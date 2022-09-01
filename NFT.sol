// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT is AccessControlEnumerable, ERC721Pausable, ERC721Enumerable, ERC721Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using Strings for uint256;
    string private _baseTokenURI;
    mapping(uint128 => string) public typeURI;
    mapping(uint128 => uint256) public currentIndex;

    event TransferAdminRole(address oldAdmin, address newAdmin);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _baseTokenURI = baseTokenURI;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NFT: not admin");
        _;
    }

    function transferAdminRole(address adminRole) external onlyAdmin {
        require(adminRole != address(0), "NFT: zero address");
        require(!hasRole(DEFAULT_ADMIN_ROLE, adminRole), "NFT: Role has been added");
        _setupRole(DEFAULT_ADMIN_ROLE, adminRole);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit TransferAdminRole(_msgSender(), adminRole);
    }

    function grantRole(bytes32, address) public virtual override(IAccessControl, AccessControl) {
        revert("NFT: At most one admin role");
    }

    function addMinter(address minter) external onlyAdmin {
        require(minter != address(0), "NFT: zero address");
        require(!hasRole(MINTER_ROLE, minter), "NFT: minter has been added");
        _setupRole(MINTER_ROLE, minter);
    }

    function removeMinter(address minter) external onlyAdmin {
        require(minter != address(0), "NFT: zero address");
        require(hasRole(MINTER_ROLE, minter), "NFT: minter has not added");
        revokeRole(MINTER_ROLE, minter);
    }

    function setTokenTypeURI(uint128 _tokenType, string memory _uri) external onlyAdmin {
        typeURI[_tokenType] = _uri;
    }

    function setBaseURI(string memory _uri) external onlyAdmin {
        _baseTokenURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getTokenIdType(uint256 tokenId) public pure returns (uint128) {
        return uint128(tokenId >> 128);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "NFT: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        uint128 tokenType = getTokenIdType(tokenId);
        return
            bytes(baseURI).length > 0 && bytes(typeURI[tokenType]).length > 0
                ? string(abi.encodePacked(baseURI, typeURI[tokenType], tokenId.toString(), ".json"))
                : "";
    }

    function mint(address _to, uint128 _type) external whenNotPaused returns (uint256) {
        require(
            hasRole(MINTER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "NFT: must have permission role to mint"
        );
        uint256 count = currentIndex[_type];
        count++;
        currentIndex[_type] = count;
        uint256 tokenId = (uint256(_type) << 128) | count;
        _mint(_to, tokenId);
        return tokenId;
    }

    function batchMint(
        address _to,
        uint128 _type,
        uint256 _amount
    ) external whenNotPaused {
        require(
            hasRole(MINTER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "NFT: must have permission role to mint"
        );
        uint256 count = currentIndex[_type];
        for (uint256 i = 0; i < _amount; ++i) {
            count++;
            uint256 tokenId = (uint256(_type) << 128) | count;
            _mint(_to, tokenId);
        }
        currentIndex[_type] = count;
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
