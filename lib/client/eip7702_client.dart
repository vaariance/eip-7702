part of '../eip7702.dart';

/// {@macro Eip7702ClientBase}
class Eip7702Client implements Eip7702ClientBase {
  final Eip7702Context ctx;
  final AuthorizationBuilder _authBuilder;
  final SetCodeTxBuilder _txBuilder;

  Eip7702Client(this.ctx, this._authBuilder, this._txBuilder);

  @override
  Future<HexString> delegateAndCall({
    required Signer signer,
    required EthereumAddress to,
    Uint8List? data,
    EtherAmount? value,
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
      delegateOverride: EthereumAddress(Uint8List(20)),
    );
    final auth = signAuthorization(signer, unsignedAuth);

    final raw = await _txBuilder.buildSignAndEncodeRaw(
      signer: txSigner ?? signer,
      to: EthereumAddress(Uint8List(20)),
      value: EtherAmount.zero(),
      data: Uint8List(0),
      authorizationList: [auth],
    );

    final hash = await ctx.web3Client.makeRPCCall('eth_sendRawTransaction', [
      raw,
    ]);
    return hash;
  }

  static Future<Eip7702Client> create({
    required String rpcUrl,
    required EthereumAddress delegateAddress,
    Web3Client? customClient,
    GasTransformFn? transformer,
  }) async {
    final ctx =
        customClient != null
            ? Eip7702Context(
              delegateAddress: delegateAddress,
              web3Client: customClient,
              transformer: transformer,
            )
            : await Eip7702Context.forge(
              rpcUrl: rpcUrl,
              delegateAddress: delegateAddress,
              transformer: transformer,
            );
    final authBuilder = AuthorizationBuilder(ctx);
    final txBuilder = SetCodeTxBuilder(ctx);
    return Eip7702Client(ctx, authBuilder, txBuilder);
  }
}
