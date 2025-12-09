part of '../builder.dart';

enum Speed {
  fast(75),
  slow(25),
  normal(50);

  const Speed(this.gasQuota);
  final int gasQuota;
}

mixin Eip7702Common on Eip7702Base {
  Future<BigInt> resolveChainId() async {
    ctx.chainId ??= await ctx.web3Client.getChainId();
    return ctx.chainId!;
  }

  Future<BigInt> getNonce(EthereumAddress address) async {
    final nonce = await ctx.web3Client.getTransactionCount(
      address,
      atBlock: const BlockNum.pending(),
    );
    return BigInt.from(nonce);
  }

  Future<({BigInt maxFeePerGas, BigInt maxPriorityFeePerGas})> getFeeData([
    Speed speed = Speed.normal,
  ]) async {
    final fee = await ctx.web3Client.getGasInEIP1559();
    return switch (speed) {
      Speed.slow => (
        maxFeePerGas: fee[0].maxFeePerGas,
        maxPriorityFeePerGas: fee[0].maxPriorityFeePerGas,
      ),
      Speed.normal => (
        maxFeePerGas: fee[1].maxFeePerGas,
        maxPriorityFeePerGas: fee[1].maxPriorityFeePerGas,
      ),
      Speed.fast => (
        maxFeePerGas: fee[2].maxFeePerGas,
        maxPriorityFeePerGas: fee[2].maxPriorityFeePerGas,
      ),
    };
  }

  Future<Uint8List?> getDelegatedImpl(EthereumAddress eoa) async {
    const List<int> kStubPrefix = [0xEF, 0x01, 0x00];
    final code = await ctx.web3Client.getCode(eoa);
    if (code.isEmpty || code.length != 23) return null;

    for (var i = 0; i < kStubPrefix.length; i++) {
      if (code[i] != kStubPrefix[i]) return null;
    }
    return code.sublist(code.length - 20);
  }

  Future<bool> isDelegatedTo(EthereumAddress eoa, EthereumAddress impl) async {
    final currentImpl = await getDelegatedImpl(eoa);
    if (currentImpl == null) return false;
    return bytesToHex(currentImpl) == impl.without0x;
  }
}
