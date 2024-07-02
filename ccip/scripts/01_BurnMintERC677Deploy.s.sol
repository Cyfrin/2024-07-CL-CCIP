// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/token/ERC677/BurnMintERC677.sol";
import "./ChainConfigHelper.s.sol";
import "forge-std/Script.sol";

/**
 * How to run:
 * 1. set desired CHAIN_ID in env
 * 2. source .env
 * 3. forge script ./ccip/scripts/01_BurnMintERC677Deploy.s.sol:BurnMintERC677Deploy --rpc-url $<RPC_URL> --broadcast -vvvv
 *
 * This script auto-updates token address in config.json.
 * If you wish to use a different token in following steps, you can manually set it.
 */
contract BurnMintERC677Deploy is ChainConfigHelper {
  function deployBurnMintERC677() internal {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    uint256 chainId = vm.envUint("CHAIN_ID");
    console.log("Deploying BurnMintERC677 contract on chainId: ", chainId);

    TokenConfig memory tokenConfig = getTokenConfig();

    console.log("Deploying BurnMintERC677 contract with name: ", tokenConfig.name);

    // Deploy the contract with the parsed values
    BurnMintERC677 burnMintERC677 =
      new BurnMintERC677(tokenConfig.name, tokenConfig.symbol, tokenConfig.decimals, tokenConfig.maxSupply);
    
    console.log("****************************************************************************");
    console.log("***");
    console.log("***  BurnMintERC677 deployed at: ", address(burnMintERC677));
    console.log("***");
    console.log("****************************************************************************");

    // persisting the token address in the config.json
    persistTokenAddress(chainId, address(burnMintERC677));

  }
}
