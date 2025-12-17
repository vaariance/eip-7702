part of '../../builder.dart';

/// Function signature for transforming an estimated gas value.
///
/// A [GasTransformFn] takes the original gas estimate (as a [BigInt]) and
/// returns a modified value that will be used when building transactions.
/// This is useful for applying multipliers, adding buffers, or capping
/// the gas limit before submission.
typedef GasTransformFn = BigInt Function(BigInt);

/// Holds the shared configuration and network environment used by all
/// EIP-7702 builders, transaction utilities, and signing workflows.
///
/// An [Eip7702Context] encapsulates:
///
///  - [delegateAddress] — the implementation contract that externally
///    owned accounts (EOAs) will delegate to via EIP-7702.
///  - [web3Client] — the active [Web3Client] instance for RPC access.
///  - [chainId] — the connected network’s chain ID, cached for reuse.
///  - [transformer] - useful for overriding the estimated gas
///
/// This context is typically supplied to builders such as
/// `AuthorizationBuilder` and `SetCodeTxBuilder` via [Eip7702Base], and
/// ensures that all operations share consistent network and configuration
/// state.
///
/// ### Creating a context
/// Most applications should use the [create7702Context] factory, which creates a [Web3Client] internally:
///
/// ```dart
/// final ctx = create7702Context(
///   rpcUrl: 'https://rpc.example.com',
///   delegateAddress: '0x1234...',
/// );
/// ```
class Eip7702Context {
  final EthereumAddress delegateAddress;
  final Web3Client web3Client;
  BigInt? chainId;
  GasTransformFn? transformer;

  Eip7702Context({
    required this.delegateAddress,
    required this.web3Client,
    this.chainId,
    this.transformer,
  });
}

/// Creates an [Eip7702Context] with a managed [Web3Client] instance.
///
/// This factory function is the recommended way to instantiate an
/// [Eip7702Context] for most applications. It handles:
///  - Converting the hex-formatted [delegateAddress] to an [EthereumAddress]
///  - Creating a [Web3Client] with the provided [rpcUrl]
///  - Optionally applying a [transformer] for gas estimation adjustments
///
/// The created [Web3Client] uses a default HTTP client internally.
///
/// Parameters:
///  - [rpcUrl] — the Ethereum JSON-RPC endpoint URL.
///  - [delegateAddress] — the implementation contract address as a hex string.
///  - [transformer] — optional function to modify gas estimates before
///    transaction submission (e.g., multiplying by 1.2 for a 20% buffer).
///
/// Returns a fully configured [Eip7702Context] ready for use with builders.
///
/// ### Example
/// ```dart
/// final context = create7702Context(
///   rpcUrl: 'https://mainnet.infura.io/v3/YOUR_KEY',
///   delegateAddress: '0x1234...',
///   transformer: (gas) => gas * BigInt.from(12) ~/ BigInt.from(10), // 20% buffer
/// );
/// ```
Eip7702Context create7702Context({
  required String rpcUrl,
  required HexString delegateAddress,
  GasTransformFn? transformer,
}) => Eip7702Context(
  delegateAddress: delegateAddress.ethAddress,
  web3Client: Web3Client(rpcUrl, http.Client()),
  transformer: transformer,
);
