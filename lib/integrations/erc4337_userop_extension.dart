part of '../eip7702.dart';

Map<String, dynamic> addEip7702AuthToOp(
  AuthorizationTuple auth,
  Map<String, dynamic> op,
) {
  return op..addAll({"authorization": auth.toMap()});
}

Map<String, dynamic> canonicalizeUserOp(
  AuthorizationTuple auth,
  Map<String, dynamic> op,
) {
  validateUserOp(auth, op);
  if (op.containsKey('factory')) {
    op.remove("factory");
    op.remove("factoryData");
  } else {
    op["initCode"] = "0x";
  }
  return addEip7702AuthToOp(auth, op);
}

void validateUserOp(AuthorizationTuple auth, Map<String, dynamic> op) {
  final preImage = createAuthPreImage(auth.auth);
  final digest = keccak256(preImage);
  final recoveredPublicKey = ecRecover(digest, auth.signature);
  final recoveredAddress = EthereumAddress(
    publicKeyToAddress(recoveredPublicKey),
  );
  final recoveredHex = recoveredAddress.eip55With0x;

  if (op["sender"] == null) {
    op["sender"] = recoveredHex;
    return;
  }

  if (recoveredHex.toLowerCase() != op["sender"].toLowerCase()) {
    throw AssertionError("Authorization signer must match op['sender']");
  }
}
