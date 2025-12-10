part of '../eip7702.dart';

typedef HexString = String;

/// Creates the canonical preimage for signing an [Unsigned7702Tx].
///
/// This method returns the serialized unsigned transaction bytes produced
/// by calling [Unsigned7702Tx.getUnsignedSerialized].
///
/// The optional `chainId` parameter overrides the chain ID used during
/// serialization.
///
/// Example:
/// ```dart
/// final preimage = createTxPreImage(unsignedTx);
/// final sig = signer.signAsync(hash);
/// ```
Uint8List createTxPreImage(Unsigned7702Tx tx, {int? chainId}) {
  final unsignedTx = tx.getUnsignedSerialized(chainId: chainId);
  return unsignedTx;
}

/// Signs an [Unsigned7702Tx] using the provided [Signer] and returns a
/// fully formed [Signed7702Tx].
///
/// This method:
///  1. Generates the transaction signing preimage via [createTxPreImage].
///  2. Asynchronously signs the preimage using [Signer.signAsync].
///  3. Wraps the unsigned transaction and resulting [EIP7702MsgSignature]
///     into a [Signed7702Tx] that can be passed into [parseRawTransaction]
///
/// The optional `chainId` argument overrides the chain ID used when
/// creating the preimage.
///
/// Example:
/// ```dart
/// final signed = await signTransaction(signer, unsignedTx);
/// final raw = parseRawTransaction(signed);
/// ```
Future<Signed7702Tx> signTransaction(
  Signer signer,
  Unsigned7702Tx tx, {
  int? chainId,
}) async {
  final preImage = createTxPreImage(tx, chainId: chainId);
  final signature = await signer.signAsync(preImage);
  return (signature: signature, tx: tx);
}

/// Converts a [Signed7702Tx] into its hex-encoded raw transaction form,
/// suitable for submission to Ethereum JSON-RPC endpoints such as
/// `eth_sendRawTransaction`.
///
/// This method:
///  1. Serializes the signed transaction using
///     [Signed7702TxExtension.getSignedSerialized].
///  2. Encodes the resulting bytes as a `0x`-prefixed hexadecimal string.
///
/// Example:
/// ```dart
/// final rawHex = parseRawTransaction(signedTx);
/// await client.sendRawTransaction(rawHex);
/// ```
HexString parseRawTransaction(Signed7702Tx tx, {int? chainId}) {
  final rawBytes = tx.getSignedSerialized(chainId: chainId);
  return bytesToHex(rawBytes, include0x: true, padToEvenLength: true);
}
