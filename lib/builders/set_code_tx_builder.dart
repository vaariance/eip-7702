part of '../builder.dart';

/// Gas cost charged per authorization tuple in an EIP-7702 `setCode` transaction.
///
/// Each authorization adds a fixed 25,000 gas to the transaction’s intrinsic cost.
/// This value is defined by the EIP-7702 specification and is multiplied by the
/// number of entries in the `authorizationList` when computing the total gas limit.
final BigInt baseAuthCost = BigInt.from(25000);

/// A builder responsible for constructing type `0x04` EIP-7702
/// transactions that update an externally owned account’s code to the
/// designated delegation stub.
///
/// A [SetCodeTxBuilder] uses the shared context provided by
/// [Eip7702Base] and helper utilities from [Eip7702Common] to:
///
///  - estimate gas and fees for the `setCode` transaction,
///  - resolve the correct nonce for the sender,
///  - include the appropriate authorization tuple(s),
///  - build an [Unsigned7702Tx] representing the complete transaction,
///  - optionally sign and serialize the transaction for broadcast.
///
/// The resulting transaction is a typed transaction (`0x04`) as defined
/// by EIP-7702 and is typically submitted via `eth_sendRawTransaction`.
///
/// ### Example
/// ```dart
/// final builder = SetCodeTxBuilder(ctx);
/// final unsigned = await builder.buildUnsigned(eoa: signer.address);
/// final signed = await builder.buildAndSign(
///   signer: signer,
///   unsigned: unsigned,
/// );
/// final raw = parseRawTransaction(signed);
/// ```
///
/// This builder does not perform signing itself; instead, it delegates
/// signature creation to a [Signer] passed into higher-level methods.
class SetCodeTxBuilder extends Eip7702Base with Eip7702Common {
  final Eip7702Context _ctx;

  SetCodeTxBuilder(this._ctx);

  @override
  Eip7702Context get ctx => _ctx;

  /// Builds, signs, and encodes a complete EIP-7702 transaction into a
  /// raw hex string suitable for submission via `eth_sendRawTransaction`.
  ///
  /// This helper performs the full transaction pipeline:
  ///
  ///  1. Constructs an [Unsigned7702Tx] using [buildUnsigned].
  ///  2. Signs the transaction using [signUnsigned] and the provided [Signer].
  ///  3. Serializes the signed transaction via [parseRawTransaction].
  ///
  /// The resulting hex string contains the typed transaction prefix (`0x04`)
  /// followed by the RLP-encoded body and is ready for broadcast to any
  /// JSON-RPC node.
  ///
  /// Parameters:
  ///  - [signer] — the signer producing the ECDSA signature.
  ///  - [to] — the destination address of the transaction.
  ///  - [value] — optional ether value to transfer.
  ///  - [data] — optional calldata payload.
  ///  - [authorizationList] — one or more previously constructed
  ///    [AuthorizationTuple] values to include in the EIP-7702
  ///    `authorizationList` field.
  ///
  /// Example:
  /// ```dart
  /// final raw = await builder.buildSignAndEncodeRaw(
  ///   signer: signer,
  ///   to: recipient,
  ///   data: myCallData,
  /// );
  /// await client.sendRawTransaction(raw);
  /// ```
  Future<HexString> buildSignAndEncodeRaw({
    required Signer signer,
    required HexString to,
    BigInt? value,
    Uint8List? data,
    List<AuthorizationTuple> authorizationList = const [],
  }) async {
    final unsignedTx = await buildUnsigned(
      sender: signer.ethPrivateKey.address.eip55With0x,
      to: to,
      value: value,
      data: data,
      authorizationList: authorizationList,
    );

    final signedTx = await signUnsigned(signer: signer, unsignedTx: unsignedTx);
    final rawTx = parseRawTransaction(signedTx, chainId: ctx.chainId?.toInt());
    return rawTx;
  }

