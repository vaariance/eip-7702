part of '../builder.dart';

class SetCodeTxBuilder extends Eip7702Base with Eip7702Common {
  final Eip7702Context _ctx;

  SetCodeTxBuilder(this._ctx);

  @override
  Eip7702Context get ctx => _ctx;

  Future<HexString> buildSignAndEncodeRaw({
    required Signer signer,
    required EthereumAddress to,
    EtherAmount? value,
    Uint8List? data,
    List<AuthorizationTuple> authorizationList = const [],
  }) async {
    final unsignedTx = await buildUnsignedTx(
      sender: signer.ethPrivateKey.address,
      to: to,
      value: value,
      data: data,
      authorizationList: authorizationList,
    );

    final signedTx = await signUnsignedTx(
      signer: signer,
      unsignedTx: unsignedTx,
    );

    final rawTx = parseRawTransaction(signedTx, chainId: ctx.chainId?.toInt());
    return rawTx;
  }

  Future<Unsigned7702Tx> buildUnsignedTx({
    required EthereumAddress sender,
    required EthereumAddress to,
    EtherAmount? value,
    Uint8List? data,
    List<AuthorizationTuple> authorizationList = const [],
    BigInt? nonceOverride,
  }) async {
    final prepareTxFn = await prepareUnsigned(sender, to, nonceOverride);
    final preparedTx = await prepareTxFn(value, data);
    preparedTx.authorizationList = authorizationList;
    return preparedTx;
  }

  Future<Future<Unsigned7702Tx> Function(EtherAmount?, Uint8List?)>
  prepareUnsigned(
    EthereumAddress sender,
    EthereumAddress to,
    BigInt? nonceOverride,
  ) async {
    final [nonce, fees] = await Future.wait<dynamic>([
      nonceOverride != null ? Future.value(nonceOverride) : getNonce(sender),
      getFeeData(),
    ]);
    final maxFeePerGas = EtherAmount.inWei(fees.maxFeePerGas);
    final maxPriorityFeePerGas = EtherAmount.inWei(fees.maxPriorityFeePerGas);

    return (EtherAmount? value, Uint8List? data) async {
      final gasLimit = await ctx.web3Client.estimateGas(
        sender: sender,
        to: to,
        data: data,
        value: value,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
        maxFeePerGas: maxFeePerGas,
      );

      return Unsigned7702Tx(
        from: sender,
        to: to,
        gasLimit: gasLimit,
        nonce: nonce.toInt(),
        value: value ?? EtherAmount.zero(),
        data: data ?? Uint8List(0),
        maxFeePerGas: maxFeePerGas,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
      );
    };
  }

  Future<Signed7702Tx> signUnsignedTx({
    required Signer signer,
    required Unsigned7702Tx unsignedTx,
  }) async {
    final resolvedChainId = await resolveChainId();
    final signedTx = signTransaction(
      signer,
      unsignedTx,
      chainId: resolvedChainId.toInt(),
    );
    return signedTx;
  }

  Future<HexString> sendSignedTransactionRaw({required HexString signedTxRaw}) {
    return ctx.web3Client.makeRPCCall('eth_sendRawTransaction', [signedTxRaw]);
  }
}
