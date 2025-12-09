part of '../eip7702.dart';

/// 0x05 prefix for EIP-7702 authorization messages
const int _kEip7702AuthPrefix = 0x05;

/// Build the preimage for an authorization tuple:
/// ( 0x05 || rlp([chainId, address, nonce]) )
Uint8List createAuthPreImage(UnsignedAuthorization auth) {
  final encodedAuth = LengthTrackingByteSink();
  encodedAuth.addByte(_kEip7702AuthPrefix);
  encodedAuth.add(rlp.encode([auth.chainId, auth.delegateAddress, auth.nonce]));
  encodedAuth.close();
  return encodedAuth.asBytes();
}

/// Sign an authorization tuple with a Signer and return a full AuthorizationTuple
/// keccak256(preimage) -> sign
AuthorizationTuple signAuthorization(
  Signer signer,
  UnsignedAuthorization auth,
) {
  final preImage = createAuthPreImage(auth);
  final sig = signer.sign(preImage);
  return (auth: auth, signature: sig);
}
