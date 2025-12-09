part of '../eip7702.dart';

typedef AccessListItem = ({Uint8List address, List<Uint8List> storageKeys});

typedef Signed7702Tx = ({Unsigned7702Tx tx, EIP7702MsgSignature signature});

class Unsigned7702Tx extends Transaction {
  List<AuthorizationTuple> authorizationList;
  List<AccessListItem> accessList; // UNIMPLEMENTED
  BigInt gasLimit;

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
    this.authorizationList = const [],
  });

  @override
  bool get isEIP1559 => true;

  @override
  int? get maxGas => gasLimit.toInt();

  TransactionType get transactionType =>
      authorizationList.isEmpty
          ? TransactionType.eip1559
          : TransactionType.eip7702;

  BigInt getChainId(int? custom) {
    if (custom == null && authorizationList.isEmpty) {
      throw Exception("ChainId is required if Authorization List is empty");
    }
    return custom != null
        ? BigInt.from(custom)
        : authorizationList.first.auth.chainId;
  }

  @override
  Uint8List getUnsignedSerialized({int? chainId}) {
    final encodedTx = LengthTrackingByteSink();
    encodedTx.addByte(transactionType.value);
    encodedTx.add(
      rlp.encode(encodeEIP1559ToRlp(this, null, getChainId(chainId))),
    );

    encodedTx.close();

    return encodedTx.asBytes();
  }
}

extension Signed7702TxExtension on Signed7702Tx {
  Uint8List getSignedSerialized({int? chainId}) {
    final encodedTx = LengthTrackingByteSink();
    encodedTx.addByte(tx.transactionType.value);
    encodedTx.add(
      rlp.encode(encodeEIP1559ToRlp(tx, signature, tx.getChainId(chainId))),
    );

    encodedTx.close();

    return encodedTx.asBytes();
  }
}

final tx = Unsigned7702Tx(
  to: EthereumAddress.fromHex(""),
  gasLimit: BigInt.one,
  nonce: 1,
  maxFeePerGas: EtherAmount.zero(),
  maxPriorityFeePerGas: EtherAmount.zero(),
  authorizationList: const [],
);
