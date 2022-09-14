// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PropsCard is AccessControlEnumerable, ERC1155Burnable, ERC1155Pausable, ERC1155Supply {
    using Strings for uint256;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    string private _baseURI;
    uint256 public maxType = 6;

    constructor(string memory _uri) ERC1155(_uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURN_ROLE, _msgSender());
        _baseURI = _uri;
    }
    
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not admin");
        _;
    }

    function grantRole(bytes32, address) public virtual override(IAccessControl, AccessControl) {
        revert("At most one admin role");
    }

    function addMinter(address minter) external onlyAdmin {
        require(minter != address(0), "Zero address");
        require(!hasRole(MINTER_ROLE, minter), "Minter has been added");
        _setupRole(MINTER_ROLE, minter);
    }

    function removeMinter(address minter) external onlyAdmin {
        require(minter != address(0), "Zero address");
        require(hasRole(MINTER_ROLE, minter), "Minter has not added");
        revokeRole(MINTER_ROLE, minter);
    }

    function addBurnRole(address burnRole) external onlyAdmin {
        require(burnRole != address(0), "Zero address");
        require(!hasRole(BURN_ROLE, burnRole), "burnRole has been added");
        _setupRole(BURN_ROLE, burnRole);
    }

    function removeBurnRole(address burnRole) external onlyAdmin {
        require(burnRole != address(0), "Zero address");
        require(hasRole(BURN_ROLE, burnRole), "burnRole has not added");
        revokeRole(BURN_ROLE, burnRole);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function setBaseURI(string memory _uri) external onlyAdmin {
        _baseURI = _uri;
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        if (id > maxType) {
            return "";
        }
        return string(abi.encodePacked(_baseURI, id.toString()));
    }

    function setMaxType(uint256 max) external onlyAdmin {
        maxType = max;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Must have permission role to mint"
        );
        require(id <= maxType, "Not exist type");
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Must have permission role to mint"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] <= maxType, "Not exist type");
        }
        _mintBatch(to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