  /// Constructs an [Unsigned7702Tx] for a EIP-7702 transaction,
  /// resolving nonce, gas parameters, and optional call data before returning
  /// a fully prepared unsigned transaction object.
  ///
  /// This method delegates the core preparation work to [prepareUnsigned],
  /// which resolves:
  ///  - the sender’s nonce (unless [nonceOverride] is provided),
  ///  - gas fee parameters (EIP-1559),
  ///  - base transaction metadata such as [to], [value], and [data].
  ///
  /// After preparation, the provided [authorizationList] is attached to the
  /// transaction. These values typically come from an
  /// [AuthorizationBuilder] and represent the EIP-7702 authorization tuples
  /// required for this transaction.
  ///
  /// Parameters:
  ///  - [sender] — the EOA submitting the transaction.
  ///  - [to] — the execution target.
  ///  - [value] — optional ether value transferred with the call.
  ///  - [data] — optional calldata for contract execution.
  ///  - [authorizationList] — one or more [AuthorizationTuple] values
  ///    to embed in the transaction’s `authorizationList`.
  ///  - [nonceOverride] — explicitly sets the nonce, bypassing automatic
  ///    nonce lookup (primarily for testing).
  ///
  /// ### Example
  /// ```dart
  /// final unsigned = await builder.buildUnsigned(
  ///   sender: signer.ethPrivateKey.address,
  ///   to: target,
  ///   value: EtherAmount.zero(),
  ///   authorizationList: [authTuple],
  /// );
  /// ```
  Future<Unsigned7702Tx> buildUnsigned({
    required HexString sender,
    required HexString to,
    BigInt? value,
    Uint8List? data,
    List<AuthorizationTuple> authorizationList = const [],
    BigInt? nonceOverride,
  }) async {
    final prepareTxFn = await prepareUnsigned(sender, to, nonceOverride);
    final preparedTx = await prepareTxFn(value, data, authorizationList.length);
    preparedTx.authorizationList = authorizationList;
    return preparedTx;
  }

  /// Prepares the base components of an unsigned EIP-7702 transaction and
  /// returns a closure that finalizes the transaction once `value` and `data`
  /// are provided.
  ///
  /// This method performs the initial transaction setup:
  ///  - Resolves the sender’s nonce using [getNonce], unless [nonceOverride] is provided.
  ///  - Fetches EIP-1559 fee parameters using [getFeeData].
  ///  - Constructs a partially-built transaction template containing fixed
  ///    fields (`from`, `to`, `nonce`, `maxFeePerGas`,
  ///    `maxPriorityFeePerGas`).
  ///
  /// Instead of immediately returning an [Unsigned7702Tx], this method
  /// returns a **function** that completes the transaction when given:
  ///
  ///  - an optional [EtherAmount] `value`, and
  ///  - optional calldata `data`.
  ///
  /// ### Why return a closure?
  /// This design enables callers to resolve nonce and fee data *once*,
  /// while deferring gas estimation until [value] and [data] are known.
  /// Builders like [buildUnsigned] use this to assemble transactions in a
  /// staged, efficient manner.
  ///
  /// ### Example
  /// ```dart
  /// final prepare = await builder.prepareUnsigned(sender, to);
  /// final unsigned = await prepare(EtherAmount.zero(), callData);
  /// ```
  Future<Future<Unsigned7702Tx> Function(BigInt?, Uint8List?, int)>
  prepareUnsigned(
    HexString sender,
    HexString to, [
    BigInt? nonceOverride,
  ]) async {
    final [nonce, fees] = await Future.wait<dynamic>([
      resolveNonce(sender.ethAddress, null, nonceOverride),
      getFeeData(),
    ]);
    final maxFeePerGas = EtherAmount.inWei(fees.maxFeePerGas);
    final maxPriorityFeePerGas = EtherAmount.inWei(fees.maxPriorityFeePerGas);

    return (BigInt? value, Uint8List? data, int noOfAuths) async {
      final valueEtherAmount = EtherAmount.inWei(value ?? BigInt.zero);

      final gasLimit = await ctx.web3Client.estimateGas(
        sender: sender.ethAddress,
        to: to.ethAddress,
        data: data,
        value: valueEtherAmount,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
        maxFeePerGas: maxFeePerGas,
      );

      final baseCost = baseAuthCost * BigInt.from(noOfAuths);
      final totalGas = gasLimit + baseCost;

      return Unsigned7702Tx(
        from: sender.ethAddress,
        to: to.ethAddress,
        gasLimit: ctx.transformer?.call(totalGas) ?? totalGas,
        nonce: nonce.toInt(),
        value: valueEtherAmount,
        data: data ?? Uint8List(0),
        maxFeePerGas: maxFeePerGas,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
      );
    };
  }

  /// Signs an [Unsigned7702Tx] using the provided [Signer] and returns a
  /// fully formed [Signed7702Tx].
  ///
  /// The returned transaction is ready to be serialized using
  /// [parseRawTransaction] or passed to higher-level helpers.
  ///
  /// ### Example
  /// ```dart
  /// final signed = await builder.signUnsigned(
  ///   signer: signer,
  ///   unsignedTx: unsigned,
  /// );
  /// ```
  Future<Signed7702Tx> signUnsigned({
    required Signer signer,
    required Unsigned7702Tx unsignedTx,
  }) async {
    final resolvedChainId = await resolveChainId();
    final signedTx = await signTransaction(
      signer,
      unsignedTx,
      chainId: resolvedChainId.toInt(),
    );
    return signedTx;
  }
}
