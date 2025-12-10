part of '../eip7702.dart';

class EIP7702MsgSignature extends MsgSignature {
  final int yParity;

  EIP7702MsgSignature(super.r, super.s, super.v, this.yParity);

  factory EIP7702MsgSignature.forge(BigInt r, BigInt s, int v) {
    v = v > 1 ? v : v + 27;
    return EIP7702MsgSignature(r, s, v, v - 27);
  }
}

@freezed
class Signer with _$Signer {
  const factory Signer.eth(EthPrivateKey ethPrivateKey) = EthSigner;
  const factory Signer.raw(Uint8List rawPrivateKey) = RawSigner;
}

extension SignerX on Signer {
  EthPrivateKey get ethPrivateKey =>
      when(raw: (value) => EthPrivateKey(value), eth: (value) => value);

  EIP7702MsgSignature sign(Uint8List preImage) {
    final signature = ethPrivateKey.signToEcSignature(
      preImage,
      isEIP1559: true,
    );
    return EIP7702MsgSignature.forge(signature.r, signature.s, signature.v);
  }

  Future<EIP7702MsgSignature> signAsync(Uint8List preImage) {
    return Future.value(sign(preImage));
  }
}
