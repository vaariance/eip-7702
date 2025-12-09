part of '../eip7702.dart';

List<dynamic> encodeAuthorizationTupleToRlp(AuthorizationTuple auth) {
  final list = [
    auth.auth.chainId,
    auth.auth.delegateAddress,
    auth.auth.nonce,
    auth.signature.yParity,
    auth.signature.r,
    auth.signature.s,
  ];
  return list;
}

List<dynamic> encodeAuthorizationListToRlp(
  List<AuthorizationTuple> authorizationList,
) {
  return authorizationList.map(encodeAuthorizationTupleToRlp).toList();
}

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
