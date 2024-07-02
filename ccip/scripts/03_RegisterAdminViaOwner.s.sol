// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import "./ChainConfigHelper.s.sol";
import "forge-std/Script.sol";

/**
 * How to run:
 * 1. set desired CHAIN_ID in env
 * 2. source .env
 * 3. forge script ./ccip/scripts/03_RegisterAdminViaOwner.s.sol:RegisterAdminViaOwner --rpc-url $<RPC_URL> --broadcast -vvvv
 */
contract RegisterAdminViaOwner is ChainConfigHelper {
  function registerAdminViaOwner() internal {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    uint256 chainId = vm.envUint("CHAIN_ID");
    ChainConfig memory chainConfig = getChainConfig(chainId);

    // Parse the JSON configuration for the specific chainId
    address registryModuleOwnerCustomAddress = chainConfig.registrationModule;
    address tokenAddress = chainConfig.token;

    RegistryModuleOwnerCustom registryModuleOwnerCustom = RegistryModuleOwnerCustom(registryModuleOwnerCustomAddress);

    console.log("Calling registerAdminViaOwner for token at address: ", tokenAddress);
    registryModuleOwnerCustom.registerAdminViaOwner(tokenAddress);
  }
}
