part of '../eip7702.dart';

typedef UnsignedAuthorization =
    ({BigInt chainId, EthereumAddress delegateAddress, BigInt nonce});

typedef AuthorizationTuple =
    ({UnsignedAuthorization auth, EIP7702MsgSignature signature});
