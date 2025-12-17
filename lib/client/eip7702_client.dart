part of '../eip7702.dart';

/// Creates a fully configured [Eip7702Client] for performing EIP-7702
/// delegation operations.
///
/// This factory function is the primary entry point for most applications.
/// It handles:
///  - Creating or accepting a [Web3Client] for RPC communication
///  - Building an [Eip7702Context] with the specified [delegateAddress]
///  - Instantiating [AuthorizationBuilder] and [SetCodeTxBuilder]
///  - Wiring everything together into a ready-to-use client
///
/// The function supports two modes:
///  1. **Managed client**: Provide [rpcUrl] and optionally [transformer].
///     A new [Web3Client] will be created internally via [create7702Context].
///  2. **Custom client**: Provide [customClient] to use your own
///     [Web3Client] instance. In this mode, [rpcUrl] is ignored.
///
/// Parameters:
///  - [rpcUrl] — the Ethereum JSON-RPC endpoint URL (required unless using
///    [customClient]).
///  - [delegateAddress] — the implementation contract address that EOAs will
///    delegate to, as a hex string.
///  - [customClient] — optional pre-configured [Web3Client]. If provided,
///    [rpcUrl] and [transformer] are ignored.
///  - [transformer] — optional function to modify gas estimates.
///
/// Returns a fully initialized [Eip7702Client] ready to perform delegation
/// and call operations.
///
/// ### Example (managed client)
/// ```dart
/// final client = create7702Client(
///   rpcUrl: 'https://mainnet.infura.io/v3/YOUR_KEY',
///   delegateAddress: '0x1234...',
///   transformer: (gas) => gas * BigInt.from(12) ~/ BigInt.from(10),
/// );
///
/// await client.delegateAndCall(
///   signer: mySigner,
///   to: contractAddress,
///   data: callData,
/// );
/// ```
///
/// ### Example (custom client)
/// ```dart
/// final customWeb3 = Web3Client('https://rpc.example', http.Client());
/// final client = create7702Client(
///   rpcUrl: '', // ignored
///   delegateAddress: '0x1234...',
///   customClient: customWeb3,
/// );
/// ```
Eip7702Client create7702Client({
  required String rpcUrl,
  required HexString delegateAddress,
  Web3Client? customClient,
  GasTransformFn? transformer,
}) {
  final ctx =
      customClient != null
          ? Eip7702Context(
            delegateAddress: delegateAddress.ethAddress,
            web3Client: customClient,
            transformer: transformer,
          )
          : create7702Context(
            rpcUrl: rpcUrl,
            delegateAddress: delegateAddress,
            transformer: transformer,
          );

  final authBuilder = AuthorizationBuilder(ctx);
  final txBuilder = SetCodeTxBuilder(ctx);
  return Eip7702Client(ctx, authBuilder, txBuilder);
}

/// {@macro Eip7702ClientBase}
class Eip7702Client implements Eip7702ClientBase {
  final Eip7702Context ctx;
  final AuthorizationBuilder _authBuilder;
  final SetCodeTxBuilder _txBuilder;

  Eip7702Client(this.ctx, this._authBuilder, this._txBuilder);

  @override
  Future<HexString> call({
    required Signer txSigner,
    required HexString to,
    Uint8List? data,
    BigInt? value,
  }) async {
    final raw = await _txBuilder.buildSignAndEncodeRaw(
      signer: txSigner,
      to: to,
      value: value,
      data: data,
      authorizationList: [],
    );

    final hash = await ctx.web3Client.makeRPCCall('eth_sendRawTransaction', [
      raw,
    ]);
    return hash;
  }

  @override
  Future<HexString> delegateAndCall({
    required Signer signer,
    required HexString to,
    Uint8List? data,
    BigInt? value,
    Signer? txSigner,
  }) async {
    final auth = await _authBuilder.buildAndSignIfNeeded(
      signer: signer,
      executor: txSigner != null ? Executor.relayer : Executor.self,
    );
    final raw = await _txBuilder.buildSignAndEncodeRaw(
      signer: txSigner ?? signer,
      to: to,
      value: value,
      data: data,
      authorizationList: [if (auth != null) auth],
    );

    final hash = await ctx.web3Client.makeRPCCall('eth_sendRawTransaction', [
      raw,
    ]);
    return hash;
  }

  @override
  Future<HexString> revokeDelegation({
    required Signer signer,
    Signer? txSigner,
  }) async {
    final ensureDelegating = await _authBuilder.isDelegatedTo(
      signer.ethPrivateKey.address,
      ctx.delegateAddress,
    );

    assert(ensureDelegating, 'EOA is not delegating to the delegate address');

    final unsignedAuth = await _authBuilder.buildUnsigned(
      eoa: signer.ethPrivateKey.address,
      executor: txSigner != null ? Executor.relayer : Executor.self,
      delegateOverride: zeroAddress,
    );
    final auth = signAuthorization(signer, unsignedAuth);

    final raw = await _txBuilder.buildSignAndEncodeRaw(
      signer: txSigner ?? signer,
      to: zeroAddress,
      value: BigInt.zero,
      data: Uint8List(0),
      authorizationList: [auth],
    );

    final hash = await ctx.web3Client.makeRPCCall('eth_sendRawTransaction', [
      raw,
    ]);
    return hash;
  }
}
