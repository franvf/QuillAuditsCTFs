// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract PrivateClub is ReentrancyGuard, Ownable {
    uint private registerEndDate;
    event setRegEndDate(uint registerEndDate);
    event memberWithdrawevent(address member, address to, uint amount);
    address[] public members_;
    mapping(address => bool) public members;

    receive() external payable {}

    uint public membersCount;

    function setRegisterEndDate(uint _newRegisterEndDate) external onlyOwner {
        registerEndDate = _newRegisterEndDate;
        emit setRegEndDate(registerEndDate);
    }

    function becomeMember(
        address[] calldata _members
    ) external payable nonReentrant {
        require(block.timestamp < registerEndDate, "registration closed");
        require(_members.length == membersCount, "wrong members length");
        require(msg.value == membersCount * 1 ether, "need more ethers");
        for (uint i = 0; i < _members.length; i++) {
            _members[i].call{value: 1 ether}("");
        }
        membersCount += 1;
        members[msg.sender] = true;
        members_.push(msg.sender);
    }

    modifier onlyMember() {
        bool member;
        for (uint i = 0; i < membersCount; i++) {
            if (members_[i] == msg.sender) {
                member = true;
            }
        }

        require(member == true, "you are not a member");
        _;
    }

    function adminWithdraw(address to, uint amount) external onlyOwner {
        payable(to).call{value: amount}("");
    }

    function addMemberByAdmin(address newMember) external onlyOwner {
        membersCount += 1;
        members[newMember] = true;
        members_.push(newMember);
    }

    function buyAdminRole(address newAdmin) external payable onlyMember {
        require(msg.value == 10 ether, "need 10 ethers");
        _transferOwnership(newAdmin);
    }
}