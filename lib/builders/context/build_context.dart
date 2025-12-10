part of '../../builder.dart';

/// Holds the shared configuration and network environment used by all
/// EIP-7702 builders, transaction utilities, and signing workflows.
///
/// An [Eip7702Context] encapsulates:
///
///  - [delegateAddress] — the implementation contract that externally
///    owned accounts (EOAs) will delegate to via EIP-7702.
///  - [web3Client] — the active [Web3Client] instance for RPC access.
///  - [chainId] — the connected network’s chain ID, cached for reuse.
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

  Eip7702Context({
    required this.delegateAddress,
    required this.web3Client,
    this.chainId,
  });

  static Future<Eip7702Context> forge({
    required String rpcUrl,
    required EthereumAddress delegateAddress,
  }) async {
    final client = Web3Client(rpcUrl, http.Client());
    final chainId = await client.getChainId();
    return Eip7702Context(
      delegateAddress: delegateAddress,
      web3Client: client,
      chainId: chainId,
    );
  }
}
