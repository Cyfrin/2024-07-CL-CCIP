# Chainlink CCIP v1.5

- Total Pool - $200,000
- H/M - $175,000
- Low - $10,000
- Community Judging - $15,000

- Starts: July 02, 2024, Noon UTC
- Ends: July 17, 2024, Noon UTC

- nSLOC: 2114

[//]: # (contest-details-open)

# Contest Details

## About the project

Chainlink [Cross Chain Interoperability Protocol](https://chain.link/cross-chain) (CCIP) is an interoperability solution that allows for the transfer of assets and/or messages between different blockchains. For a general overview of how CCIP works, we recommend reading the [official architecture docs](https://docs.chain.link/ccip/architecture). CCIP is currently live on 12 blockchains, with more to come in the near future.

This audit will be for version 1.5 of the CCIP protocol. CCIP v1.5 enables token issuers to integrate their tokens with CCIP in a self-serve manner while maintaining ownership of token pool contracts and customized implementation logic.

[Documentation](https://docs.chain.link/ccip)

[Explorer](https://ccip.chain.link/)

### Focus

We ask auditors to focus primarily on any aspect of the codebase that interacts with, or is, a token pool. Special areas to consider are:

- onRamp and offRamp interactions with token pools
- Token pool caller verification
- Impact of malicious tokens
  - Impact should be limited to only transactions that contain the token
- Impact of malicious token pools
  - Impact should be limited to only transactions that contain the token for this pool
- The token logic should be non-EVM compatible and work with non-EVM chains in the future

In addition, for changes to existing contracts:

- Out-of-order execution
- Interactions with / changes to the new Risk Management Network contract with fine-grained cursing

## Actors

- CCIP Owner
  - Manages CCIP through its privileged functions
  - A multi-signature contract structure that includes the entire DON and therefore inherits the security of the entire DON
  - **This means any exploits that involve the owner being compromised are out of scope**
  - [Source code](https://github.com/smartcontractkit/ccip-owner-contracts), not in scope
- Token Issuer
  - Wants their token to be transferable between multiple blockchains
  - Wants the process of adding their token to CCIP to be fast and easy to do
- CCIP User
  - The initiator of CCIP transactions
  - Bridges tokens across chains
  - Wants many tokens to be available on CCIP
- CCIP Token Administrator
  - Controls the mapping between a token and a token pool
  - Proves ownership of the token to assume the role

### Contracts

We will examine the new contract introduced in this version of CCIP. For any existing contract, we will examine the main changes in them, but for a basic understanding of existing contracts please read the [public docs](https://docs.chain.link/ccip/architecture).

#### TokenAdminRegistry

The administrator of a token contract will be stored in the TokenAdministratorRegistry contract. This contract is owned by the CCIP Owner which will have a single instance deployed on each chain where CCIP is active.
The TokenAdministratorRegistry will be a modular contract that at its core only stores the mapping between tokens and its Administrators and token pools. The registry is token pool type agnostic: It does not matter if the pool is of burnMint, lockRelease, or any other custom type.

The contract is not meant to be upgraded and is deliberately kept simple. It is extendable through RegistryModules.
We start with a single registry module that allows registration through the `owner()` and the `getCCIPAdmin()` functions.
In addition, the CCIP Owner can also propose administrators for tokens, allowing token contracts that cannot use the registration modules to still self-manage. Note that after registration even the CCIP Owner has zero permissions to modify or remove tokens.

The `owner()` and the `getCCIPAdmin()` methods have been chosen for different reasons. The `owner()` method is present on many existing contracts, meaning many contracts will be compatible without any modifications. The `getCCIPAdmin()` method is for protocols that are either upgradable or have not been deployed yet. This allows them to have an admin that is different from the owner of the contract, which might be preferable. Either one could be used, and the result of using either is that the returned address will be set as pendingAdministrator. This address then needs to explicitly accept the admin role before it takes effect.

#### Changes to existing contracts

- Token prices are now optional, due to the unbounded number of tokens that cannot be priced.
  - By default, all features that required token prices in the past are turned off. These can still be enabled on a case-by-case basis when a price source is configured.
- Tokens no longer require a custom fee config to be set. If none is set, the default values are used, This means that all self-serve tokens will use the default values.
- Aggregate rate limiting is no longer required but optional.
- The token pool IO has been changed to give more information to token pools and to allow them to send data from the source pool to the destination pool by including a payload in the CCIP message.
- The Solidity version has been bumped from 0.8.19 to 0.8.24.
  - NOTE: We explicitly configure the Paris upgrade (The Merge) as a hard fork to ensure the compiled contracts work on a broad spectrum of EVM chains.
- Risk Management Network (in RMN.sol, previously ARM in ARM.sol):
  - Risk Management Network cursing now happens per-chain and is no longer global.
    - Previously, a “curse” would be applied to every chain at the same time, regardless of the issue that caused it. With this new version, depending on the curse reason, RMN is able to only curse relevant chains. This means that an issue on chain A will only affect lanes to and from chain A, and not the entire CCIP system.
- Out-of-order (OOO) execution
  - We allow for out-of-order execution by setting a boolean in the extraArgs. This effectively means the nonce isn't used for that particular transaction. This is especially useful for applications where ordering doesn't matter.
  - Out-of-order execution allows for broader support for chains that behave differently from Ethereum, like ZK chains which might revert the entire transaction due to a ZK overflow. This could lead to a transaction being non-executable forever, which would block future transactions due to nonce ordering without OOO. Without nonce ordering enforced, even if a transaction fails due to ZK overflow, which cannot be gracefully handled, it won't block future transactions.

### Upgrading to self serve pools

CCIP already runs on many chains with various token pools. We have constructed an upgrade path that requires no involvement from the token issuers that are currently listed on CCIP. The upgrade path is contained in two Foundry tests, one for upgrading the older pools (pre-v1.4) and one for the newest pools (v1.4), `test_tokenPoolMigration_Success_1_2` and `test_tokenPoolMigration_Success_1_4`.

Due to the differences between the older and the newer pools, the upgrade flow is slightly different. Both use the new `BurnMintTokenPoolAndProxy` or `LockReleaseTokenPoolAndProxy` pool contracts, which are both full self-serve token pools and can also act as a proxy for any older pool. For every older pool, we'd deploy the appropriate proxy pool and point it to the existing pool. For the pre-v1.4 pools, we would configure the proxy pool as a ramp on the contract, meaning it is allowed to make permissioned calls to the pool. The newer 1.4 pools check for allowed ramps in the Router, which means that we need to atomically change the Router to point to the new v1.5 lanes and change the router in the v1.4 pool to point to the v1.5 proxy pool. This can easily be done through the CCIP Admin as the multi-signature contract allows for batch transactions.

After the router has been changed to point to v1.5 onRamps, all new messages will use the new version of CCIP, without any downtime. Older messages will still be processed and the existing pre-v1.5 token pools will still allow for the minting/releasing of funds for these messages.

NOTE: The USDC token pools don't have a proxy version as they can be upgraded without any interaction with Circle, due
to the use of Circle’s CCTP.

### Assumptions

- A token issuer is not malicious toward their own token
  - If they are, there are more effective methods to exploit their users than to do so through CCIP
  - We are aware they could deploy pools that would only take funds and never release them
  - We are aware they could deploy pools that always revert, meaning the transaction can never be completed successfully
- Some tokens will require custom pools. The assumption is that the given pools will use standard ERC-20 tokens.
  - The protocol is designed in a way that gives a lot of options while designing custom pools
    - Pools can, by default, send one slot worth of data (32 bytes) to the receiving pool. This could e.g. contain encoded data to support tokens that have different decimals on different chains.
    - The receiving pool can change the amount that is received, which will properly be forwarded to the end dApp
    - Attributes like the originalSender allow for token pools with allowLists
  - We are aware that reentering CCIP is possible from a token pool. This should not impact the protocol
    - The ordering of some events can be changed, we do not rely on the ordering of events offchain

[//]: # (contest-details-close)

[//]: # (scope-open)

## Scope (contracts)

```js
ccip
├── interfaces
│   ├── IGetCCIPAdmin.sol
│   ├── IOwner.sol
│   ├── IPool.sol
│   └── ITokenAdminRegistry.sol
├── libraries
│   ├── Client.sol
│   ├── Internal.sol
│   └── Pool.sol
├── offRamp
│   └── EVM2EVMOffRamp.sol
├── onRamp
│   └── EVM2EVMOnRamp.sol
├── pools
│   ├── USDC
|   |   ├── USDCTokenPool.sol
│   └── all contract at this layer
├── tokenAdminRegistry
│   ├── RegistryModuleOwnerCustom.sol
│   └── TokenAdminRegistry.sol
└── CommitStore.sol
```

### Out of scope

- Any contract not seen above in the “Scope (contracts)” section
- All files outside the ccip folder are out of scope.
- Any exploits that involve the owner being compromised are out of scope
- CCIP Owner contracts ([Source code](https://github.com/smartcontractkit/ccip-owner-contracts))

## Compatibilities

Blockchains: Any fully EVM-compatible chain

Tokens: Any contract can be registered as a token pool or token. This does not mean CCIP works for every token and/or pool. Any standard ERC-20 token should be supported. Strictly speaking, we currently only support ERC-20, but that does not mean other variants won't work or cannot be made to work with a custom token pool. With a custom token pool, even rebasing assets could be made to work by sending the underlying `shares` data in the payload from the source pool to the destination pool.

We do **not** offer any guarantees of functionality for anything besides standard ERC-20s. We do guarantee that any token should **at most** be able to influence the CCIP message it is contained in. This means we are aware that a malicious token could make any CCIP message containing that malicious token un-executable forever. This poses a risk when a transaction contains multiple tokens, as a single one of them could prevent the other from being released. This vector is known and acknowledged and not in scope for this contest.

[//]: # (scope-close)

[//]: # (getting-started-open)

## Setup

Clone contest repo
```bash
git clone https://github.com/Cyfrin/2024-07-CL-CCIP.git
code 2024-07-CL-CCIP
```

Build & test

```bash
forge build

forge test
```

Static analysis, assuming slither and adaryn are installed.

```bash
make slither -i
```

```bash
make aderyn
```

## Getting started

We encourage anyone to deploy and register tokens on our CCIP testnet environment. There are various tests included in this repo that depict how all the contracts should be deployed to form a complete CCIP system, but to get anyone started we have deployed CCIP v1.5 across three testnets, ready to be used. These testnets are Sepolia, Avalanche Fuji, and BNB Chain Testnet. Due to CCIP requiring chain finality, we advise using Avalanche Fuji or BNB Chain Testnet as a source chain to speed up testing. The contract addresses are listed below.

### Adding your token to CCIP

Adding your token to CCIP can easily be done in just a few steps. This guide assumes you do not have a token deployed yet. If you do, you can skip the token deploy step.

The steps are as follows:

- Deploy a token
- Deploy a token pool
- Claim to become the admin of the token
- Set the pool for the token
- Set the remote pool(s) on the pool

Below is an image of the dependency graph between these actions:

![Registration order](https://res.cloudinary.com/droqoz7lg/image/upload/v1719916109/registration_order_dmfsos.png)

- Deploy a token

Any standard ERC-20 token can be used, but for testing, we recommend using the [BurnMintERC677](https://github.com/Cyfrin/2024-07-CL-CCIP/blob/main/shared/token/ERC677/BurnMintERC677.sol) included in this repo. This token is also used in all of the Foundry tests. The next steps will assume this token is used.

- Deploy a token pool

Assuming the BurnMintERC677 has been deployed, we can deploy a [BurnMint](https://github.com/Cyfrin/2024-07-CL-CCIP/blob/main/ccip/pools/BurnMintTokenPool.sol) token pool.
If your token does not support burning and minting you should use the [LockRelease](https://github.com/Cyfrin/2024-07-CL-CCIP/blob/main/ccip/pools/LockReleaseTokenPool.sol) token pool variant. There are multiple variants of the BurnMint pool, each using a different burn signature.

- Claim to become the admin of the token

We can now claim to become the admin of the just deployed token. Since BurnMintERC677 implements the `owner()` function, we will use that to make our claim. We call `registerAdminViaOwner` with as the only argument the token address. We should now be set as the pendingAdministrator in the TokenAdminRegistry. We call `acceptAdminRole` again with the token address and have successfully claimed our admin role.

- Set the remote pool(s) on the pool

Assuming we've completed the above deployment steps on at least one other chain, we can set the remote tokens and pools on our local pool. To do that we call `applyChainUpdates` on the token pool. The arguments are as follows:

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

Note that the remotePoolAddress and the remoteTokenAddress are abi-encoded for EVM chains. This is to support non-EVM in the future. You can disable the rate limits for this example, they can always be adjusted at a later time. To do this pass in `false` for `isEnabled` and `0`, `0` for `capacity` and `rate`.

- Set the pool for the token

To set a pool for a token we call `setPool` on the TokenAdminRegistry with the token and pool as arguments. After this step, CCIP will allow token transfers between the configured chains we have set in the previous step

Congratulations, your token is now cross-chain!

If you used the `BurnMintERC677` token you can call `grantMintAndBurnRoles(address burnAndMinter)` on it with as only argument your wallet address to permit yourself to mint. Then call `mint(address account, uint256 amount)` to create some tokens. These can now be used to call `ccipSend` on the Router for your first cross-chain token transaction with the newly deployed tokens and pools.

### Contract addresses

We have deployed this version of CCIP on testnets for this audit. It is deployed on three testnets:

Sepolia

- Router: `0xadd3cb08d0edbf71edade497436c73abf683ef0c`
- TokenAdminRegistry: `0x6a6eec13c4525eadda517c77e27b4bcfe74f1ab9`
- RegistrationModule: `0x94d70e71715d946b05d1fcd32cf04e3077016b7d`
- RMN: `0xe013be5430b72fa175c8e506c93dc056b70a2191`

Avalanche

- Router: `0xe48712efd95adc5ddf9ad240ae8cd3a2663ba794`
- TokenAdminRegistry: `0x3f764ff0e803322e9e78f44840a1c478a2ae8975`
- RegistrationModule: `0xe9d8a02097f7a1c76371b96791de922601cefb19`
- RMN: `0x670303037afdf186a6539ba2b6df1b9d5c849301`

Binance Chain

- Router: `0xa9e2c14215b0c8188a53c4186dbcbcb55b6e16dc`
- TokenAdminRegistry: `0xe2865c4310918c245abcca25a27834201ba28421`
- RegistrationModule: `0xebfd2f2068fc62f2d168fad34e81cc07be9cfdb9`
- RMN: `0x7766ea125c05c3c76d1fe09bd689fded57fcf9a8`

NOTE: This deployment is done with a mockRMN contract. This will always return true when asked if a root is blessed. This is not representative of a real deployment but it should not impact the required testing for this audit.

NOTE: Fees have been lowered on this deployment to allow for in-depth testing without requiring significant testnet assets.

NOTE: This deployment uses only static token prices, which means the response from the PriceRegistry could not reflect the latest token prices.

### Tooling versions used

The following versions have been validated to work with this repository.

- Foundry `nightly-c4a984fbf2c48b793c8cd53af84f56009dd1070c`
- Aderyn: `0.1.4`
- Slither: `0.10.3`

[//]: # (getting-started-close)

[//]: # (known-issues-open)

## Known issues

#### Token issuer is malicious

- Any malicious token issuer can negatively impact transactions that contain their token.
- Any malicious token issuer can make transactions that contain their token fail forever, leading to the loss of any funds in that transaction.
  - Users should be cautious about sending tokens they do not trust.
  - Sending a single token per transaction will prevent any contagion to other tokens.
  - On some chains, there are methods through which a malicious token issuer can cause an entire transaction to revert without being caught by the try-catch, such as overflowing ZK proof size on EVM-compatible zkRollups. In such edge cases, a malicious token issuer can block following transactions from the same sender at the destination when not using out-of-order execution, potentially causing unbounded loss.
- Anyone can list any token with any name or affiliation. The CCIP Owner has zero control over what is listed and cannot modify or remove any tokens. This means there could be tokens listed with names or affiliations that are not endorsed by the CCIP Owner or Chainlink Labs.
- Malicious tokens or token pools will be able to re-enter.
  - This should not have any negative impact on the CCIP system.
  - This does allow them to re-order some events, but never to double spend.

#### Token issuer responsibility

- When a token issuer misconfigures their own tokens/pools, users could potentially not receive these tokens.
  - The CCIP Owner has no special access to resolve misconfigurations, only the token issuer can do so.
- Token issuers can deploy token pools without rate limits, which is different from today where every token pool is rate-limited.

#### Compatibility

- Some tokens will not work.
  - For example, fee-on-transfer tokens won't work because they require multiple hops in the CCIP contracts.
  - They will still be able to register their token, as this process is fully permissionless. This could negatively impact transactions containing these tokens.
  - Pool `releaseOrMint` is bound by a per-ramp `maxPoolReleaseOrMintGas`, and Token transfer is bound by a per-ramp `maxTokenTransferGas`. As a result, pools or tokens that are extremely gas-intensive may not be supported. Similarly, pool data that can be relayed from source to destination is bound as well.
- Not every token will be able to permissionlessly register.
  - There will be tokens that do not expose the `owner` and don't have the `getCCIPAdmin` function.
  - These can still be onboarded in the same way all current tokens are onboarded: manually through the CCIP Owner.

#### Other

- CCIP Owner is a trusted role.
  - As mentioned previously, the multi-signature contract structure includes the entire DON and therefore inherits the security of the entire DON.
- Solidity 0.8.24 is used and CCIP will be deployed on various chains that don't support the newer Solidity features.
  - We explicitly compile with the Paris hard fork to ensure compatibility.
- The aggregate rate limiter only works for tokens that have prices, as it's denominated in USD.
  - Self-serve tokens will not have prices, as it would be impractical to acquire accurate price sources for any arbitrary token, and writing these prices onchain would be economically unsustainable, and easily exploitable.
  - This means that tokens default to **not** be included in the aggregate rate limiter.
- Router API `getSupportedTokens` is now deprecated, calling it will revert.
  - There is no longer an official API that returns all supported tokens for a given destination in 1 call.
  - One should iterate through tokens via `getAllConfiguredTokens` in TokenAdminRegistry and then call `isSupportedChain` on its token pool.

#### Additional Known Issues
Any issues as detected by LightChaser, detailed [here](https://github.com/Cyfrin/2024-07-CL-CCIP/issues/1)

[//]: # (known-issues-close)
