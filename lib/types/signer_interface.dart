part of '../eip7702.dart';

class EIP7702MsgSignature extends MsgSignature {
  final int yParity;

  EIP7702MsgSignature(super.r, super.s, super.v, this.yParity);

  factory EIP7702MsgSignature.forge(BigInt r, BigInt s, int v) =>
      EIP7702MsgSignature(r, s, v, v > 1 ? v - 27 : v);
}

@freezed
class Signer with _$Signer {
  const factory Signer.raw(Uint8List rawPrivateKey) = RawSigner;
  const factory Signer.eth(EthPrivateKey ethPrivateKey) = EthSigner;
}

extension SignerX on Signer {
  EIP7702MsgSignature sign(Uint8List digest) {
    final EthPrivateKey key = when(
      raw: (value) => EthPrivateKey(value),
      eth: (value) => value,
    );

    final signature = key.signToEcSignature(digest, isEIP1559: true);
    return EIP7702MsgSignature.forge(signature.r, signature.s, signature.v);
  }
}
