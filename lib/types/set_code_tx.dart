part of '../eip7702.dart';

typedef AccessListItem = ({Uint8List address, List<Uint8List> storageKeys});

class Unsigned7702Tx extends Transaction {
  List<AuthorizationTuple> authorizationList;
  List<AccessListItem> accessList; // UNIMPLEMENTED
  BigInt gasLimit;

  @override
  int? get maxGas => gasLimit.toInt();

  @override
  bool get isEIP1559 => true;

  Unsigned7702Tx({
    super.from,
    required super.to,
    required this.gasLimit,
    super.value,
    super.data,
    required super.nonce,
    required super.maxFeePerGas,
    required super.maxPriorityFeePerGas,
    this.accessList = const [],
    required this.authorizationList,
  });

  @override
  Uint8List getUnsignedSerialized({int? chainId}) {
    final encodedTx = LengthTrackingByteSink();
    encodedTx.addByte(0x04);
    encodedTx.add(
      rlp.encode(encodeEIP1559ToRlp(this, null, getChainId(chainId))),
    );

    encodedTx.close();

    return encodedTx.asBytes();
  }

  BigInt getChainId(int? custom) {
    return custom != null
        ? BigInt.from(custom)
        : authorizationList.first.auth.chainId;
  }
}

typedef Signed7702Tx = ({Unsigned7702Tx tx, EIP7702MsgSignature signature});

extension Signed7702TxExtension on Signed7702Tx {
  Uint8List getSignedSerialized({int? chainId}) {
    final encodedTx = LengthTrackingByteSink();
    encodedTx.addByte(0x04);
    encodedTx.add(
      rlp.encode(encodeEIP1559ToRlp(tx, signature, tx.getChainId(chainId))),
    );

    encodedTx.close();

    return encodedTx.asBytes();
  }
}
