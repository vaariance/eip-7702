import 'package:eip7702/builder.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import 'package:eip7702/eip7702.dart';
import '../__test_utils__/fixtures.dart';
import '../__test_utils__/keys.dart';
import '../__test_utils__/mocks.dart';

void main() {
  late MockWeb3Client web3;
  late Eip7702Context ctx;
  late SetCodeTxBuilder builder;
  late Signer signer;

  setUpAll(() {
    setupMocktailFallbacks();
  });

  setUp(() {
    web3 = MockWeb3Client();
    ctx = Eip7702Context(
      delegateAddress: implAddress.ethAddress,
      web3Client: web3,
    );

    builder = SetCodeTxBuilder(ctx);
    signer = Signer.eth(ethKey);
  });

  whenEstimatingGas(sender, to) => when(
    () => web3.estimateGas(
      sender: any(named: 'sender'),
      to: any(named: 'to'),
      data: any(named: 'data'),
      value: any(named: 'value'),
      maxPriorityFeePerGas: any(named: 'maxPriorityFeePerGas'),
      maxFeePerGas: any(named: 'maxFeePerGas'),
    ),
  ).thenAnswer((_) async => testGas.getInWei);

  group('prepareUnsigned', () {
    test('returns closure that uses nonceOverride and estimates gas', () async {
      final sender = signer.ethPrivateKey.address.with0x;
      final to = sender;
      when(
        () => web3.getGasInEIP1559(),
      ).thenAnswer((_) async => [slow, normal, fast]);

      final nonceOverride = BigInt.from(99);

      final prepareFn = await builder.prepareUnsigned(
        sender,
        to,
        nonceOverride,
      );

      whenEstimatingGas(sender, to);

      final unsigned = await prepareFn(value, calldata, 0);

      expect(unsigned.nonce, equals(nonceOverride.toInt()));
      expect(unsigned.from, equals(sender.ethAddress));
      expect(unsigned.to, equals(to.ethAddress));
      expect(unsigned.value!.getInWei, equals(value));
      expect(unsigned.data, equals(calldata));
      expect(unsigned.gasLimit, equals(testGas.getInWei));

      verifyNever(
        () =>
            web3.getTransactionCount(any(), atBlock: const BlockNum.pending()),
      );
    });
  });

  group('buildUnsigned', () {
    test('constructs Unsigned7702Tx and attaches authorizationList', () async {
      final sender = signer.ethPrivateKey.address.with0x;
      final to = sender;

      when(
        () => web3.getGasInEIP1559(),
      ).thenAnswer((_) async => [slow, normal, fast]);

      when(
        () => web3.getTransactionCount(
          sender.ethAddress,
          atBlock: const BlockNum.pending(),
        ),
      ).thenAnswer((_) async => customNonce.toInt());

      when(() => web3.getChainId()).thenAnswer((_) async => chainId);

      whenEstimatingGas(sender, to);

      final unsignedAuth = (
        chainId: chainId,
        delegateAddress: ctx.delegateAddress.with0x,
        nonce: customNonce,
      );

      final authTuple = (auth: unsignedAuth, signature: dummySignatureObj);

      final unsignedTx = await builder.buildUnsigned(
        sender: sender,
        to: to,
        value: value,
        data: calldata,
        authorizationList: [authTuple],
      );

      expect(unsignedTx.from, equals(sender.ethAddress));
      expect(unsignedTx.to, equals(to.ethAddress));
      expect(unsignedTx.gasLimit, equals(testGas.getInWei + baseAuthCost));
      expect(unsignedTx.nonce, equals(customNonce.toInt()));
      expect(unsignedTx.authorizationList.length, equals(1));
      expect(unsignedTx.authorizationList.first.auth.chainId, equals(chainId));
    });
  });

  group('signUnsigned', () {
    test('produces Signed7702Tx with recoverable signer', () async {
      final sender = signer.ethPrivateKey.address;
      final to = sender;

      when(() => web3.getChainId()).thenAnswer((_) async => chainId);

      final unsignedTx = Unsigned7702Tx(
        from: sender,
        to: to,
        gasLimit: testGas.getInWei,
        nonce: 1,
        value: valueEtherAmount,
        data: calldata,
        maxFeePerGas: testGas,
        maxPriorityFeePerGas: testGas,
        authorizationList: const [],
      );

      final signed = await builder.signUnsigned(
        signer: signer,
        unsignedTx: unsignedTx,
      );

      final preImage = createTxPreImage(unsignedTx, chainId: chainId.toInt());
      final digest = keccak256(preImage);

      final recoveredPubKey = ecRecover(digest, signed.signature);
      final recoveredAddr = EthereumAddress(
        publicKeyToAddress(recoveredPubKey),
      );

      expect(recoveredAddr.eip55With0x, equals(sender.eip55With0x));
    });
  });

  group('buildSignAndEncodeRaw', () {
    test('builds, signs and returns hex-encoded raw transaction', () async {
      final sender = signer.ethPrivateKey.address.with0x;
      final to = sender;

      when(() => web3.getChainId()).thenAnswer((_) async => chainId);

      when(
        () => web3.getTransactionCount(
          sender.ethAddress,
          atBlock: const BlockNum.pending(),
        ),
      ).thenAnswer((_) async => customNonce.toInt());

      when(
        () => web3.getGasInEIP1559(),
      ).thenAnswer((_) async => [slow, normal, fast]);

      whenEstimatingGas(sender, to);

      final unsignedAuth = (
        chainId: chainId,
        delegateAddress: ctx.delegateAddress.with0x,
        nonce: customNonce,
      );

      final authTuple = (auth: unsignedAuth, signature: dummySignatureObj);

      final raw = await builder.buildSignAndEncodeRaw(
        signer: signer,
        to: to,
        value: value,
        data: calldata,
        authorizationList: [authTuple],
      );

      expect(raw.startsWith('0x'), isTrue);

      final rawBytes = hexToBytes(raw);
      expect(rawBytes.isNotEmpty, isTrue);

      expect(
        rawBytes.first,
        equals(TransactionType.eip7702.value),
        reason: 'Expected EIP-7702 type prefix 0x04 in raw transaction',
      );
    });
  });
}
