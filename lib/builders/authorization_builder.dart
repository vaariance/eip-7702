part of '../builder.dart';

/// A high-level builder responsible for constructing EIP-7702
/// authorization messages for an externally owned account (EOA).
///
/// An [AuthorizationBuilder] uses the shared context provided by
/// [Eip7702Base] and utilities from [Eip7702Common] to:
///
///  - resolve the correct authorization `nonce` for the EOA,
///  - assemble an [UnsignedAuthorization] tuple,
///  - produce a signed [AuthorizationTuple] using a [Signer],
///  - optionally determine whether a new authorization is needed.
///
/// This builder is typically used prior to creating a type `0x04`
/// EIP-7702 transaction, where the resulting authorization tuple is
/// included in the transaction’s `authorizationList`.
///
/// ### Example usage
/// ```dart
/// final builder = AuthorizationBuilder(ctx);
/// final tuple = await builder.buildAndSignIfNeeded(signer, eoa);
/// ```
class AuthorizationBuilder extends Eip7702Base with Eip7702Common {
  final Eip7702Context _ctx;

  AuthorizationBuilder(this._ctx);

  @override
  Eip7702Context get ctx => _ctx;

  /// Builds an unsigned EIP-7702 authorization for the signer’s address
  /// and returns a fully signed [AuthorizationTuple].
  ///
  /// This method:
  ///  1. Constructs an [UnsignedAuthorization] using [buildUnsigned],
  ///     resolving the appropriate `nonce` unless `nonceOverride` is
  ///     provided.
  ///  2. Signs the resulting authorization preimage using the given
  ///     [Signer].
  ///  3. Wraps the fields and signature into a complete [AuthorizationTuple].
  ///
  /// The authorization produced here is typically inserted into the
  /// `authorizationList` of a type `0x04` EIP-7702 transaction.
  ///
  /// The optional `nonceOverride` parameter may be used during testing or
  /// custom workflows to supply a specific authorization nonce.
  ///
  /// Example:
  /// ```dart
  /// final tuple = await builder.buildAndSign(
  ///   signer: signer,
  /// );
  /// ```
  ///
  /// See also:
  ///  - [buildUnsigned] – constructs the unsigned authorization fields.
  Future<AuthorizationTuple> buildAndSign({
    required Signer signer,
    Executor? executor,
    BigInt? nonceOverride,
  }) async {
    final unsigned = await buildUnsigned(
      eoa: signer.ethPrivateKey.address,
      executor: executor,
      nonceOverride: nonceOverride,
    );
    return signAuthorization(signer, unsigned);
  }

  /// Builds and signs a new authorization tuple only if the EOA is not
  /// already delegated to the configured implementation.
  ///
  /// This method:
  ///  1. Checks the current delegation state using [isDelegatedTo].
  ///  2. If the EOA already delegates to [Eip7702Context.delegateAddress],
  ///     returns `null`.
  ///  3. Otherwise, invokes [buildAndSign] to produce a new
  ///     [AuthorizationTuple].
  ///
  /// This helper is typically used when preparing a type `0x04`
  /// EIP-7702 transaction to ensure that delegation is applied only when
  /// necessary.
  ///
  /// Example:
  /// ```dart
  /// final tuple = await builder.buildAndSignIfNeeded(signer: signer);
  /// if (tuple == null) {
  ///   print('Delegation already active; no authorization needed.');
  /// }
  /// ```
  ///
  /// See also:
  ///  - [buildAndSign]
  Future<AuthorizationTuple?> buildAndSignIfNeeded({
    required Signer signer,
    Executor? executor,
  }) async {
    final alreadyDelegating = await isDelegatedTo(
      signer.ethPrivateKey.address,
      ctx.delegateAddress,
    );
    if (alreadyDelegating) return null;
    return buildAndSign(signer: signer, executor: executor);
  }

  /// Constructs an [UnsignedAuthorization] record for the specified EOA,
  /// resolving the required chain ID, nonce, and delegate address.
  ///
  /// This method performs:
  ///  1. Network chain ID resolution via [resolveChainId].
  ///  2. Nonce resolution for the given `eoa` unless `nonceOverride` is
  ///     provided, using [getNonce].
  ///  3. Delegate resolution using the provided `delegateOverride` or the
  ///     default [Eip7702Context.delegateAddress].
  ///
  /// The resulting unsigned authorization record may be signed using
  /// [signAuthorization] or passed to higher-level builders such as
  /// [buildAndSign] or [buildAndSignIfNeeded].
  ///
  /// ### Example
  /// ```dart
  /// final unsigned = await builder.buildUnsigned(
  ///   eoa: myAddress,
  /// );
  /// print(unsigned.chainId);
  /// ```
  ///
  /// Parameters:
  ///  - `eoa` — the externally owned account performing the authorization.
  ///  - `delegateOverride` — optional implementation address to override
  ///    the default delegation target.
  ///  - `nonceOverride` — optional nonce to bypass automatic nonce
  ///    discovery (useful for testing).
  ///
  /// See also:
  ///  - [UnsignedAuthorization]
  ///  - [buildAndSign]
  ///  - [buildAndSignIfNeeded]
  Future<UnsignedAuthorization> buildUnsigned({
    required EthereumAddress eoa,
    Executor? executor,
    HexString? delegateOverride,
    BigInt? nonceOverride,
  }) async {
    final resolvedChainId = await resolveChainId();
    final resolvedNonce = await resolveNonce(eoa, executor, nonceOverride);
    final delegateAddress = delegateOverride ?? ctx.delegateAddress.with0x;
    return (
      chainId: resolvedChainId,
      delegateAddress: delegateAddress,
      nonce: resolvedNonce,
    );
  }
}
