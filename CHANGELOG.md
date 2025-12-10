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
