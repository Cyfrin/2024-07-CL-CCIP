## Environment Setup
1. create a `.env` file from `.env.example`
2. make sure to populate env the following variables
```
PRIVATE_KEY=""
CHAIN_ID=
REMOTE_CHAIN_ID=

SEPOLIA_RPC_URL=
AVAX_SEPOLIA_RPC_URL=
BSC_TESTNET_RPC_URL=
```

## Follow the execution of these in sequence

1. `cd` to the ccip directory

2. run `MainSetupScript` for chains where you would like to deploy token and token pools.

```sh
 forge script ./ccip/scripts/MainSetup.s.sol:MainSetupScript --rpc-url $<RPC_URL> --broadcast -vvvv
```

3. To set the remote config, run this script for both chains.

```sh
 forge script ./ccip/scripts/05_ApplyChainUpdates.s.sol:ApplyChainUpdates --rpc-url $<RPC_URL> --broadcast -vvvv
```

4. Ensure that step-3 is executed for both chains.



## Details of scripts executed in sequence by Main Script

1. Deploy a token

Any standard ERC20 can be used, but for testing, we recommend using the [BurnMintERC677](./shared/token/ERC677/BurnMintERC677.sol)
included in this repo. This token is also used in all Foundry tests. The next steps will assume this token is used.

Ensure to fill in the token details in [01_BurnMintERC677Deploy](./ccip/scripts/01_BurnMintERC677Deploy.s.sol)

2. Deploy a token pool

Assuming the `BurnMintERC677` has been deployed, we can deploy a [BurnMint](../../ccip/pools/BurnMintTokenPool.sol) token pool.
If your token does not support burning and minting you should use the [LockRelease](ccip/pools/LockReleaseTokenPool.sol)
token pool variant. There are multiple variants of the burnMint pool, each using a different burn signature.

Ensure to fill in the token pool details in [02_BurnMintTokenPoolDeploy](./ccip/scripts/02_BurnMintTokenPoolDeploy.s.sol)

3. Initiate the claim to be the admin of the token

We can now claim to be the admin of the just deployed token. Since BurnMintERC677 implements the `owner` function, we
will use that to make our claim. We call `registerAdminViaOwner` with the only argument being the token address, from the owner account. The call should
set the `pendingAdministrator` in the TokenAdminRegistry.


4. Complete admin registration

The TokenAdminRegistry always uses a 2-step owner transfer. To complete owner registration, we call `acceptAdminRole` with the token address to accept our admin role.

5. Set the remote pool(s) on the pool

Assuming we've completed the above deployment steps on at least one other chain, we can set the remote tokens and pools
on our local pool. To do that we call `applyChainUpdates` on the token pool. The arguments are as follows

```solidity
  struct ChainUpdate {
    uint64 remoteChainSelector; // ──╮ Remote chain selector
    bool allowed; // ────────────────╯ Whether the chain should be enabled
    bytes remotePoolAddress; //        Address of the remote pool, ABI encoded in the case of a remote EVM chain.
    bytes remoteTokenAddress; //       Address of the remote token, ABI encoded in the case of a remote EVM chain.
    RateLimiter.Config outboundRateLimiterConfig; // Outbound rate limited config, meaning the rate limits for all of the onRamps for the given chain
    RateLimiter.Config inboundRateLimiterConfig; // Inbound rate limited config, meaning the rate limits for all of the offRamps for the given chain
  }
```

Note that the remotePoolAddress and the remoteTokenAddress are abi-encoded for EVM chains so that v1.5 can also support 
non-EVM chains. You can disable the rate limits for this example, they can always be adjusted at a later time. To do this
pass in `false` for `isEnabled` and `0`, `0` for `capacity` and `rate`.

6. Set the pool for the token

To set a pool for a token we call `setPool` on the TokenAdminRegistry with as arguments the token and then the pool.
After this step, CCIP will allow token transfers between the configured chains we have set in the previous step.

