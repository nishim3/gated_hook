// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDeltaLibrary, BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";

contract NFTGatedPoolHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    // NFT contract address
    IERC721 public nftContract;

    // Mapping to store NFT-gated pools
    mapping(PoolId => bool) public nftGatedPools;

    constructor(IPoolManager _poolManager, IERC721 _nftContract) BaseHook(_poolManager) {
        nftContract = _nftContract;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: false,
            beforeAddLiquidity: true,
            beforeRemoveLiquidity: true,
            afterAddLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: true,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function beforeInitialize(address, PoolKey calldata key, uint160, bytes calldata)
        external
        override
        returns (bytes4)
    {
        // Mark this pool as NFT-gated
        nftGatedPools[key.toId()] = true;
        return this.beforeInitialize.selector;
    }

    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override onlyPoolManager returns (bytes4) {
        if (nftGatedPools[key.toId()]) {
            require(nftContract.balanceOf(sender) > 0, "NFTGatedPoolHook: Must own NFT to modify position");
        }
        return this.beforeAddLiquidity.selector;
    }

    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override onlyPoolManager returns (bytes4) {
        if (nftGatedPools[key.toId()]) {
            require(nftContract.balanceOf(sender) > 0, "NFTGatedPoolHook: Must own NFT to modify position");
        }
        return this.beforeAddLiquidity.selector;
    }

    function beforeSwap(address sender, PoolKey calldata key, IPoolManager.SwapParams calldata, bytes calldata)
        external
        override
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        if (nftGatedPools[key.toId()]) {
            require(nftContract.balanceOf(sender) > 0, "NFTGatedPoolHook: Must own NFT to swap");
        }
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function beforeDonate(address sender, PoolKey calldata key, uint256, uint256, bytes calldata)
        external
        override
        onlyPoolManager
        returns (bytes4)
    {
        if (nftGatedPools[key.toId()]) {
            require(nftContract.balanceOf(sender) > 0, "NFTGatedPoolHook: Must own NFT to swap");
        }
        return this.beforeDonate.selector;
    }
}
