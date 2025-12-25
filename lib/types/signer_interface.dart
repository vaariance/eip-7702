part of '../eip7702.dart';

/// Represents an ECDSA signature used in EIP-7702 authorization messages.
///
/// EIP-7702 requires signatures to include a **y-parity bit** (`0` or `1`)
///
///  - [yParity] — the parity bit used in EIP-7702 authorization tuples.
///  - [r] and [s]   — standard ECDSA components.
///  - [v]           — normalized to `27` or `28` for compatibility with `ecRecover`.
///
/// Internally, the [v]value is normalized so that:
///
/// ```text
///   yParity = v - 27
///   normalizedV = 27 + yParity
/// ```
///
/// This allows using [yParity] when encoding authorization tuples and
/// still passing the signature as a regular [MsgSignature] to [ecRecover]
class EIP7702MsgSignature extends MsgSignature {
  final int yParity;

  EIP7702MsgSignature(super.r, super.s, super.v, this.yParity);

  factory EIP7702MsgSignature.forge(BigInt r, BigInt s, int v) {
    int yParity = (v == 0 || v == 1) ? v : (v - 27);

    if (yParity != 0 && yParity != 1) {
      throw ArgumentError.value(v, 'v', 'Must be 0/1 or 27/28');
    }
    final vNorm = 27 + yParity;
    return EIP7702MsgSignature(r, s, vNorm, yParity);
  }

  factory EIP7702MsgSignature.fromUint8List(Uint8List data) {
    if (data.length != 65) {
      throw ArgumentError.value(data, 'data', 'Must be 65 bytes long');
    }
    return EIP7702MsgSignature.forge(
      bytesToUnsignedInt(data.sublist(0, 32)),
      bytesToUnsignedInt(data.sublist(32, 64)),
      data[64],
    );
  }
}

/// Represents a signing source used to produce ECDSA signatures for
/// EIP-7702 authorization messages and typed transactions.
///
/// Two variants are supported:
///
///  - [Signer.eth] – wraps an [EthPrivateKey] from the `web3dart`
///    package.
///  - [Signer.raw] – wraps a 32-byte `Uint8List` raw private key.
///
/// Both variants are treated equivalently by signing utilities; callers do
/// not need to differentiate between them.
///
/// Example:
/// ```dart
/// final signer = Signer.raw(myPrivateKeyBytes);
/// final signature = signer.signDigest(messageHash);
/// ```
///
/// See also:
///  - [EthPrivateKey] – the key type used by `web3dart`.
@freezed
class Signer with _$Signer {
  const factory Signer.eth(EthPrivateKey ethPrivateKey) = EthSigner;
  const factory Signer.raw(Uint8List rawPrivateKey) = RawSigner;
}

/// A custom signer that implements the [Signer] interface.
///
/// This abstract class allows external implementations to plug in their own
/// signing logic while still exposing the required [EthPrivateKey] getter.
///
/// Implementations must create a getter override: `ethPrivateKey`
abstract class CustomSigner implements Signer {
  /// {@macro sign}
  EIP7702MsgSignature sign(Uint8List preImage);

  /// {@macro signAsync}
  Future<EIP7702MsgSignature> signAsync(Uint8List preImage);
}

/// Extension providing convenient access to the underlying [EthPrivateKey]
/// for any [Signer] instance, regardless of its concrete type ([EthSigner]
/// or [RawSigner]).
extension SignerX on Signer {
  /// Returns the [EthPrivateKey] associated with this signer.
  ///
  /// For [Signer.eth], it simply unwraps the stored key; for [Signer.raw],
  /// it constructs a new [EthPrivateKey] from the raw 32-byte private key.
  EthPrivateKey get ethPrivateKey =>
      when(raw: (value) => EthPrivateKey(value), eth: (value) => value);

  /// {@template sign}
  /// Signs the given preimage using this signer’s underlying private key
  /// and returns an [EIP7702MsgSignature].
  ///
  /// The input [preImage] must be the canonical transaction or authorization
  /// preimage, such as that produced by [createTxPreImage] or
  /// [createAuthPreImage].
  ///
  /// This is a synchronous operation and should be used when blocking
  /// execution is acceptable.
  /// {@endtemplate}
  EIP7702MsgSignature sign(Uint8List preImage) {
    final signature = ethPrivateKey.signToEcSignature(
      preImage,
      isEIP1559: true,
    );
    return EIP7702MsgSignature.forge(signature.r, signature.s, signature.v);
  }

  /// {@template signAsync}
  /// Asynchronously signs the given preimage using this signer’s underlying
  /// private key.
  ///
  /// This method simply wraps [sign] in a `Future`, allowing use in async
  /// workflows such as transaction builders, RPC pipelines, or background
  /// execution contexts.
  ///
  /// Example:
  /// ```dart
  /// final sig = await signer.signAsync(preImage);
  /// ```
  /// {@endtemplate}
  Future<EIP7702MsgSignature> signAsync(Uint8List preImage) {
    return Future.value(sign(preImage));
  }
}
