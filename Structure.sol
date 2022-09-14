// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract Structure is EIP712Upgradeable {
    struct UpgradeOrder {
        bytes32 orderSn; // 订单编号
        uint256 tokenId; // tokenId
        address userAddress; // 发起该订单的用户地址
        uint256 targetLevel; // 目标等级
        uint256 coinAmount; // 消耗的MWT数量
        uint256 upgradeCardAmount; // 消耗的升级卡数量
        uint256 createTime; // 创建的时间
        uint256 deadline; // 过期时间
        bytes userSign; // 用户签名
    }

    struct AssetsOrder {
        bytes32 orderSn; // 订单编号
        uint256 orderType; // 0 充值 1 提取
        address userAddress; // 用户地址
        uint256 coinAmount; // MWT数量
        uint256 overtimeCard; // 加时卡
        uint256 timeReductionCard; // 减时卡
        uint256 debugCard; // 排错卡
        uint256 robocards; // 抢答卡
        uint256 resurrectionCard; // 复活卡
        uint256 upgradeCard; // 升级卡
        uint256 createTime; // 创建的时间
        uint256 deadline; // 过期时间
        bytes userSign; // 用户签名
    }

    struct CultivateOrder {
        bytes32 orderSn; // 订单编号
        address userAddress; // 用户地址
        uint256 tokenId0; // token0Id
        uint256 tokenId1; // token1Id
        uint256 rarity0; // token0稀有度 N R SR SSR : 0 1 2 3
        uint256 rarity1; // token1稀有度
        uint256 createTime; // 创建的时间
        uint256 deadline; // 过期时间
        bytes userSign; // 用户签名
    }

    struct WithdrawOrder {
        address userAddress; // 用户地址
        uint256 tokenId; // tokenId
        uint256 createTime; // 创建时间
        uint256 deadline; // 过期时间
    }

    bytes32 public constant USER_LEVEL_TYPEHASH =
        keccak256(
            "UpgradeOrder(uint256 tokenId,address userAddress,uint256 targetLevel,uint256 coinAmount,uint256 upgradeCardAmount)"
        );

    bytes32 public constant SIGNER_LEVEL_TYPEHASH =
        keccak256(
            "UpgradeOrder(bytes32 orderSn,uint256 tokenId,address userAddress,uint256 targetLevel,uint256 coinAmount,uint256 upgradeCardAmount,uint256 createTime,uint256 deadline,bytes userSign)"
        );

    bytes32 public constant USER_ASSET_TYPEHASH =
        keccak256(
            "AssetsOrder(uint256 orderType,address userAddress,uint256 coinAmount,uint256 overtimeCard,uint256 timeReductionCard,uint256 debugCard,uint256 robocards,uint256 resurrectionCard,uint256 upgradeCard)"
        );

    bytes32 public constant SIGNER_ASSET_TYPEHASH =
        keccak256(
            "AssetsOrder(bytes32 orderSn,uint256 orderType,address userAddress,uint256 coinAmount,uint256 overtimeCard,uint256 timeReductionCard,uint256 debugCard,uint256 robocards,uint256 resurrectionCard,uint256 upgradeCard,uint256 createTime,uint256 deadline,bytes userSign)"
        );

    bytes32 public constant USER_CULTIVATE_TYPEHASH =
        keccak256(
            "CultivateOrder(address userAddress,uint256 tokenId0,uint256 tokenId1,uint256 rarity0,uint256 rarity1)"
        );

    bytes32 public constant SIGNER_CULTIVATE_TYPEHASH =
        keccak256(
            "CultivateOrder(bytes32 orderSn,address userAddress,uint256 tokenId0,uint256 tokenId1,uint256 rarity0,uint256 rarity1,uint256 createTime,uint256 deadline,bytes userSign)"
        );

    bytes32 public constant SIGNER_WITHDRAW_TYPEHASH =
        keccak256("WithdrawOrder(address userAddress,uint256 tokenId,uint256 createTime,uint256 deadline)");

    function userLevelUpgrade(UpgradeOrder memory order) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        USER_LEVEL_TYPEHASH,
                        order.tokenId,
                        order.userAddress,
                        order.targetLevel,
                        order.coinAmount,
                        order.upgradeCardAmount
                    )
                )
            );
    }

    function signerLevelUpgrade(UpgradeOrder memory order) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SIGNER_LEVEL_TYPEHASH,
                        order.orderSn,
                        order.tokenId,
                        order.userAddress,
                        order.targetLevel,
                        order.coinAmount,
                        order.upgradeCardAmount,
                        order.createTime,
                        order.deadline,
                        keccak256(order.userSign)
                    )
                )
            );
    }

    function userAssetUpdate(AssetsOrder memory order) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        USER_ASSET_TYPEHASH,
                        order.orderType,
                        order.userAddress,
                        order.coinAmount,
                        order.overtimeCard,
                        order.timeReductionCard,
                        order.debugCard,
                        order.robocards,
                        order.resurrectionCard,
                        order.upgradeCard
                    )
                )
            );
    }

    function signerAssetUpdate(AssetsOrder memory order) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SIGNER_ASSET_TYPEHASH,
                        order.orderSn,
                        order.orderType,
                        order.userAddress,
                        order.coinAmount,
                        order.overtimeCard,
                        order.timeReductionCard,
                        order.debugCard,
                        order.robocards,
                        order.resurrectionCard,
                        order.upgradeCard,
                        order.createTime,
                        order.deadline,
                        keccak256(order.userSign)
                    )
                )
            );
    }

    function userCultivate(CultivateOrder memory order) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        USER_CULTIVATE_TYPEHASH,
                        order.userAddress,
                        order.tokenId0,
                        order.tokenId1,
                        order.rarity0,
                        order.rarity1
                    )
                )
            );
    }

    function signerCultivate(CultivateOrder memory order) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SIGNER_CULTIVATE_TYPEHASH,
                        order.orderSn,
                        order.userAddress,
                        order.tokenId0,
                        order.tokenId1,
                        order.rarity0,
                        order.rarity1,
                        order.createTime,
                        order.deadline,
                        keccak256(order.userSign)
                    )
                )
            );
    }

    function signerWithdraw(WithdrawOrder memory order) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SIGNER_WITHDRAW_TYPEHASH,
                        order.userAddress,
                        order.tokenId,
                        order.createTime,
                        order.deadline
                    )
                )
            );
    }
}
