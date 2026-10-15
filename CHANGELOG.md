# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `AffixRegistry` accepts ETH through `receive` and `fallback`, emitting `EthReceived`
- Owner-only `withdrawSponsorFunds(amount)` on `AffixRegistry`
- `FundRegistry` script to send 0.0001 ETH to a registry
- Tests for ETH handling and payable `addAgent`

### Changed

- `AffixRegistry` inherits OpenZeppelin `Ownable`; `admin` is replaced by `owner()`
- `AffixFactory.registerEntity` takes `entityOwner`; `EntityRegistered` and `getEntityDetails` expose `owner`
- `addAgent` is payable, requires at least 0.000001 ETH and forwards 0.000001 ETH to the new agent
- Solidity compiler bumped to 0.8.30
- Factory salt bumped to `AFFIX_DOCUMENT_FACTORY_V2`; scripts point to the V2 factory

### Removed

- Test-only `issueDocumentOpenBar` from `AffixRegistry`
