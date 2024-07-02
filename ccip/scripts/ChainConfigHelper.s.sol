// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

// Updated ChainConfig struct with new fields
  struct ChainConfig {
    string name;
    uint64 chainSelector;
    address token;
    address tokenPool;
    address router;
    address tokenAdminRegistry;
    address registrationModule;
    address rmnProxy;
    address[] allowList;
  }

  struct TokenConfig {
    string name;
    string symbol;
    uint8 decimals;
    uint256 maxSupply;
  }

contract ChainConfigHelper is Script {
  function getTokenConfig() internal view returns (TokenConfig memory) {
    string memory json = vm.readFile("./config.json");
    return TokenConfig(
      vm.parseJsonString(json, ".defaultTokenConfig.name"),
      vm.parseJsonString(json, ".defaultTokenConfig.symbol"),
      uint8(vm.parseJsonUint(json, ".defaultTokenConfig.decimals")),
      vm.parseJsonUint(json, ".defaultTokenConfig.maxSupply")
    );
  }

  function getChainConfig(uint256 chainId) internal view returns (ChainConfig memory config) {
    string memory json = vm.readFile("./config.json");
    string memory basePath = string.concat(".chains.", vm.toString(chainId), ".");

    config.chainSelector = uint64(vm.parseJsonUint(json, string.concat(basePath, "chainSelector")));
    config.token = vm.parseJsonAddress(json, string.concat(basePath, "Token"));
    config.tokenPool = vm.parseJsonAddress(json, string.concat(basePath, "TokenPool"));
    config.router = vm.parseJsonAddress(json, string.concat(basePath, "Router"));
    config.tokenAdminRegistry = vm.parseJsonAddress(json, string.concat(basePath, "TokenAdminRegistry"));
    config.registrationModule = vm.parseJsonAddress(json, string.concat(basePath, "RegistrationModule"));
    config.rmnProxy = vm.parseJsonAddress(json, string.concat(basePath, "RMN"));
    config.allowList = vm.parseJsonAddressArray(json, string.concat(basePath, "allowList"));
  }

  function persistTokenAddress(uint256 chainId, address token) internal {
    string memory basePath = string.concat(".chains.", vm.toString(chainId), ".");
    vm.writeJson(vm.toString(token), "./config.json", string.concat(basePath, "Token"));
  }

  function persistTokenPoolAddress(uint256 chainId, address tokenPool) internal {
    string memory basePath = string.concat(".chains.", vm.toString(chainId), ".");
    vm.writeJson(vm.toString(tokenPool), "./config.json", string.concat(basePath, "TokenPool"));
  }
}