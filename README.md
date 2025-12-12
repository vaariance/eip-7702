# EIP-7702 Library for flutter apps

A lightweight, modern implementation of EIP-7702 typed transactions (0x04), including authorization generation, transaction building, signing, and optional ERC-4337 compatibility helpers. Built with [web3dart](https://pub.dev/packages/web3dart).

The package is designed for wallets, account-abstraction layers, smart-account frameworks, and dApp-embedded signing experiences, where full control of signing, auth generation, and transaction serialization is required.

To Learn more about EIP-7702 visit: <https://eips.ethereum.org/EIPS/eip-7702>

## Usage - The happy path

```dart
final client = await Eip7702Client.create(
  rpcUrl: 'https://rpc.mychain.lfg/apikey=secretish...',
  delegateAddress: mySmartAccountImpl,
  // optional: customWeb3Client will be priotized if present
);

final signer = Signer.raw(myPrivateKeyBytes);

final txHash = await client.delegateAndCall(
  signer: signer,
  to: someDappContract,
  data: myCalldata,
);
```

This automatically:

- Detects whether the EOA is already delegated
- Builds + signs authorization if needed
- Builds + signs a typed 0x04 transaction
- Produces a raw hex payload
- Sends it to `eth_sendRawTransaction`

## Usage - Low Level Control

For applications that want more granular control, you can use each builder directly.

1. Build and sign authorization manually

```dart
final ctx = await Eip7702Context.forge(
  rpcUrl: rpc,
  delegateAddress: myImpl,
);

final authBuilder = AuthorizationBuilder(ctx);

final unsignedAuth = await authBuilder.buildUnsigned(
  eoa: signer.ethPrivateKey.address,
);

final auth = signAuthorization(signer, unsignedAuth);

// alternatively, you can skip the above 2 steps and call `buildAndSign`
```

This gives you the raw `(auth, signature)` tuple you can insert anywhere you like.

2. Build and sign the typed EIP-7702 transaction manually

```dart
final txBuilder = SetCodeTxBuilder(ctx);

final unsignedTx = await txBuilder.buildUnsigned(
  sender: signer.ethPrivateKey.address,
  to: someContract,
  data: myCallData,
  authorizationList: [auth],
);

final signedTx = await txBuilder.signUnsigned(
  signer: signer,
  unsignedTx: unsignedTx,
);

final rawHex = parseRawTransaction(signedTx);

// alternatively, you can skip the above 3 steps and call `buildSignAndEncodeRaw`
```

You now have rawHex which you can push to your own RPC flow:

```dart
await web3Client.makeRPCCall('eth_sendRawTransaction', [
      rawHex,
    ]);
```

## EIP-4337 Integration

This package includes utilities for embedding EIP-7702 authorization data inside a `UserOperation`, enabling hybrid flows where AA wallets can leverage delegation-based execution.

### Canonicalizing a UserOperation

```dart
final auth = await authBuilder.buildAndSign(
  signer: signer
);

// Insert auth into UserOp
final userOp = {
  "sender": signer.ethPrivateKey.address.hexEip55,
  "callData": myData,
  "callGasLimit": "0x5208",
  ...
};

final canon = canonicalizeUserOp(auth, userOp);

// ... continue with 4337 flow with the canon
```

To manually test signature recovery + validation

```dart
try {
  validateUserOp(auth, userOp);
} on AssertionError catch (e) {
  // Handle validation error
}
```

## Test

```sh
# run all tests
dart test tests

# run e2e test
dart test tests/e2e

# simulate a real testnet set_code_tx
export RPC_URL = "...lfg"
export PRIVATE_KEY_WITH_FUNDS = "...0x-i-have-some-testnet-eth"
dart test tests/__simulation__
# then follow up on the logs
```
