// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract MillionwinnerToken is ERC20, Pausable, AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public team; // 
    address public eldf; // 
    uint256 public teamReleaseTime; //
    uint256 public eldfReleaseTime; // 
    uint256 public teamReleaseCount; // 
    uint256 public eldfReleaseCount; // 
    uint256 public teamReleaseAmount = 4166666 * 1e18; // 
    uint256 public eldfReleaseAmount = 3888888 * 1e18; // 
    uint256 public releasePeriods = 30 days; // 
    uint256 public cap = 1000000000 * 1e18; // 

    event TransferAdminRole(address oldAdmin, address newAdmin);

    constructor(
        string memory _name,
        string memory _symbol,
        address _team,
        address _eldf
    ) ERC20(_name, _symbol) {
        require(_team != address(0) && _eldf != address(0), "Millionwinner Token: Zero address");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        team = _team;
        eldf = _eldf;
        // 
        teamReleaseTime = block.timestamp + 180 days;
        // 
        eldfReleaseTime = block.timestamp + 90 days;
        // 
        _mint(address(this), 290000000 * 1e18);
        _mint(eldf, 10000000 * 1e18);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Millionwinner Token: not admin");
        _;
    }

    function transferAdminRole(address adminRole) external onlyAdmin {
        require(adminRole != address(0), "Millionwinner Token: zero address");
        require(!hasRole(DEFAULT_ADMIN_ROLE, adminRole), "Millionwinner Token: Role has been added");
        _setupRole(DEFAULT_ADMIN_ROLE, adminRole);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit TransferAdminRole(_msgSender(), adminRole);
    }

    function addMinter(address minter) external onlyAdmin {
        require(minter != address(0), "Millionwinner Token: zero address");
        require(!hasRole(MINTER_ROLE, minter), "Millionwinner Token: minter has been added");
        _setupRole(MINTER_ROLE, minter);
    }

    function removeMinter(address minter) external onlyAdmin {
        require(minter != address(0), "Millionwinner Token: zero address");
        require(hasRole(MINTER_ROLE, minter), "Millionwinner Token: minter has not added");
        revokeRole(MINTER_ROLE, minter);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    // 
    function getTeamLockAmount() external {
        require(msg.sender == team, "Millionwinner Token: forbidden to call");
        require(block.timestamp >= teamReleaseTime, "Millionwinner Token: Unlock time");
        // 
        uint256 number = (block.timestamp - teamReleaseTime + releasePeriods) / releasePeriods;
        number = number > 36 ? 36 : number;
        require(number > teamReleaseCount, "Millionwinner Token: release amount has been collected");
        uint256 available = number - teamReleaseCount;
        // 
        if (number == 36) {
            uint256 over = 150000000 * 1e18 - (teamReleaseAmount * 36);
            transfer(team, teamReleaseAmount * available + over);
        } else {
            transfer(team, teamReleaseAmount * available);
        }
        teamReleaseCount += available;
    }

    // 
    function getEldfLockAmount() external {
        require(msg.sender == eldf, "Millionwinner Token: forbidden to call");
        require(block.timestamp >= eldfReleaseTime, "Millionwinner Token: Unlock time");
        uint256 number = (block.timestamp - eldfReleaseTime + releasePeriods) / releasePeriods;
        number = number > 36 ? 36 : number;
        require(number > eldfReleaseCount, "Millionwinner Token: release amount has been collected");
        uint256 available = number - eldfReleaseCount;
        // 
        if (number == 36) {
            uint256 over = 140000000 * 1e18 - (eldfReleaseAmount * 36);
            transfer(eldf, eldfReleaseAmount * available + over);
        } else {
            transfer(eldf, eldfReleaseAmount * available);
        }
        eldfReleaseCount += available;
    }

    // 
    function setTeamAddress(address _team) external {
        require(
            _team != address(0) && _team != team,
            "Millionwinner Token: Cannot set zero address or the same address"
        );
        require(msg.sender == team, "Millionwinner Token: forbidden to call");
        team = _team;
    }

    // 
    function seteldfAddress(address _eldf) external {
        require(
            _eldf != address(0) && _eldf != eldf,
            "Millionwinner Token: Cannot set zero address or the same address"
        );
        require(msg.sender == eldf, "Millionwinner Token: Forbidden to call");
        eldf = _eldf;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function mint(address _to, uint256 _amount) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Millionwinner Token: must have minter role to mint");
        require(totalSupply() + _amount <= cap, "Millionwinner Token: cap exceeded");
        _mint(_to, _amount);
    }

    function grantRole(bytes32, address) public virtual override(IAccessControl, AccessControl) {
        revert("Millionwinner Token: At most one admin role");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "Millionwinner Token: token transfer while paused");
    }
}
