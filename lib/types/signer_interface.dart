part of '../eip7702.dart';

class EIP7702MsgSignature extends MsgSignature {
  final int yParity;

  EIP7702MsgSignature(super.r, super.s, super.v, this.yParity);

  factory EIP7702MsgSignature.forge(BigInt r, BigInt s, int v) =>
      EIP7702MsgSignature(r, s, v, v > 1 ? v - 27 : v);
}

@freezed
class Signer with _$Signer {
  const factory Signer.eth(EthPrivateKey ethPrivateKey) = EthSigner;
  const factory Signer.raw(Uint8List rawPrivateKey) = RawSigner;
}

extension SignerX on Signer {
  EthPrivateKey get ethPrivateKey =>
      when(raw: (value) => EthPrivateKey(value), eth: (value) => value);

  EIP7702MsgSignature sign(Uint8List digest) {
    final signature = ethPrivateKey.signToEcSignature(digest, isEIP1559: true);
    return EIP7702MsgSignature.forge(signature.r, signature.s, signature.v);
  }
}
