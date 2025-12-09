part of '../eip7702.dart';

typedef AuthorizationTuple =
    ({UnsignedAuthorization auth, EIP7702MsgSignature signature});

typedef UnsignedAuthorization =
    ({BigInt chainId, EthereumAddress delegateAddress, BigInt nonce});
