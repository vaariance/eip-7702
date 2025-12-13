# Changelog

## 1.0.0 (2025-12-13)


### Features

* add comprehensive documentation ([c5d0cfa](https://github.com/vaariance/eip-7702/commit/c5d0cfaeb37cd37d56c539045a1c84d989de1010))
* add EIP-7702 authorization builder and related changes ([37b4746](https://github.com/vaariance/eip-7702/commit/37b4746600d7ea943c7232a9eda245423d68e512))
* **builders:** add base implementation for EIP-7702 builders ([e38373b](https://github.com/vaariance/eip-7702/commit/e38373b0e7c87d08204a75b6218335848e68a50d))
* **client:** add EIP7702Client for delegation operations ([53237ff](https://github.com/vaariance/eip-7702/commit/53237ffdee7861c5c12dd100fe456cc4f39243a4))
* **client:** add executor support and gas transformation for EIP-7702 transactions ([35c7788](https://github.com/vaariance/eip-7702/commit/35c77880eb54560bec3cc03cd8e4cfbf00ea5003))
* **erc4337:** add ERC-4337 user operation extension ([7234636](https://github.com/vaariance/eip-7702/commit/72346366760c1a1fb6312938ef3d9af1253f9f6a))
* implement EIP-7702 transaction signing and authorization ([4b290f5](https://github.com/vaariance/eip-7702/commit/4b290f5eda281e6172a9415a43cd9d041571b311))
* **test:** add comprehensive test suite for EIP-7702 implementation ([d369b3f](https://github.com/vaariance/eip-7702/commit/d369b3fe59cf3dafea946d714a86d12c9bd61cac))

## 0.1.0

* ✨ EIP-7702 Core Implementation
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

* 🧰 Builder Layer
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

* 🚀 High-Level Client
  * `Eip7702Client` provides simple entrypoints:
    * `delegateAndCall`
      → Builds + signs + broadcasts a 7702 transaction, performing delegation if needed.
    * `revokeDelegation`
      → Clears delegation using 7702 SetCode flow.

* 🔌 4337 Integration Helpers : `canonicalizeUserOp` for binding 7702 authorization with ERC-4337 user operations.
