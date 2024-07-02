.PHONY: slither
slither:
	 slither ./ccip \
	--exclude solc-version,pragma,low-level-calls,timestamp,assembly,costly-loop,reentrancy-events \
    --filter-paths "Router.sol|PriceRegistry.sol|MerkleMultiProof.sol|vendor|foundry-lib"

	slither ./ccip/onramp \
    --exclude solc-version,pragma,low-level-calls,timestamp,assembly,costly-loop,reentrancy-events \
    --filter-paths "Router.sol|PriceRegistry.sol|MerkleMultiProof.sol|RMN.sol|vendor|foundry-lib"

	slither ./ccip/offramp \
	--exclude solc-version,pragma,low-level-calls,timestamp,assembly,costly-loop,reentrancy-events \
	--filter-paths "Router.sol|PriceRegistry.sol|MerkleMultiProof.sol|RMN.sol|vendor|foundry-lib"

	slither ./ccip/pools \
	--exclude solc-version,pragma,low-level-calls,timestamp,assembly,costly-loop,reentrancy-events,dead-code,unimplemented-functions \
	--filter-paths "Router.sol|PriceRegistry.sol|MerkleMultiProof.sol|RMN.sol|vendor|foundry-lib"

	slither ./ccip/libraries \
	--exclude solc-version,pragma,low-level-calls,timestamp,assembly,costly-loop,reentrancy-events,dead-code,unimplemented-functions \
	--filter-paths "Router.sol|PriceRegistry.sol|MerkleMultiProof.sol|RMN.sol|vendor|foundry-lib"

	slither ./ccip/tokenAdminRegistry \
	--exclude solc-version,reentrancy-events,unused-return,pragma,assembly


.PHONY: aderyn
aderyn:
	aderyn -x "ccip/Router.sol,ccip/ARMProxy.sol,ccip/ocr/OCR2Base.sol,ccip/ocr/OCR2BaseNoChecks.sol,ccip/ocr/OCR2Abstract.sol,ccip/PriceRegistry.sol,ccip/libraries/MerkleMultiProof.sol,ccip/libraries/RateLimiter.sol,ccip/libraries/USDPriceWith18Decimals.sol,ccip/pools/USDC/IMessageTransmitter.sol,ccip/pools/USDC/ITokenMessenger.sol,ccip/interfaces/IRouterClient.sol,ccip/interfaces/IRouter.sol,ccip/applications/CCIPClientExample.sol,ccip/applications/DefensiveExample.sol,ccip/applications/CCIPReceiver.sol,ccip/AggregateRateLimiter.sol,ccip/applications/PingPongDemo.sol"

