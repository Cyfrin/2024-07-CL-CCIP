// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/RateLimiter.sol";
import "../pools/TokenPool.sol";
import "./ChainConfigHelper.s.sol";
import "forge-std/Script.sol";

interface ITokenPool {
    function applyChainUpdates(
        TokenPool.ChainUpdate[] calldata chains
    ) external;
}

/**
 * How to run:
 * 1. set desired CHAIN_ID in env
 * 2. set desired REMOTE_CHAIN_ID in env; the local token pool will point to the remote token pool
 * 3. source .env
 * 4. forge script ./ccip/scripts/05_ApplyChainUpdates.s.sol:ApplyChainUpdates --rpc-url $<RPC_URL> --broadcast -vvvv
 */
contract ApplyChainUpdates is ChainConfigHelper {
    function applyChainUpdates() internal {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 chainId = vm.envUint("CHAIN_ID");
        uint256 remoteChainId = vm.envUint("REMOTE_CHAIN_ID");

        // Load the JSON configuration file
        ChainConfig memory chainConfig = getChainConfig(chainId);
        ChainConfig memory remoteChainConfig = getChainConfig(remoteChainId);

        TokenPool tokenPool = TokenPool(chainConfig.tokenPool);

        // Example ChainUpdate data, adjust according to your needs.
        TokenPool.ChainUpdate[] memory updates = new TokenPool.ChainUpdate[](1);
        updates[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteChainConfig.chainSelector,
            allowed: true,
            outboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: true,
                capacity: 100e18,
                rate: 1e17
            }), // 0.1 token/s, 100 token max capacity
            inboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: true,
                capacity: 100e18,
                rate: 1e17
            }),
            remotePoolAddress: abi.encodePacked(remoteChainConfig.tokenPool),
            remoteTokenAddress: abi.encodePacked(remoteChainConfig.token)
        });

        vm.startBroadcast(deployerPrivateKey);
        tokenPool.applyChainUpdates(updates);
        vm.stopBroadcast();
    }
}
