part of '../../builder.dart';

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
