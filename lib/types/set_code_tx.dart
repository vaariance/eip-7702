part of '../eip7702.dart';

typedef AccessListItem = ({Uint8List address, List<Uint8List> storageKeys});

/// Represents a fully signed EIP-7702 transaction, pairing the unsigned
/// transaction body with the final [EIP7702MsgSignature].
///
/// This record contains:
///  - [tx] — the underlying [Unsigned7702Tx] instance.
///  - [signature] — the normalized ECDSA signature used for typed transaction serialization.
///
/// Example:
/// ```dart
/// final unsigned = Unsigned7702Tx(...);
/// final sig = signer.signDigest(unsigned.getUnsignedSerialized());
/// final signed = (tx: unsigned, signature: sig);
/// final raw = signed.getSignedSerialized();
/// ```
typedef Signed7702Tx = ({Unsigned7702Tx tx, EIP7702MsgSignature signature});

/// Represents the unsigned portion of an EIP-7702 typed transaction
/// (`0x04`), extending the base [Transaction] model.
///
/// An [Unsigned7702Tx] contains all transaction fields except the final
/// [EIP7702MsgSignature]. It includes:
///
///  - EIP-1559 fee parameters (`nonce`, `maxPriorityFeePerGas`,
///    `maxFeePerGas`, etc.)
///  - Delegation-specific data via [authorizationList]
///  - Optional EIP-2930 [accessList]
///
/// The resulting instance is typically passed to a RLP encoder via
/// [encodeEIP1559ToRlp] and later bundled into a [Signed7702Tx].
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
  /// Serializes this signed EIP-7702 transaction into the raw byte form
  /// expected by Ethereum JSON-RPC endpoints (e.g. `eth_sendRawTransaction`).
  ///
  /// The returned bytes include:
  ///
  /// ```text
  /// <transactionType> || rlp( <signedTransactionFields> )
  /// ```
  ///
  /// Where:
  ///  - `<transactionType>` is the type byte from
  ///    [TransactionType.eip7702] (`0x04`) or other supported types.
  ///  - The RLP body is constructed using
  ///    [encodeEIP1559ToRlp] with the attached signature.
  ///
  /// Example:
  /// ```dart
  /// final signed = (tx: unsignedTx, signature: sig);
  /// final raw = signed.getSignedSerialized();
  /// ```
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
