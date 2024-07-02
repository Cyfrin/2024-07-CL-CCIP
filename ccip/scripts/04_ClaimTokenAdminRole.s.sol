// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../tokenAdminRegistry/TokenAdminRegistry.sol";
import "./ChainConfigHelper.s.sol";
import "forge-std/Script.sol";

/**
 * How to run:
 * 1. set desired CHAIN_ID in env
 * 2. source .env
 * 3. forge script ./ccip/scripts/04_ClaimAdminRole.s.sol:ClaimAdminRole --rpc-url $<RPC_URL> --broadcast -vvvv
 */
contract ClaimTokenAdminRole is ChainConfigHelper {
  function claimTokenAdminRole() internal {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    uint256 chainId = vm.envUint("CHAIN_ID");

    ChainConfig memory chainConfig = getChainConfig(chainId);

    TokenAdminRegistry tokenAdminRegistry = TokenAdminRegistry(chainConfig.tokenAdminRegistry);

    console.log("Accepting admin role for token at address: ", chainConfig.token);
    tokenAdminRegistry.acceptAdminRole(chainConfig.token);

  }
}
