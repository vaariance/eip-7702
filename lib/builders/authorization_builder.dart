part of 'builder.dart';

class AuthorizationBuilder extends Eip7702Base with Eip7702Common {
  final Eip7702Context _ctx;

  @override
  Eip7702Context get ctx => _ctx;

  AuthorizationBuilder(this._ctx);

  Future<UnsignedAuthorization> buildUnsigned({
    required EthereumAddress eoa,
    BigInt? nonceOverride,
  }) async {
    final resolvedChainId = await resolveChainId();
    final nonce = nonceOverride ?? await getNonce(eoa);
    return (
      chainId: resolvedChainId,
      delegateAddress: ctx.delegateAddress,
      nonce: nonce,
    );
  }

  Future<AuthorizationTuple> buildAndSign({
    required Signer signer,
    BigInt? nonceOverride,
  }) async {
    final unsigned = await buildUnsigned(
      eoa: signer.ethPrivateKey.address,
      nonceOverride: nonceOverride,
    );
    return signAuthorization(signer, unsigned);
  }

  Future<AuthorizationTuple?> buildAndSignIfNeeded({
    required Signer signer,
  }) async {
    final alreadyDelegating = await isDelegatedTo(
      signer.ethPrivateKey.address,
      ctx.delegateAddress,
    );
    if (alreadyDelegating) return null;
    return buildAndSign(signer: signer);
  }
}
