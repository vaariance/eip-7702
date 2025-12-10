part of '../../builder.dart';

/// A mixin that provides shared utilities and convenience methods for
/// EIP-7702 builders and components.
///
/// This mixin relies on the [Eip7702Base] interface, which supplies the
/// shared execution context ([ctx]). Implementations may use this mixin
/// to access common RPC helpers, authorization utilities, gas estimation
/// logic, or other reusable EIP-7702 workflows.
///
/// The mixin itself does not define behavior; it serves as a shared
/// extension point for builder implementations such as authorization
/// constructors or typed-transaction builders.
///
/// Subclasses may document additional behaviors or override methods
/// provided by mixins layered on top of this one.
///
/// See also:
///  - [Eip7702Base] – required context provider.
///  - [Eip7702Context] – network and configuration container.
mixin Eip7702Common on Eip7702Base {
  /// Reads the on-chain bytecode of an externally owned account (EOA) and
  /// extracts the delegated implementation address if the account has been
  /// upgraded via EIP-7702.
  ///
  /// This method checks whether the account code matches the minimal
  /// delegation stub:
  ///
  /// ```text
  /// 0xEF 0x01 0x00 || <20-byte implementation address>
  /// ```
  ///
  /// If the code matches this format, the function returns the final
  /// 20 bytes, representing the implementation address that the EOA is
  /// currently delegated to.
  /// Otherwise, `null` is returned.
  ///
  /// A valid delegation stub must satisfy:
  ///  - non-empty code
  ///  - code length of exactly `23` bytes
  ///  - first three bytes equal to `0xEF 0x01 0x00`
  ///  - remaining 20 bytes represent the delegated address
  ///
  /// Example:
  /// ```dart
  /// final impl = await getDelegatedImpl(myEoa);
  /// if (impl != null) {
  ///   print('EOA delegates to ${bytesToHex(impl)}');
  /// }
  /// ```
  ///
  /// See also:
  ///  - [isDelegatedTo] – checks if an EOA is delegated to a specific address.
  ///  - https://eips.ethereum.org/EIPS/eip-7702
  Future<Uint8List?> getDelegatedImpl(EthereumAddress eoa) async {
    const List<int> kStubPrefix = [0xEF, 0x01, 0x00];
    final code = await ctx.web3Client.getCode(eoa);
    if (code.isEmpty || code.length != 23) return null;

    for (var i = 0; i < kStubPrefix.length; i++) {
      if (code[i] != kStubPrefix[i]) return null;
    }
    return code.sublist(code.length - 20);
  }

  /// Retrieves EIP-1559 fee parameters (`maxFeePerGas` and
  /// `maxPriorityFeePerGas`) from the network and returns a preset based on
  /// the requested [TransactionSpeed].
  ///
  /// This method queries the connected network via
  /// [Web3Client.getGasInEIP1559], which typically returns three fee
  /// recommendations (slow, normal, fast). The preset returned corresponds
  /// to:
  ///
  ///  - [TransactionSpeed.slow]
  ///  - [TransactionSpeed.normal]
  ///  - [TransactionSpeed.fast]
  ///
  /// If no `speed` is provided, [TransactionSpeed.normal] is used.
  ///
  /// Returns a record containing:
  ///
  ///  - `maxFeePerGas` – the maximum total fee per unit of gas
  ///  - `maxPriorityFeePerGas` – the miner tip per unit of gas
  ///
  /// Example:
  /// ```dart
  /// final fees = await getFeeData(TransactionSpeed.fast);
  /// print('maxFee: ${fees.maxFeePerGas}, priority: ${fees.maxPriorityFeePerGas}');
  /// ```
  ///
  /// See also:
  ///  - [TransactionSpeed] – preset selection for fee biasing.
  ///  - https://eips.ethereum.org/EIPS/eip-1559
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

  /// Returns the next available transaction nonce for the given Ethereum
  /// address.
  ///
  /// This method queries the network via
  /// [Web3Client.getTransactionCount] with a block tag of
  /// `pending`, ensuring the returned nonce reflects both mined and
  /// in-mempool transactions. This is the recommended behavior for
  /// constructing new EIP-1559 or EIP-7702 transactions.
  ///
  /// Example:
  /// ```dart
  /// final nonce = await getNonce(myAddress);
  /// print('Next nonce: $nonce');
  /// ```
  Future<BigInt> getNonce(EthereumAddress address) async {
    final nonce = await ctx.web3Client.getTransactionCount(
      address,
      atBlock: const BlockNum.pending(),
    );
    return BigInt.from(nonce);
  }

  /// Checks whether the given externally owned account (EOA) is currently
  /// delegated to the specified implementation address.
  ///
  /// This method reads the EOA’s code via [getDelegatedImpl]. If the code
  /// contains a valid EIP-7702 delegation stub, the extracted 20-byte
  /// implementation address is compared to the provided [impl].
  ///
  /// Returns:
  ///  - `true` if the EOA delegates to [impl].
  ///  - `false` if the EOA has no delegation stub or delegates elsewhere.
  ///
  /// Example:
  /// ```dart
  /// final isActive = await isDelegatedTo(myEoa, implAddress);
  /// if (isActive) {
  ///   print('Delegation is already set.');
  /// }
  /// ```
  ///
  /// See also:
  ///  - [getDelegatedImpl] – extracts the implementation from the stub.
  Future<bool> isDelegatedTo(EthereumAddress eoa, EthereumAddress impl) async {
    final currentImpl = await getDelegatedImpl(eoa);
    if (currentImpl == null) return false;
    return bytesToHex(currentImpl) == impl.without0x;
  }

  /// Resolves and returns the active chain ID for the current context.
  ///
  /// If the [Eip7702Context.chainId] field is already set, it is returned
  /// immediately. Otherwise, the chain ID is fetched lazily from the network
  /// using [Web3Client.getChainId] and cached inside the context for future
  /// calls.
  ///
  /// This method guarantees that builders and transaction utilities operate
  /// with a consistent chain ID throughout their lifecycle.
  ///
  /// Example:
  /// ```dart
  /// final chainId = await resolveChainId();
  /// print('Connected to chain: $chainId');
  /// ```
  Future<BigInt> resolveChainId() async {
    ctx.chainId ??= await ctx.web3Client.getChainId();
    return ctx.chainId!;
  }
}
