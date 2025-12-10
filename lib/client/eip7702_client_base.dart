part of '../eip7702.dart';

/// Defines the high-level client interface for performing EIP-7702
/// delegation operations, including setting a delegation and revoking it.
///
/// Concrete implementations of this interface coordinate:
///  - authorization construction (via [AuthorizationTuple]),
///  - building typed EIP-7702 transactions (via [Unsigned7702Tx]),
///  - signing using a [Signer] or optional transaction signer,
///  - serializing the resulting transaction into a raw hex string
///    suitable for `eth_sendRawTransaction`.
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
    required EthereumAddress to,
    Uint8List? data,
    EtherAmount? value,
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
}
