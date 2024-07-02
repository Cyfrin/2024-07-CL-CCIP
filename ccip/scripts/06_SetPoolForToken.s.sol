// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../tokenAdminRegistry/TokenAdminRegistry.sol";
import "./ChainConfigHelper.s.sol";
import "forge-std/Script.sol";

/**
 * How to run:
 * 1. set desired CHAIN_ID in env
 * 2. source .env
 * 3. forge script ./ccip/scripts/06_SetPoolForToken.s.sol:SetPoolForToken --rpc-url $<RPC_URL> --broadcast -vvvv
 */
// source .env && forge script ./ccip/scripts/06_SetPoolForToken.s.sol:SetPoolForToken --rpc-url anvil --broadcast -vvvv
contract SetPoolForToken is ChainConfigHelper {
  function setPoolForToken() internal {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    uint256 chainId = vm.envUint("CHAIN_ID");

    ChainConfig memory chainConfig = getChainConfig(chainId);

    TokenAdminRegistry tokenAdminRegistry = TokenAdminRegistry(chainConfig.tokenAdminRegistry);

    console.log("Setting pool for token at address: ", chainConfig.token);
    tokenAdminRegistry.setPool(chainConfig.token, chainConfig.tokenPool);

  }
}
