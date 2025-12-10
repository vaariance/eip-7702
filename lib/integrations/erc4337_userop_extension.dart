part of '../eip7702.dart';

/// Inserts an EIP-7702 authorization tuple into a UserOperation map by
/// adding an `authorization` field containing the serialized form of the
/// provided [AuthorizationTuple].
///
/// This helper is used when adapting 7702 authorization semantics to
/// ERC-4337 UserOperations. The method mutates the provided `op` map and
/// returns the same instance for chaining.
///
/// The authorization is encoded using [AuthorizationTuple.toMap], which
/// produces a JSON-compatible structure appropriate for schema-agnostic
/// bundler implementations.
///
/// ### Example
/// ```dart
/// final updated = addEip7702AuthToOp(authTuple, userOp);
/// print(updated['authorization']);
/// ```
Map<String, dynamic> addEip7702AuthToOp(
  AuthorizationTuple auth,
  Map<String, dynamic> op,
) {
  return op..addAll({"authorization": auth.toMap()});
}

/// Normalizes a UserOperation map so it can safely incorporate an
/// EIP-7702 authorization tuple, returning the canonicalized operation.
///
/// This method performs three steps:
///
///  1. **Validation**
///     Ensures the authorization tuple’s recovered address matches the
///     UserOperation sender via [validateUserOp]. If the sender is absent,
///     it is injected based on the recovered authorization signer.
///
///  2. **Canonicalization of factory fields**
///     If the UserOperation contains a `factory` entry (i.e., a deploy-time
///     init flow), both `factory` and `factoryData` are removed.
///
///     Otherwise, the method forces `initCode` to an empty value (`"0x"`),
///     ensuring consistent schema behavior expected by ERC-4337 bundlers.
///
///  3. **Inserting authorization data**
///     Adds the serialized EIP-7702 authorization via
///     [addEip7702AuthToOp], producing a UserOperation enriched with the
///     `authorization` field.
///
/// This helper ensures that UserOperations remain structurally valid while
/// integrating EIP-7702 semantics.
///
/// ### Example
/// ```dart
/// final canon = canonicalizeUserOp(authTuple, userOp);
/// print(canon['authorization']);
/// ```
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

/// Validates that the provided [AuthorizationTuple] is compatible with the
/// given UserOperation by recovering the signer address and ensuring it
/// matches `op['sender']`.
///
/// This method performs the essential safety check required when merging
/// EIP-7702 authorization semantics into ERC-4337 UserOperations:
///
///  1. Reconstructs the authorization preimage using
///     [createAuthPreImage].
///  2. Computes the Keccak-256 digest of the preimage.
///  3. Recovers the public key via [ecRecover] from the authorization
///     signature.
///  4. Derives the EOA address and compares it to the UserOperation's
///     `sender` field.
///
/// Validation outcomes:
///
///  - If the UserOperation does **not** specify a sender, the recovered
///    address is inserted automatically into `op['sender']`.
///  - If the sender **is** present but does not match the authorization
///    signer, an [AssertionError] is thrown.
///
/// This ensures that:
///  - the authorization tuple was signed by the same EOA performing the
///    UserOperation, and
///  - no mismatched signatures or replayed authorizations can be
///    injected into the UserOperation.
///
/// ### Example
/// ```dart
/// validateUserOp(authorization, userOp);  // throws on mismatch
/// ```
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
