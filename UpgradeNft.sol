// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import "./Structure.sol";

interface INFT {
    function mint(address, uint128) external returns (uint256);

    function getTokenIdType(uint256) external pure returns (uint128);
}

interface IPropsCard {
    //  id1 : 
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function maxType() external view returns (uint256);
}

interface IRandom {
    function getRandom() external returns (uint256);
}

interface ICoin {
    function mint(address to, uint256 amount) external;

    // function burnFrom(address to, uint256 amount) external;
    function burn(address to, uint256 amount) external;
}

contract UpgradeNft is Structure, OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public nftAddress; // 
    address public mwt; // 
    address public propsCard; // 
    address public signAddress; // 
    uint256 public levelCap; // 
    address public random;
    mapping(uint256 => uint256) public mwtConsumption; // 
    mapping(uint256 => uint256) public cardConsumption; // 
    mapping(uint256 => uint256) public upgradeInterval; // 
    mapping(uint256 => mapping(uint256 => uint256)) public cultivationConsumption; // 
    mapping(uint256 => mapping(uint256 => uint256)) public cultivationFailureRate; // 
    mapping(uint256 => address) public belong; // 
    mapping(address => uint256[]) public userLockInfo; // 
    mapping(uint256 => TokenInfo) public tokenInfo; // 
    mapping(uint256 => uint256) public mysteryBoxRarity; // 
    mapping(uint256 => uint256) public NFTRarity; // 
    mapping(bytes32 => bool) public orderSn; // 

    // event UpgradeEvent(address indexed user);
    // event WithdrawAssets(bytes32 indexed orderSn, address user);
    // event RechargeAssets(bytes32 indexed orderSn, address user);

    struct TokenInfo {
        uint256 level; //  
        uint256 incubationsNumber; // 
        uint256 interval; // 
    }

    function __UpgradeNft_init(
        address _nftAddress,
        address _mwt,
        address _propsCard,
        address _signAddress
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __EIP712_init("UpgradeNft Protocol", "1");
        __UpgradeNft_init_unchained(_nftAddress, _mwt, _propsCard, _signAddress);
    }

    function __UpgradeNft_init_unchained(
        address _nftAddress,
        address _mwt,
        address _propsCard,
        address _signAddress
    ) internal onlyInitializing {
        nftAddress = _nftAddress;
        mwt = _mwt;
        propsCard = _propsCard;
        signAddress = _signAddress;
    }

    // 
    function getUserLock(address user) external view returns (uint256[] memory) {
        uint256[] memory lockInfo = userLockInfo[user];
        if (lockInfo.length > 0) return lockInfo;
        return new uint256[](0);
    }

    // 
    function setSignAddress(address newSign) external onlyOwner {
        require(newSign != address(0), "Is zero address");
        signAddress = newSign;
    }

    // 
    function setRandom(address _random) external onlyOwner {
        require(_random != address(0), "Is zero address");
        random = _random;
    }

    // 
    function setNft(address _nft) external onlyOwner {
        nftAddress = _nft;
    }

    // 
    function setLevelCap(uint256 cap) external onlyOwner {
        require(cap > 0, "UpgradeNft: The upper limit cannot be zero");
        levelCap = cap;
    }

    // 
    function setMwtConsumption(uint256[] memory _level, uint256[] memory _consumption) external onlyOwner {
        require(_level.length > 0 && _level.length == _consumption.length, "UpgradeNft: length error");
        for (uint256 i = 0; i < _level.length; i++) {
            mwtConsumption[_level[i]] = _consumption[i];
        }
    }

    // 
    function setCardConsumption(uint256[] memory _level, uint256[] memory _consumption) external onlyOwner {
        require(_level.length > 0 && _level.length == _consumption.length, "UpgradeNft: length error");
        for (uint256 i = 0; i < _level.length; i++) {
            cardConsumption[_level[i]] = _consumption[i];
        }
    }

    // 
    function setUpgradeInterval(uint256[] memory _level, uint256[] memory _interval) external onlyOwner {
        require(_level.length > 0 && _level.length == _interval.length, "UpgradeNft: length error");
        for (uint256 i = 0; i < _level.length; i++) {
            upgradeInterval[_level[i]] = _interval[i];
        }
    }

    // 
    function setCultivationConsumption(
        uint256 _rarity, // 
        uint256[] memory _number, // 
        uint256[] memory _consumption // 
    ) external onlyOwner {
        require(_number.length > 0 && _number.length == _consumption.length, "UpgradeNft: length error");

        for (uint256 i = 0; i < _number.length; i++) {
            cultivationConsumption[_rarity][_number[i]] = _consumption[i];
        }
    }

    // 
    function setCultivationFailureRate(
        uint256 _rarity,
        uint256[] memory _number,
        uint256[] memory _failureRate
    ) external onlyOwner {
        require(_number.length > 0 && _number.length == _failureRate.length, "UpgradeNft: length error");

        for (uint256 i = 0; i < _number.length; i++) {
            cultivationFailureRate[_rarity][_number[i]] = _failureRate[i];
        }
    }

    // 
    function upgradeLevel(UpgradeOrder memory order, bytes memory signature) external {
        require(!orderSn[order.orderSn], "UpgradeNft: order completed");
        require(order.deadline >= block.timestamp, "UpgradeNft: order already expired");
        require(msg.sender == order.userAddress, "UpgradeNft: operation denied");
        require(IERC721Upgradeable(nftAddress).ownerOf(order.tokenId) == msg.sender, "UpgradeNft: no token ownership");
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(signAddress, signerLevelUpgrade(order), signature),
            "UpgradeNft: signer signature is invalid"
        );
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(order.userAddress, userLevelUpgrade(order), order.userSign),
            "UpgradeNft: user signature is invalid"
        );
        TokenInfo storage tInfo = tokenInfo[order.tokenId];
        require(order.targetLevel <= levelCap, "UpgradeNft: exceeding the maximum level");
        require(order.targetLevel - 1 == tInfo.level, "UpgradeNft: only one level up");
        require(block.timestamp >= tInfo.interval, "UpgradeNft: the next upgrade is not yet available");
        require(
            order.coinAmount == mwtConsumption[tInfo.level],
            "UpgradeNft: abnormal amount of MWT consumed for upgrade"
        );
        require(
            order.upgradeCardAmount == cardConsumption[tInfo.level],
            "UpgradeNft: the number of upgrade cards consumed for upgrade is abnormal"
        );
        ICoin(mwt).burn(msg.sender, order.coinAmount);
        if (order.upgradeCardAmount > 0) {
            IPropsCard(propsCard).burn(msg.sender, 6, order.upgradeCardAmount);
        }
        tInfo.level++;
        tInfo.interval = upgradeInterval[tInfo.level] * 60 + block.timestamp;
        orderSn[order.orderSn] = true;
    }

    // 
    function withdrawAssets(AssetsOrder memory order, bytes memory signature) external {
        require(!orderSn[order.orderSn], "UpgradeNft: order completed");
        require(order.deadline >= block.timestamp, "UpgradeNft: order already expired");
        require(msg.sender == order.userAddress, "UpgradeNft: operation denied");
        require(order.orderType == 1, "UpgradeNft: order type error");
        require(
            order.coinAmount > 0 ||
                order.overtimeCard > 0 ||
                order.timeReductionCard > 0 ||
                order.debugCard > 0 ||
                order.robocards > 0 ||
                order.resurrectionCard > 0 ||
                order.upgradeCard > 0,
            "UpgradeNft: assets withdrawn are zero"
        );
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(signAddress, signerAssetUpdate(order), signature),
            "UpgradeNft: signer signature is invalid"
        );
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(order.userAddress, userAssetUpdate(order), order.userSign),
            "UpgradeNft: user signature is invalid"
        );
        if (order.coinAmount > 0) {
            ICoin(mwt).burn(msg.sender, order.coinAmount);
        }
        if (order.overtimeCard > 0) {
            IPropsCard(propsCard).burn(msg.sender, 1, order.overtimeCard);
        }
        if (order.timeReductionCard > 0) {
            IPropsCard(propsCard).burn(msg.sender, 2, order.timeReductionCard);
        }
        if (order.debugCard > 0) {
            IPropsCard(propsCard).burn(msg.sender, 3, order.debugCard);
        }
        if (order.robocards > 0) {
            IPropsCard(propsCard).burn(msg.sender, 4, order.robocards);
        }
        if (order.resurrectionCard > 0) {
            IPropsCard(propsCard).burn(msg.sender, 5, order.resurrectionCard);
        }
        if (order.upgradeCard > 0) {
            IPropsCard(propsCard).burn(msg.sender, 6, order.upgradeCard);
        }
        orderSn[order.orderSn] = true;
    }

    // 
    function rechargeAssets(AssetsOrder memory order, bytes memory signature) external {
        require(!orderSn[order.orderSn], "UpgradeNft: order completed");
        require(order.deadline >= block.timestamp, "UpgradeNft: order already expired");
        require(msg.sender == order.userAddress, "UpgradeNft: operation denied");
        require(order.orderType == 0, "UpgradeNft: order type error");
        require(
            order.coinAmount > 0 ||
                order.overtimeCard > 0 ||
                order.timeReductionCard > 0 ||
                order.debugCard > 0 ||
                order.robocards > 0 ||
                order.resurrectionCard > 0 ||
                order.upgradeCard > 0,
            "UpgradeNft: assets withdrawn are zero"
        );
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(signAddress, signerAssetUpdate(order), signature),
            "UpgradeNft: signer signature is invalid"
        );
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(order.userAddress, userAssetUpdate(order), order.userSign),
            "UpgradeNft: user signature is invalid"
        );
        if (order.coinAmount > 0) {
            ICoin(mwt).mint(msg.sender, order.coinAmount);
        }
        if (order.overtimeCard > 0) {
            IPropsCard(propsCard).mint(msg.sender, 1, order.overtimeCard, "");
        }
        if (order.timeReductionCard > 0) {
            IPropsCard(propsCard).mint(msg.sender, 2, order.timeReductionCard, "");
        }
        if (order.debugCard > 0) {
            IPropsCard(propsCard).mint(msg.sender, 3, order.debugCard, "");
        }
        if (order.robocards > 0) {
            IPropsCard(propsCard).mint(msg.sender, 4, order.robocards, "");
        }
        if (order.resurrectionCard > 0) {
            IPropsCard(propsCard).mint(msg.sender, 5, order.resurrectionCard, "");
        }
        if (order.upgradeCard > 0) {
            IPropsCard(propsCard).mint(msg.sender, 6, order.upgradeCard, "");
        }
        orderSn[order.orderSn] = true;
    }

    // 
    function cultivationNft(CultivateOrder memory order, bytes memory signature) external returns (uint256, uint256) {
        require(!orderSn[order.orderSn], "UpgradeNft: order completed");
        require(order.deadline >= block.timestamp, "UpgradeNft: order already expired");
        require(msg.sender == order.userAddress, "UpgradeNft: operation denied");
        require(
            IERC721Upgradeable(nftAddress).ownerOf(order.tokenId0) == msg.sender &&
                IERC721Upgradeable(nftAddress).ownerOf(order.tokenId1) == msg.sender,
            "UpgradeNft: no token ownership"
        );
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(signAddress, signerCultivate(order), signature),
            "UpgradeNft: signer signature is invalid"
        );
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(order.userAddress, userCultivate(order), order.userSign),
            "UpgradeNft: user signature is invalid"
        );
        TokenInfo storage tInfo0 = tokenInfo[order.tokenId0];
        TokenInfo storage tInfo1 = tokenInfo[order.tokenId1];
        require(
            tInfo0.incubationsNumber < 5 && tInfo1.incubationsNumber < 5,
            "UpgradeNft: cultivation has reached the upper limit"
        );
        uint256 spend = cultivationConsumption[order.rarity0][tInfo0.incubationsNumber] +
            cultivationConsumption[order.rarity1][tInfo1.incubationsNumber];
        ICoin(mwt).burn(msg.sender, spend);
        uint256 failRate = cultivationFailureRate[order.rarity0][tInfo0.incubationsNumber] +
            cultivationFailureRate[order.rarity1][tInfo1.incubationsNumber];
        uint256 fRandom = IRandom(random).getRandom();
        if (failRate >= fRandom) {
            orderSn[order.orderSn] = true;
            return (0, 0);
        }
        uint256 mRate = cultivationPR(order.rarity0, order.rarity1);
        require(mRate != 9999, "UpgradeNft: wrong mysteryBox rarity");
        uint256 tokenId = INFT(nftAddress).mint(msg.sender, 100);
        mysteryBoxRarity[tokenId] = mRate;
        tInfo0.incubationsNumber++;
        tInfo1.incubationsNumber++;
        orderSn[order.orderSn] = true;
        return (tokenId, mRate);
    }

    // 
    function deposit(uint256 tid) external {
        require(IERC721Upgradeable(nftAddress).ownerOf(tid) == msg.sender, "UpgradeNft: no token ownership");
        require(belong[tid] == address(0), "UpgradeNft: illegal withdraw");
        // TODO 
        IERC721Upgradeable(nftAddress).safeTransferFrom(msg.sender, address(this), tid);
        belong[tid] = msg.sender;
        userLockInfo[msg.sender].push(tid);
    }

    // 
    function withdraw(WithdrawOrder memory order, bytes memory signature) external {
        require(order.deadline >= block.timestamp, "UpgradeNft: order already expired");
        require(msg.sender == order.userAddress, "UpgradeNft: operation denied");
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(signAddress, signerWithdraw(order), signature),
            "UpgradeNft: signer signature is invalid"
        );
        require(belong[order.tokenId] == msg.sender, "UpgradeNft: NFT does not belong to the caller");
        uint256[] storage lock = userLockInfo[msg.sender];
        for (uint256 i = 0; i < lock.length; i++) {
            if (lock[i] == order.tokenId) {
                uint256 lastIndex = lock.length - 1;
                if (lastIndex != i) {
                    uint256 lastTid = lock[lastIndex];
                    lock[i] = lastTid;
                }
                lock.pop();
                break;
            }
        }
        delete belong[order.tokenId];
        IERC721Upgradeable(nftAddress).safeTransferFrom(address(this), msg.sender, order.tokenId);
    }

    // 
    function openMysteryBox(uint256 tid) external returns (uint256, uint256) {
        require(IERC721Upgradeable(nftAddress).ownerOf(tid) == msg.sender, "UpgradeNft: no token ownership");
        require(INFT(nftAddress).getTokenIdType(tid) == 100, "UpgradeNft: Wrong type of NFT");
        uint256 nRate = NFTPR(mysteryBoxRarity[tid]);
        require(nRate != 9999, "UpgradeNft: wrong NFT rarity");
        uint256 tokenId = INFT(nftAddress).mint(msg.sender, 666);
        NFTRarity[tokenId] = nRate;
        return (tokenId, nRate);
    }

    function getPropsCardAmount(address user) external view returns (uint256[] memory) {
        uint256 len = IPropsCard(propsCard).maxType();
        uint256[] memory amount = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            amount[i] = IERC1155Upgradeable(propsCard).balanceOf(user, i + 1);
        }
        return amount;
    }

    function NFTPR(uint256 rarity) public returns (uint256) {
        require(rarity < 4, "UpgradeNft: Rarity is wrong");
        uint256 nRandom = IRandom(random).getRandom();
        if (rarity == 0) {
            if (nRandom <= 97) {
                return 0;
            }
            return 1;
        }
        if (rarity == 1) {
            if (nRandom <= 25) {
                return 0;
            } else if (nRandom <= 98) {
                return 1;
            }
            return 2;
        }
        if (rarity == 2) {
            if (nRandom <= 30) {
                return 1;
            } else if (nRandom <= 98) {
                return 2;
            }
            return 3;
        }
        if (rarity == 3) {
            if (nRandom <= 35) {
                return 2;
            }
            return 3;
        }
        return 9999;
    }

    // 
    function cultivationPR(uint256 rarity0, uint256 rarity1) public returns (uint256) {
        uint256 rate = rarity0 + rarity1;
        if (rate == 0) {
            return 0;
        }
        if (rate == 6) {
            return 3;
        }
        uint256 mRandom = IRandom(random).getRandom();
        if (rate == 1) {
            if (mRandom <= 50) {
                return 0;
            } else if (mRandom <= 99) {
                return 1;
            }
            return 2;
        }
        if (rate == 2) {
            if (rarity0 == 0 || rarity1 == 0) {
                if (mRandom <= 50) {
                    return 0;
                } else if (mRandom <= 99) {
                    return 2;
                }
                return 3;
            } else {
                if (mRandom <= 98) {
                    return 1;
                } else {
                    return 2;
                }
            }
        }
        if (rate == 3) {
            if (rarity0 == 0 || rarity1 == 0) {
                if (mRandom <= 50) {
                    return 0;
                } else {
                    return 3;
                }
            } else {
                if (mRandom <= 50) {
                    return 1;
                } else if (mRandom <= 99) {
                    return 2;
                }
                return 3;
            }
        }
        if (rate == 4) {
            if (rarity0 == 1 || rarity1 == 1) {
                if (mRandom <= 50) {
                    return 1;
                } else {
                    return 3;
                }
            } else {
                if (mRandom <= 98) {
                    return 2;
                } else {
                    return 3;
                }
            }
        }
        if (rate == 5) {
            if (mRandom <= 50) {
                return 2;
            } else {
                return 3;
            }
        }
        return 9999;
    }
}
