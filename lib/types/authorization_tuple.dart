part of '../eip7702.dart';

/// Represents a complete EIP-7702 authorization, consisting of the
/// unsigned authorization fields and the corresponding [EIP7702MsgSignature].
///
/// This tuple is included inside the `authorizationList` of a type
/// `0x04` EIP-7702 transaction. The signature is generated over the
/// authorization preimage constructed as:
///
/// ```text
/// keccak256( 0x05 || rlp([ chainId, delegateAddress, nonce ]) )
/// ```
///
/// Fields:
///  - `auth` – the unsigned data being authorized.
///  - `signature` – the normalized ECDSA signature.
///
/// See also:
///  - https://eips.ethereum.org/EIPS/eip-7702
typedef AuthorizationTuple =
    ({UnsignedAuthorization auth, EIP7702MsgSignature signature});

/// Represents the unsigned portion of an EIP-7702 authorization message.
///
/// ```text
/// [ chainId, delegateAddress, nonce ]
/// ```
///
/// They define which externally-owned account (EOA) is granting delegation,
/// which implementation it delegates to, and the monotonic nonce used to
/// prevent replay.
///
/// Record fields:
///  - `chainId` – the chain ID on which the authorization is valid.
///  - `delegateAddress` – the smart-contract implementation address
///    the EOA is delegating to.
///  - `nonce` – a replay-protection nonce for the EOA.
///
/// See also:
///  - https://eips.ethereum.org/EIPS/eip-7702
typedef UnsignedAuthorization =
    ({BigInt chainId, HexString delegateAddress, BigInt nonce});

extension AuthorizationTupleX on AuthorizationTuple {
  Map<String, dynamic> toMap() => {
    "address": auth.delegateAddress,
    "chainId": "0x${auth.chainId.toRadixString(16)}",
    "nonce": "0x${auth.nonce.toRadixString(16)}",
    "r": "0x${signature.r.toRadixString(16)}",
    "s": "0x${signature.s.toRadixString(16)}",
    "yParity": signature.yParity,
  };
}
