part of '../eip7702.dart';

// CREDIT: web3dart
// These are private functions which requires tweaking and reimplementaion.

/// Encodes an [AuthorizationTuple] into the list form expected by
/// RLP serialization for EIP-7702.
///
/// The returned list represents the canonical RLP structure:
///
/// ```text
/// [ chainId, delegateAddress, nonce, yParity, r, s ]
/// ```
///
/// This list is typically passed directly to an RLP encoder (such as
/// `rlp.encode(...)`) when constructing the `authorizationList` field of
/// an EIP-7702 typed transaction (`TransactionType.eip7702`).
///
/// This function performs no validation; callers should ensure that
/// `auth` contains a valid signature and well-formed authorization data.
///
/// See also:
///  - [AuthorizationTuple] – contains the unsigned authorization data
///    and its corresponding ECDSA signature.
///  - EIP-7702 specification: https://eips.ethereum.org/EIPS/eip-7702
List<dynamic> encodeAuthorizationTupleToRlp(AuthorizationTuple auth) {
  final list = [
    auth.auth.chainId,
    auth.auth.delegateAddress.ethAddress.value,
    auth.auth.nonce,
    auth.signature.yParity,
    auth.signature.r,
    auth.signature.s,
  ];
  return list;
}

/// Encodes a list of [AuthorizationTuple] objects into the RLP-ready
/// list-of-lists structure required by EIP-7702.
///
/// Each tuple is individually transformed using
/// [encodeAuthorizationTupleToRlp], and the resulting list-of-lists
/// can be passed directly to an RLP encoder when constructing the
/// [authorizationList] field of a type `0x04` transaction.
///
/// Example:
/// ```dart
/// final encoded = encodeAuthorizationListToRlp(authList);
/// final rlpBytes = rlp.encode(encoded);
/// ```
List<List<dynamic>> encodeAuthorizationListToRlp(
  List<AuthorizationTuple> authorizationList,
) {
  return authorizationList.map(encodeAuthorizationTupleToRlp).toList();
}

/// Constructs the RLP-serializable list representation of an EIP-1559 or
/// EIP-7702 transaction.
///
/// This function produces the canonical typed-transaction payload **without**
/// the leading type byte (`0x02` or `0x04`). The resulting list is intended
/// to be passed directly to an RLP encoder (e.g. `rlp.encode(...)`) and then
/// prefixed with the appropriate transaction type by the caller.
///
/// The structure follows the specification for EIP-1559, with optional
/// extensions for EIP-7702 when `signature` and the transaction’s
/// `authorizationList` are present.
///
/// The encoding layout is:
///
/// ```text
/// [
///   chainId,
///   nonce,
///   maxPriorityFeePerGas,
///   maxFeePerGas,
///   gasLimit,
///   to,
///   value,
///   data,
///   accessList,
///   (authorizationList?)   // only for EIP-7702 transactions
///   (yParity?, r?, s?)     // only when a signature is provided
/// ]
/// ```
///
///    creation semantics).
///  - For [TransactionType.eip7702], this includes the encoded authorization
///    list via [encodeAuthorizationListToRlp] before appending any signature.
///  - The caller is responsible for prefixing the appropriate type byte:
///    `0x02` for EIP-1559 and `0x04` for EIP-7702.
///
/// Example:
/// ```dart
/// final body = encodeEIP1559ToRlp(tx, signature, chainId);
/// final raw = BytesBuilder()
///   ..addByte(TransactionType.eip7702.value)
///   ..add(rlp.encode(body));
/// final serialized = raw.toBytes();
/// ```
///
/// See also:
///  - EIP-1559: https://eips.ethereum.org/EIPS/eip-1559
List<dynamic> encodeEIP1559ToRlp(
  Unsigned7702Tx transaction,
  EIP7702MsgSignature? signature,
  BigInt chainId,
) {
  final list = [
    chainId,
    transaction.nonce,
    transaction.maxPriorityFeePerGas!.getInWei,
    transaction.maxFeePerGas!.getInWei,
    transaction.gasLimit,
  ];

  if (transaction.to != null) {
    list.add(transaction.to!.value);
  } else {
    list.add('');
  }

  list
    ..add(transaction.value?.getInWei)
    ..add(transaction.data);

  list.add(transaction.accessList);

  if (transaction.transactionType == TransactionType.eip7702) {
    list.add(encodeAuthorizationListToRlp(transaction.authorizationList));
  }

  if (signature != null) {
    list
      ..add(signature.yParity)
      ..add(signature.r)
      ..add(signature.s);
  }

  return list;
}
