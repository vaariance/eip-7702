part of '../eip7702.dart';

typedef AuthorizationTuple =
    ({UnsignedAuthorization auth, EIP7702MsgSignature signature});

typedef UnsignedAuthorization =
    ({BigInt chainId, EthereumAddress delegateAddress, BigInt nonce});

extension AuthorizationTupleX on AuthorizationTuple {
  Map<String, dynamic> toMap() => {
    "address": auth.delegateAddress.with0x,
    "chainId": "0x${auth.chainId.toRadixString(16)}",
    "nonce": "0x${auth.nonce.toRadixString(16)}",
    "r": "0x${signature.r.toRadixString(16)}",
    "s": "0x${signature.s.toRadixString(16)}",
    "yParity": signature.yParity,
  };
}
