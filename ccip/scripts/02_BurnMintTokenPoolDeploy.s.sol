// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IBurnMintERC20} from "../../shared/token/ERC20/IBurnMintERC20.sol";
import "../pools/BurnMintTokenPool.sol";
import "./ChainConfigHelper.s.sol";
import "forge-std/Script.sol";

/**
 * How to run:
 * 1. set desired CHAIN_ID in env
 * 2. source .env
 * 3. forge script ./ccip/scripts/02_BurnMintTokenPoolDeploy.s.sol:BurnMintTokenPoolDeploy --rpc-url $<RPC_URL> --broadcast -vvvv
 *
 * This script auto-updates pool address in config.json.
 * If you wish to use a different pool in following steps, you can manually set it.
 */
contract BurnMintTokenPoolDeploy is ChainConfigHelper {
  function deployBurnMintTokenPool() internal {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    uint256 chainId = vm.envUint("CHAIN_ID");
    ChainConfig memory chainConfig = getChainConfig(chainId);

    // Parse the JSON configuration for the specific chainId
    address token = chainConfig.token;
    address rmnProxy = chainConfig.rmnProxy;
    address router = chainConfig.router;
    address[] memory allowList = chainConfig.allowList;

    console.log("Deploying BurnMintTokenPool contract on chainId: ", chainId);
    BurnMintTokenPool burnMintTokenPool = new BurnMintTokenPool(IBurnMintERC20(token), allowList, rmnProxy, router);

    console.log("****************************************************************************");
    console.log("***");
    console.log("***  BurnMintTokenPool deployed at: ", address(burnMintTokenPool));
    console.log("***");
    console.log("****************************************************************************");

    persistTokenPoolAddress(chainId, address(burnMintTokenPool));

  }
}
