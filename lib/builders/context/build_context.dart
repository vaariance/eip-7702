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
///  - [transformer] - usefull for overriding the estimated gas
///
/// This context is typically supplied to builders such as
/// `AuthorizationBuilder` and `SetCodeTxBuilder` via [Eip7702Base], and
/// ensures that all operations share consistent network and configuration
/// state.
///
/// ### Creating a context
/// Most applications should use the [forge] factory, which creates a
/// [Web3Client] internally and automatically resolves the chain ID:
///
/// ```dart
/// final ctx = await Eip7702Context.forge(
///   rpcUrl: 'https://rpc.example',
///   delegateAddress: implAddress,
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

  static Future<Eip7702Context> forge({
    required String rpcUrl,
    required EthereumAddress delegateAddress,
    GasTransformFn? transformer,
  }) async {
    final client = Web3Client(rpcUrl, http.Client());
    final chainId = await client.getChainId();
    return Eip7702Context(
      delegateAddress: delegateAddress,
      web3Client: client,
      chainId: chainId,
      transformer: transformer,
    );
  }
}
