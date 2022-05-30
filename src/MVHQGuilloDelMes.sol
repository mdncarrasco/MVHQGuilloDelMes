// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./ERC721.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";

error NonExistentTokenURI();
error WithdrawError();

/// @title MVHQGuilloDelMes
/// @author @NotNotBoludo
/// @notice Metaverse HQ Employee of the Month Award
/** @dev TODO Any function which updates state will require a signature from an address with the correct role
    This is an upgradeable contract using UUPSUpgradeable (IERC1822Proxiable / ERC1967Proxy) from OpenZeppelin 
    TODO add ROLES */
contract MVHQGuilloDelMes is ERC721, AccessControl {

    using Strings for uint256;

    /// @notice role assigned to an address that can perform upgrades to the contract
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    /// @notice role assigned to addresses that can perform managemenet actions
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    /// @notice role assigned to addresses that can perform minted actions
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public baseURI;
    string constant DEFAULT_BASE_URI = ""; // TODO define default base URI
    uint256 public currentTokenId;

    event BaseURIChanged(address indexed sender, string previousURI, string newURI);
    event Received(address indexed sender, uint256 amount);
    event Withdraw(address indexed payee, uint256 amount);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) {  
	_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        bytes(baseURI_).length > 0 ? baseURI = baseURI_
                : baseURI = DEFAULT_BASE_URI;
    }

    /// @notice function required to receive eth
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @notice Used to set the baseURI for metadata
    /// @param baseURI_ the base URI
    function setBaseURI(string memory baseURI_) external onlyRole(MANAGER_ROLE) {
        string memory previousURI = baseURI;
        bytes(baseURI_).length > 0 ? baseURI = baseURI_
                : baseURI = DEFAULT_BASE_URI;
        emit BaseURIChanged(msg.sender, previousURI, baseURI_);
    }

    // TODO create a description
    function mintTo(address recipient_) external onlyRole(MINTER_ROLE) returns (uint256) {
        
        uint256 newTokenId = ++currentTokenId;
        
        _safeMint(recipient_, newTokenId);
        return newTokenId;
    }

    /// @notice 
    /// @dev returns baseURI + tokenId.json
    /// @param tokenId_ the tokenId without offsets
    /// @return the tokenURI with metadata
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (ownerOf(tokenId_) == address(0)) {
            revert NonExistentTokenURI();
        }
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId_.toString()))
                : "";
    }

    /// @notice Withdraw function in case anyone sends ETH to contract by mistake
    /// TODO create a function in case of others tokens.
    function withdraw(address payable payee) external onlyRole(MANAGER_ROLE) {
        require(payee != address(0), "INVALID_RECIPIENT");
        uint256 balance = address(this).balance;
        emit Received(payee, balance);
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawError();
        }
        
    }
}
