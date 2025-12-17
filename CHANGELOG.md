# Changelog

## [1.1.0](https://github.com/vaariance/eip-7702/compare/v1.0.1...v1.1.0) (2025-12-17)


### Features

* add call method for delegated execution ([#5](https://github.com/vaariance/eip-7702/issues/5)) ([eb90840](https://github.com/vaariance/eip-7702/commit/eb90840c419b9254a8b0a2f7e074b2783ac5e841))

## [1.0.1](https://github.com/vaariance/eip-7702/compare/v1.0.0...v1.0.1) (2025-12-13)


### Bug Fixes

* improve package score on pub.dev ([a3985b8](https://github.com/vaariance/eip-7702/commit/a3985b8dda8a0a9cf1cc5d159117e957335ffdbf))
* make publish workflow to trigger on tag push instead of release ([62a592f](https://github.com/vaariance/eip-7702/commit/62a592f85690011e66577d75ac83086ab27cee18))

## 1.0.0 (2025-12-13)

### Features

* ✨ EIP-7702 Core Implementation ([4b290f5](https://github.com/vaariance/eip-7702/commit/4b290f5eda281e6172a9415a43cd9d041571b311))
  * Full Dart implementation of EIP-7702 typed transactions (type 0x04).
  * Support for constructing:
    * `Unsigned7702Tx`
    * `Signed7702Tx`
    * EIP-7702 authorization tuples.
  * RLP encoding for:
    * EIP-1559 base fields
    * AccessLists (EIP-2930 compatible)
    * authorizationList (EIP-7702-specific)
  * Signer Abstractions:
    * `Signer.raw(Uint8List)` for raw private keys.
    * `Signer.eth(EthPrivateKey)` for web3dart private keys.
  * Automatic v/yParity normalization for ECDSA:
    * yParity stored as `0/1` for EIP-7702.
    * v normalized to `27/28` for compatibility with `ecRecover`.

* 🧰 Builder Layer ([37b4746](https://github.com/vaariance/eip-7702/commit/37b4746600d7ea943c7232a9eda245423d68e512))
  * AuthorizationBuilder
    * Builds unsigned authorization messages with resolved chain ID + nonce.
    * Produces signed authorization tuples.
    * `buildAndSignIfNeeded` automatically avoids redundant delegation.
  * SetCodeTxBuilder
    * Builds full 0x04 typed transactions including: Nonce resolution, EIP-1559 gas estimation, AccessList, AuthorizationList
  * Delegation Detection
    * Implements correct parsing of EIP-7702 delegation stubs:
      * Detects `0xef0100` || `<impl>` prefix.
      * Extracts delegated implementation address.

* 🚀 High-Level Client ([53237ff](https://github.com/vaariance/eip-7702/commit/53237ffdee7861c5c12dd100fe456cc4f39243a4))
  * `Eip7702Client` provides simple entrypoints:
    * `delegateAndCall`
      → Builds + signs + broadcasts a 7702 transaction, performing delegation if needed.
    * `revokeDelegation`
      → Clears delegation using 7702 SetCode flow.

* 🔌 4337 Integration Helpers : `canonicalizeUserOp` for binding 7702 authorization with ERC-4337 user operations. ([7234636](https://github.com/vaariance/eip-7702/commit/72346366760c1a1fb6312938ef3d9af1253f9f6a))
* **docs:** add comprehensive documentation ([c5d0cfa](https://github.com/vaariance/eip-7702/commit/c5d0cfaeb37cd37d56c539045a1c84d989de1010))
* **test:** add comprehensive test suite for EIP-7702 implementation ([d369b3f](https://github.com/vaariance/eip-7702/commit/d369b3fe59cf3dafea946d714a86d12c9bd61cac))
