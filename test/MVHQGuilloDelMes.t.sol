// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import "ds-test/test.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/MVHQGuilloDelMes.sol";

contract MVHQGuilloDelMesTest is DSTest {
    using stdStorage for StdStorage;
    using Strings for uint256;

    Vm private vm = Vm(HEVM_ADDRESS);
    MVHQGuilloDelMes private nft;
    StdStorage private stdstore;

    function setUp() public {
        // Deploy NFT contract
        nft = new MVHQGuilloDelMes("MVHQGuilloDelMes_Test", "GDM", "https://github.com/mdncarrasco/MVHQGuilloDelMes");
    }

    function testBaseURI() public {
	string memory _baseURI = "https://github.com/mdncarrasco/MVHQGuilloDelMes";

        assertEq(_baseURI, nft.baseURI());
    }

    function testSetBaseURI() public {
	string memory newBaseURI = "https://kfishnchips.com/";

	nft.grantRole(nft.MANAGER_ROLE(),address(0xd3ad));
	vm.startPrank(address(0xd3ad));

        nft.setBaseURI(newBaseURI);
	vm.stopPrank();

        assertEq(newBaseURI, nft.baseURI());
    }

    function testFailSetBaseURI() public {
	bytes32 newBaseURI = "https://kfishnchips.com/";

	vm.startPrank(address(0xd3ad));
        nft.setBaseURI(string(abi.encodePacked(newBaseURI)));
	vm.stopPrank();
    }

    function testFailMintToZeroAddress() public {
        nft.mintTo(address(0));
    }

    function testFailMintNotOwner() public {

	vm.startPrank(address(0xd3ad));
        nft.mintTo(address(1));
	vm.stopPrank();
    }

    function testURI() public {
	string memory newBaseURI = "https://kfishnchips.com/";
	nft.grantRole(nft.MANAGER_ROLE(),address(0xd3ad));
	vm.startPrank(address(0xd3ad));
        nft.setBaseURI(newBaseURI);
	vm.stopPrank();

	nft.grantRole(nft.MINTER_ROLE(),address(0xd3ad));
	vm.startPrank(address(0xd3ad));
        uint256 _idToken = nft.mintTo(address(1));
	vm.stopPrank();
	string memory uri = string(abi.encodePacked(newBaseURI, _idToken.toString()));

	assertEq(uri, nft.tokenURI(_idToken));
    }

    function testFailURI() public {
	nft.tokenURI(1);
    }

    function testNewMintOwnerRegistered() public {
	nft.grantRole(nft.MINTER_ROLE(),address(0xd3ad));
	vm.startPrank(address(0xd3ad));
        nft.mintTo(address(1));
	vm.stopPrank();
        uint256 slotOfNewOwner = stdstore
            .target(address(nft))
            .sig(nft.ownerOf.selector)
            .with_key(1)
            .find();

        uint160 ownerOfTokenIdOne = uint160(uint256((vm.load(address(nft),bytes32(abi.encode(slotOfNewOwner))))));
        assertEq(address(ownerOfTokenIdOne), address(1));
    }

    function testBalanceIncremented() public { 
	nft.grantRole(nft.MINTER_ROLE(),address(0xd3ad));
	vm.startPrank(address(0xd3ad));
        nft.mintTo(address(1));
        uint256 slotBalance = stdstore
            .target(address(nft))
            .sig(nft.balanceOf.selector)
            .with_key(address(1))
            .find();
        
        uint256 balanceFirstMint = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balanceFirstMint, 1);

        nft.mintTo(address(1));
	vm.stopPrank();
        uint256 balanceSecondMint = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balanceSecondMint, 2);
    }

    function testSafeContractReceiver() public {
        Receiver receiver = new Receiver();
	nft.grantRole(nft.MINTER_ROLE(),address(0xd3ad));
	vm.startPrank(address(0xd3ad));
        nft.mintTo(address(receiver));
	vm.stopPrank();

        uint256 slotBalance = stdstore
            .target(address(nft))
            .sig(nft.balanceOf.selector)
            .with_key(address(receiver))
            .find();

        uint256 balance = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balance, 1);
    }
    
    function testFailUnSafeContractReceiver() public {
        vm.etch(address(1), bytes("mock code"));
        nft.mintTo(address(1));
    }



/* TODO check withdrawal

    function testWithdrawalWorksAsOwner() public {
        // Mint an NFT, sending eth to the contract
        Receiver receiver = new Receiver();
        address payable payee = payable(address(0x1337));
        uint256 priorPayeeBalance = payee.balance;
        nft.mintTo{value: nft.MINT_PRICE()}(address(receiver));
        // Check that the balance of the contract is correct
        assertEq(address(nft).balance, nft.MINT_PRICE());
        uint256 nftBalance = address(nft).balance;
        // Withdraw the balance and assert it was transferred
        nft.withdrawPayments(payee);
        assertEq(payee.balance, priorPayeeBalance + nftBalance);
    }

    function testWithdrawalFailsAsNotOwner() public {
        // Mint an NFT, sending eth to the contract
        Receiver receiver = new Receiver();
        nft.mintTo{value: nft.MINT_PRICE()}(address(receiver));
        // Check that the balance of the contract is correct
        assertEq(address(nft).balance, nft.MINT_PRICE());
        // Confirm that a non-owner cannot withdraw
        vm.expectRevert("Ownable: caller is not the owner");
        vm.startPrank(address(0xd3ad));
        nft.withdrawPayments(payable(address(0xd3ad)));
        vm.stopPrank();
    }
*/
}

contract Receiver is ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) override external returns (bytes4){
        return this.onERC721Received.selector;
    }
}


