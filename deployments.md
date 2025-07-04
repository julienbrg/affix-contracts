# June 18 deployment

## Contract Addresses

• **Factory Contract**: `0x36FB4c117507a98e780922246860E499Bb7E996C` • **Registry Contract**:
`0x27a246684dc4C8d59EE76C6EB6bfEd0a9e756bF1`

## Institution Details

• **Institution Name**: Ministry of Sound • **Admin Address**: `0x502fb0dFf6A2adbF43468C9888D1A26943eAC6D1`

## Agent Addresses

• **Agent 1**: `0x502fb0dFf6A2adbF43468C9888D1A26943eAC6D1` (same as admin) • **Agent 2**:
`0x5F6A0ce3734225296330AA89C98a6ADBc046D311` (J's gg addr)

To add:

• **Agent 3**: `0x1F85697c211181C5c439135121d7e1f2E3Df147c` (G's gg addr)

## Additional Info

• **Total Institutions Registered**: 3 • **Total Agents in Registry**: 2 • **Network**: Sepolia Testnet (Chain
ID: 11155111) • **Factory Owner**: `0x502fb0dFf6A2adbF43468C9888D1A26943eAC6D1`

## Etherscan Links

• **Factory**: https://sepolia.etherscan.io/address/0x36FB4c117507a98e780922246860E499Bb7E996C • **Registry**:
https://sepolia.etherscan.io/address/0x27a246684dc4C8d59EE76C6EB6bfEd0a9e756bF1

# July4 deployment

```
➜ forge build
[⠊] Compiling...
[⠊] Compiling 37 files with Solc 0.8.24
[⠒] Solc 0.8.24 finished in 38.44s
Compiler run successful!

veridocs-contracts took 39s
➜ forge script script/DeployAffixFactory.sol \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --broadcast \
  --gas-limit 30000000 \
  --gas-price 150000000000 \
  --evm-version paris \
  --skip-simulation
[⠊] Compiling...
[⠢] Compiling 24 files with Solc 0.8.24
[⠆] Solc 0.8.24 finished in 14.66s
Compiler run successful!
Warning: EIP-3855 is not supported in one or more of the RPCs used.
Unsupported Chain IDs: 314159.
Contracts deployed with a Solidity version equal or higher than 0.8.20 might not work properly.
For more information, please see https://eips.ethereum.org/EIPS/eip-3855
Script ran successfully.

== Return ==
AffixFactoryAddress: address 0xB5CAb4359CBd4C03867A1320a14a6e4DBe7141dd

== Logs ==
  Deploying AffixFactory on chain ID: 314159
  Network name: Filecoin Calibration
  Using Safe Singleton Factory at: 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7
  Deployer/Future Factory Owner: 0x502fb0dFf6A2adbF43468C9888D1A26943eAC6D1
  Filecoin network detected - using higher gas settings
  AffixFactory creation code length: 12908 bytes
  Expected AffixFactory address: 0xB5CAb4359CBd4C03867A1320a14a6e4DBe7141dd
  AffixFactory deployed at: 0xB5CAb4359CBd4C03867A1320a14a6e4DBe7141dd
  Deployment verified successfully!
  Factory owner set to: 0x502fb0dFf6A2adbF43468C9888D1A26943eAC6D1
   Ownership correctly set to deployer

=== Deployment Complete ===
  Automatic verification disabled as requested
  Contract deployed and functional at: 0xB5CAb4359CBd4C03867A1320a14a6e4DBe7141dd
  Explorer URL: https://calibration.filscan.io/address/0xb5cab4359cbd4c03867a1320a14a6e4dbe7141dd

Deployment Summary:
  - Network: Filecoin Calibration
  - Chain ID: 314159
  - AffixFactory: 0xB5CAb4359CBd4C03867A1320a14a6e4DBe7141dd
  - Factory Owner: 0x502fb0dFf6A2adbF43468C9888D1A26943eAC6D1
  - Salt used: 0xe334f87c4b50d09cbded604ee29f1f3fc9b1f121d08fa3a6dbf44a027afd09f8
  - Explorer URL: https://calibration.filscan.io/address/0xb5cab4359cbd4c03867a1320a14a6e4dbe7141dd
  - Gas settings: Optimized for Filecoin network

Next steps:
  1. Register institutions using: registerInstitution(address admin, string name, string url)
  2. Fund the deployer address with tFIL for transaction fees

SKIPPING ON CHAIN SIMULATION.

##### filecoin-calibration-testnet
✅  [Success] Hash: 0x15b6b9b4fcfb1fc950c406bd1d34a2a69a5d31395f9e0071e455a22f906cc5d9
Block: 2810194
Paid: 0.000017684329380368 ETH (105721994 gas * 0.000167272 gwei)

✅ Sequence #1 on filecoin-calibration-testnet | Total Paid: 0.000017684329380368 ETH (105721994 gas * avg 0.000167272 gwei)


==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /Users/ju/veridocs-contracts/broadcast/DeployAffixFactory.sol/314159/run-latest.json

Sensitive values saved to: /Users/ju/veridocs-contracts/cache/DeployAffixFactory.sol/314159/run-latest.json


veridocs-contracts took 1m 32s
➜ forge script script/RegisterInstitution.s.sol \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --broadcast \
  --gas-limit 30000000 \
  --gas-price 150000000000 \
  --evm-version paris \
  --skip-simulation
[⠊] Compiling...
[⠃] Compiling 1 files with Solc 0.8.24^C

veridocs-contracts took 6s
➜ forge script script/RegisterInstitution.s.sol \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --broadcast \
  --gas-limit 30000000 \
  --gas-price 150000000000 \
  --evm-version paris \
  --skip-simulation
[⠊] Compiling...
[⠒] Compiling 1 files with Solc 0.8.24
[⠆] Solc 0.8.24 finished in 11.51s
Compiler run successful!
Warning: EIP-3855 is not supported in one or more of the RPCs used.
Unsupported Chain IDs: 314159.
Contracts deployed with a Solidity version equal or higher than 0.8.20 might not work properly.
For more information, please see https://eips.ethereum.org/EIPS/eip-3855
Script ran successfully.

== Return ==
registryAddress: address 0xE2b7f08d9879594e69784a86c5ca07cCae86A76a

== Logs ==
  Registering institution on chain ID: 314159
  Network: Filecoin Calibration
  Using AffixFactory at: 0xB5CAb4359CBd4C03867A1320a14a6e4DBe7141dd
  Factory owner: 0x502fb0dFf6A2adbF43468C9888D1A26943eAC6D1
  Script runner: 0x502fb0dFf6A2adbF43468C9888D1A26943eAC6D1
  Institution admin address: 0x502fb0dFf6A2adbF43468C9888D1A26943eAC6D1
  Institution name: Ministry of Sound
  Institution URL: https://affix.vercel.app/about
  Institution registered successfully!
  Registry contract deployed at: 0xE2b7f08d9879594e69784a86c5ca07cCae86A76a
  Registry admin: 0x502fb0dFf6A2adbF43468C9888D1A26943eAC6D1
  Registry name: Ministry of Sound
  Registry URL: https://affix.vercel.app/about
  Registry agent count: 0

Factory Statistics:
  - Total institutions: 1
  - Factory owner: 0x502fb0dFf6A2adbF43468C9888D1A26943eAC6D1

Institution Details:
  - Admin: 0x502fb0dFf6A2adbF43468C9888D1A26943eAC6D1
  - Name: Ministry of Sound
  - URL: https://affix.vercel.app/about
  - Is registered: true

Explorer Links:
  - Factory: https://calibration.filscan.io/address/0xb5cab4359cbd4c03867a1320a14a6e4dbe7141dd
  - Registry: https://calibration.filscan.io/address/0xe2b7f08d9879594e69784a86c5ca07ccae86a76a

Next steps:
  1. The admin can add agents using: addAgent(address agent)
  2. Admin/agents can issue documents using: issueDocument(string cid) or issueDocumentWithMetadata(string cid, string metadata)
  3. Anyone can verify documents using: verifyDocument(string cid)
  4. Admin can manage agents using: addAgent(address) and revokeAgent(address)
  5. Admin can update institution details using: updateInstitutionName(string) and updateInstitutionUrl(string)

Environment variables for next scripts:
  export REGISTRY_ADDRESS= 0xE2b7f08d9879594e69784a86c5ca07cCae86A76a
  export ADMIN_ADDRESS= 0x502fb0dFf6A2adbF43468C9888D1A26943eAC6D1

SKIPPING ON CHAIN SIMULATION.

##### filecoin-calibration-testnet
✅  [Success] Hash: 0xec741587307fbfa52f9c719c888f0bec2d48141d3cd55b1fbca62b07b75fb91f
Block: 2810207
Paid: 0.000016593588028817 ETH (81563819 gas * 0.000203443 gwei)

✅ Sequence #1 on filecoin-calibration-testnet | Total Paid: 0.000016593588028817 ETH (81563819 gas * avg 0.000203443 gwei)


==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /Users/ju/veridocs-contracts/broadcast/RegisterInstitution.s.sol/314159/run-latest.json

Sensitive values saved to: /Users/ju/veridocs-contracts/cache/RegisterInstitution.s.sol/314159/run-latest.json
```

## Affix Contracts - Filecoin Calibration

**Deployment Date**: July 4, 2025 **Network**: Filecoin Calibration (314159) **Compiler**: Solidity 0.8.24
**Optimization**: 10,000 runs

**Factory**: 0xB5CAb4359CBd4C03867A1320a14a6e4DBe7141dd **Registry**: 0xE2b7f08d9879594e69784a86c5ca07cCae86A76a

**Source Code**: github.com/julienbrg/affix-contracts **Institution**: Ministry of Sound **Admin**:
0x502fb0dFf6A2adbF43468C9888D1A26943eAC6D1
