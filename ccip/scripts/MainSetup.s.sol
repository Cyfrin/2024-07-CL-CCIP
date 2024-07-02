// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./01_BurnMintERC677Deploy.s.sol";
import "./02_BurnMintTokenPoolDeploy.s.sol";
import "./03_RegisterAdminViaOwner.s.sol";
import "./04_ClaimTokenAdminRole.s.sol";
import "./05_ApplyChainUpdates.s.sol";
import "./06_SetPoolForToken.s.sol";


/**
 * How to run:
 * 1. set desired CHAIN_ID in env
 * 2. source .env
 * 3. forge script ./ccip/scripts/MainSetup.s.sol:MainSetupScript --rpc-url $<RPC_URL> --broadcast -vvvv
 *
 * This script auto-updates token address in config.json.
 * If you wish to use a different token in following steps, you can manually set it.
 */
contract MainSetupScript is BurnMintERC677Deploy, BurnMintTokenPoolDeploy, RegisterAdminViaOwner, ClaimTokenAdminRole, ApplyChainUpdates, SetPoolForToken{

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployBurnMintERC677();
        deployBurnMintTokenPool();
        registerAdminViaOwner();
        claimTokenAdminRole();
        setPoolForToken();
        vm.stopBroadcast();
    }

}

