part of '../eip7702.dart';

/// {@template Eip7702ClientBase}
/// Defines the high-level client interface for performing EIP-7702
/// delegation operations, including setting a delegation and revoking it.
///
/// Concrete implementations of this interface coordinate:
///  - authorization construction (via [AuthorizationTuple]),
///  - building typed EIP-7702 transactions (via [Unsigned7702Tx]),
///  - signing using a [Signer] or optional transaction signer,
///  - serializing the resulting transaction into a raw hex string
///    suitable for `eth_sendRawTransaction`.
/// {@endtemplate}
///
/// This abstraction allows applications to interact with EIP-7702
/// functionality through a simple, opinionated API without needing to
/// manually manage builders, authorization flows, or transaction encoding.
abstract class Eip7702ClientBase {
  /// Performs an EIP-7702 delegation (if required) and issues an optional
  /// contract call in a single transaction.
  ///
  /// This method orchestrates the full pipeline:
  ///
  ///  1. Builds and signs an authorization using
  ///     [AuthorizationBuilder].
  ///     - If the EOA is already delegated to
  ///     [Eip7702Context.delegateAddress], no authorization tuple is
  ///     produced.*
  ///
  ///  2. Constructs and signs the EIP-7702 transaction using
  ///     [SetCodeTxBuilder].
  ///     This embeds the authorization tuple (when present), the call
  ///     target `to`, optional `data`, and optional `value`.
  ///
  ///  3. Broadcasts the transaction by invoking
  ///     `eth_sendRawTransaction` via [Web3Client.makeRPCCall].
  ///
  /// The returned value is the transaction hash as a hex string.
  ///
  /// Parameters:
  ///  - [signer] — used to sign the authorization tuple.
  ///  - [to] — the address the transaction should call or transfer value to.
  ///  - [data] — optional calldata for the execution.
  ///  - [value] — optional ether value for the call.
  ///  - [txSigner] — optional override for signing the *transaction*.
  ///    Defaults to `signer`.
  ///
  /// ### Example
  /// ```dart
  /// final hash = await client.delegateAndCall(
  ///   signer: mySigner,
  ///   to: contract,
  ///   data: encodedCall,
  /// );
  /// print('Broadcast tx: $hash');
  /// ```
  Future<HexString> delegateAndCall({
    required Signer signer,
    required HexString to,
    Uint8List? data,
    BigInt? value,
    Signer? txSigner,
  });

  /// Revokes an active EIP-7702 delegation by constructing and submitting a
  /// transaction that sets the EOA’s code to the zero-address delegation stub.
  ///
  /// This method performs the full revocation workflow:
  ///
  ///  1. Confirms that the EOA is currently delegated to
  ///     [Eip7702Context.delegateAddress] using
  ///     [AuthorizationBuilder].
  ///     If not delegated, an assertion is thrown.
  ///
  ///  2. Builds an [UnsignedAuthorization] with a `delegateAddress` of
  ///     `EthereumAddress(Uint8List(20))`—the canonical “zero
  ///     implementation” address used for revocation.
  ///
  ///  3. Signs the authorization tuple via [signAuthorization].
  ///
  ///  4. Constructs and signs a type `0x04` EIP-7702 transaction using
  ///     [SetCodeTxBuilder], embedding the revocation
  ///     authorization.
  ///
  ///  5. Broadcasts the transaction using `eth_sendRawTransaction` via
  ///     [Web3Client.makeRPCCall].
  ///
  /// Upon success, the method returns the transaction hash as a hex string.
  ///
  /// Parameters:
  ///  - [signer] — used to sign the revocation authorization.
  ///  - [txSigner] — optional override for signing the transaction itself.
  ///    Defaults to `signer`.
  ///
  /// ### Example
  /// ```dart
  /// final hash = await client.revokeDelegation(
  ///   signer: mySigner,
  /// );
  /// print('Revocation tx: $hash');
  /// ```
  Future<HexString> revokeDelegation({
    required Signer signer,
    Signer? txSigner,
  });

  /// Executes a contract call from an already-delegated EOA without creating
  /// a new authorization tuple.
  ///
  /// This method is used when the EOA has already been delegated to
  /// [Eip7702Context.delegateAddress] in a previous transaction, and you
  /// simply want to execute a call or transfer value using the delegated
  /// implementation.
  ///
  /// Unlike [delegateAndCall], this method:
  ///  - Does NOT build or sign an authorization tuple
  ///  - Does NOT check current delegation status
  ///  - Assumes the EOA is already properly delegated
  ///
  /// The workflow:
  ///  1. Constructs an EIP-7702 transaction using [SetCodeTxBuilder] with an
  ///     empty authorization list.
  ///  2. Signs the transaction with [txSigner].
  ///  3. Broadcasts the transaction via `eth_sendRawTransaction`.
  ///
  /// Returns the transaction hash as a hex string.
  ///
  /// Parameters:
  ///  - [txSigner] — signer used to sign the transaction.
  ///  - [to] — the address the transaction should call or transfer value to.
  ///  - [data] — optional calldata for the execution.
  ///  - [value] — optional ether value for the call.
  ///
  /// ### Example
  /// ```dart
  /// // First delegate (in a previous transaction)
  /// await client.delegateAndCall(signer: mySigner, to: contract);
  ///
  /// // Later, execute calls using the delegation
  /// final hash = await client.call(
  ///   txSigner: mySigner,
  ///   to: contract,
  ///   data: encodedCall,
  /// );
  /// print('Call tx: $hash');
  /// ```
  Future<HexString> call({
    required Signer txSigner,
    required HexString to,
    Uint8List? data,
    BigInt? value,
  });
}
