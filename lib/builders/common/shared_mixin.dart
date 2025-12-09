part of '../../builder.dart';

mixin Eip7702Common on Eip7702Base {
  Future<Uint8List?> getDelegatedImpl(EthereumAddress eoa) async {
    const List<int> kStubPrefix = [0xEF, 0x01, 0x00];
    final code = await ctx.web3Client.getCode(eoa);
    if (code.isEmpty || code.length != 23) return null;

    for (var i = 0; i < kStubPrefix.length; i++) {
      if (code[i] != kStubPrefix[i]) return null;
    }
    return code.sublist(code.length - 20);
  }

  Future<({BigInt maxFeePerGas, BigInt maxPriorityFeePerGas})> getFeeData([
    TransactionSpeed speed = TransactionSpeed.normal,
  ]) async {
    final fee = await ctx.web3Client.getGasInEIP1559();
    return switch (speed) {
      TransactionSpeed.slow => (
        maxFeePerGas: fee[0].maxFeePerGas,
        maxPriorityFeePerGas: fee[0].maxPriorityFeePerGas,
      ),
      TransactionSpeed.normal => (
        maxFeePerGas: fee[1].maxFeePerGas,
        maxPriorityFeePerGas: fee[1].maxPriorityFeePerGas,
      ),
      TransactionSpeed.fast => (
        maxFeePerGas: fee[2].maxFeePerGas,
        maxPriorityFeePerGas: fee[2].maxPriorityFeePerGas,
      ),
    };
  }

  Future<BigInt> getNonce(EthereumAddress address) async {
    final nonce = await ctx.web3Client.getTransactionCount(
      address,
      atBlock: const BlockNum.pending(),
    );
    return BigInt.from(nonce);
  }

  Future<bool> isDelegatedTo(EthereumAddress eoa, EthereumAddress impl) async {
    final currentImpl = await getDelegatedImpl(eoa);
    if (currentImpl == null) return false;
    return bytesToHex(currentImpl) == impl.without0x;
  }

  Future<BigInt> resolveChainId() async {
    ctx.chainId ??= await ctx.web3Client.getChainId();
    return ctx.chainId!;
  }
}
