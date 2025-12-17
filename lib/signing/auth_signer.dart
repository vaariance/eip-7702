part of '../eip7702.dart';

/// 0x05 prefix for EIP-7702 authorization messages
const int _kEip7702AuthPrefix = 0x05;

/// Constructs the canonical preimage used for signing an EIP-7702
/// authorization message.
///
/// The returned bytes follow the exact format defined in the
/// specification:
///
/// ```text
/// 0x05 || rlp([ chainId, delegateAddress, nonce ])
/// ```
///
/// This function performs no hashing or signing; it only creates the
/// preimage. Callers are responsible for applying the final digest step.
Uint8List createAuthPreImage(UnsignedAuthorization auth) {
  final encodedAuth = LengthTrackingByteSink();
  encodedAuth.addByte(_kEip7702AuthPrefix);
  encodedAuth.add(
    rlp.encode([
      auth.chainId,
      auth.delegateAddress.ethAddress.value,
      auth.nonce,
    ]),
  );
  encodedAuth.close();
  return encodedAuth.asBytes();
}

/// Signs an [UnsignedAuthorization] using the provided [Signer] and
/// returns a complete [AuthorizationTuple].
///
/// This method:
///  1. Builds the canonical authorization preimage via
///     [createAuthPreImage].
///  2. Signs the preimage using the given `signer`.
///  3. Wraps the original authorization fields and the resulting
///     [EIP7702MsgSignature] into an [AuthorizationTuple].
///
/// Example:
/// ```dart
/// final unsigned = (
///   chainId: BigInt.from(1),
///   delegateAddress: myImplAddress,
///   nonce: BigInt.one,
/// );
///
/// final tuple = signAuthorization(signer, unsigned);
/// ```
AuthorizationTuple signAuthorization(
  Signer signer,
  UnsignedAuthorization auth,
) {
  final preImage = createAuthPreImage(auth);
  final sig = signer.sign(preImage);
  return (auth: auth, signature: sig);
}
