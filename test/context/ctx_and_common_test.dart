import 'dart:typed_data';

import 'package:eip7702/builder.dart';
import 'package:eip7702/eip7702.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

import '../__test_utils__/fixtures.dart';
import '../__test_utils__/mocks.dart';

void main() {
  late MockWeb3Client web3;
  late Eip7702Context context;
  late TestCommon common;

  setUp(() {
    web3 = MockWeb3Client();
    context = Eip7702Context(
      delegateAddress: implAddress.ethAddress,
      web3Client: web3,
    );
    common = TestCommon(context);
  });

  group('getDelegatedImpl', () {
    test('returns null when code is empty', () async {
      when(
        () => web3.getCode(defaultSender.ethAddress),
      ).thenAnswer((_) async => Uint8List(0));

      final impl = await common.getDelegatedImpl(defaultSender.ethAddress);
      expect(impl, isNull);
    });

    test('returns null when code length is not 23 bytes', () async {
      when(
        () => web3.getCode(defaultSender.ethAddress),
      ).thenAnswer((_) async => Uint8List.fromList([0xEF, 0x01])); // too short

      final impl = await common.getDelegatedImpl(defaultSender.ethAddress);
      expect(impl, isNull);
    });

    test('returns null when prefix does not match 0xEF0100', () async {
      final bytes = Uint8List(23);
      bytes.setAll(0, [0x00, 0x01, 0x00]); // wrong prefix

      when(
        () => web3.getCode(defaultSender.ethAddress),
      ).thenAnswer((_) async => bytes);

      final impl = await common.getDelegatedImpl(defaultSender.ethAddress);
      expect(impl, isNull);
    });

    test(
      'returns last 20 bytes when stub prefix and length are valid',
      () async {
        // prefix: 0xEF 0x01 0x00, then 20 bytes of "impl"
        final code = Uint8List.fromList([
          0xEF,
          0x01,
          0x00,
          ...implAddress.ethAddress.value,
        ]);

        when(
          () => web3.getCode(defaultSender.ethAddress),
        ).thenAnswer((_) async => code);

        final impl = await common.getDelegatedImpl(defaultSender.ethAddress);
        expect(impl, isNotNull);
        expect(impl!.length, equals(20));
        expect(impl, equals(implAddress.ethAddress.value));
      },
    );
  });

  group('isDelegatedTo', () {
    test('returns false when getDelegatedImpl returns null', () async {
      when(
        () => web3.getCode(defaultSender.ethAddress),
      ).thenAnswer((_) async => Uint8List(0));

      final result = await common.isDelegatedTo(
        defaultSender.ethAddress,
        implAddress.ethAddress,
      );
      expect(result, isFalse);
    });

    test('returns true when current impl matches expected impl', () async {
      final code = Uint8List.fromList([
        0xEF,
        0x01,
        0x00,
        ...implAddress.ethAddress.value,
      ]);

      when(
        () => web3.getCode(defaultSender.ethAddress),
      ).thenAnswer((_) async => code);

      final result = await common.isDelegatedTo(
        defaultSender.ethAddress,
        implAddress.ethAddress,
      );
      expect(result, isTrue);
    });

    test(
      'returns false when current impl does not match expected impl',
      () async {
        final code = Uint8List.fromList([0xEF, 0x01, 0x00, ...Uint8List(32)]);

        when(
          () => web3.getCode(defaultSender.ethAddress),
        ).thenAnswer((_) async => code);

        final result = await common.isDelegatedTo(
          defaultSender.ethAddress,
          implAddress.ethAddress,
        );
        expect(result, isFalse);
      },
    );
  });

  group('getFeeData', () {
    test(
      'returns slow/normal/fast presets based on TransactionSpeed',
      () async {
        when(
          () => web3.getGasInEIP1559(),
        ).thenAnswer((_) async => [slow, normal, fast]);

        final slowFees = await common.getFeeData(TransactionSpeed.slow);
        final normalFees = await common.getFeeData(TransactionSpeed.normal);
        final fastFees = await common.getFeeData(TransactionSpeed.fast);

        expect(slowFees.maxFeePerGas, equals(BigInt.from(10)));
        expect(slowFees.maxPriorityFeePerGas, equals(BigInt.from(1)));

        expect(normalFees.maxFeePerGas, equals(BigInt.from(20)));
        expect(normalFees.maxPriorityFeePerGas, equals(BigInt.from(2)));

        expect(fastFees.maxFeePerGas, equals(BigInt.from(30)));
        expect(fastFees.maxPriorityFeePerGas, equals(BigInt.from(3)));
      },
    );

    test('defaults to normal when no speed is provided', () async {
      when(
        () => web3.getGasInEIP1559(),
      ).thenAnswer((_) async => [slow, normal, fast]);

      final fees = await common.getFeeData();
      expect(fees.maxFeePerGas, equals(BigInt.from(20)));
      expect(fees.maxPriorityFeePerGas, equals(BigInt.from(2)));
    });
  });

  group('getNonce', () {
    test(
      'wraps getTransactionCount with BlockNum.pending and BigInt',
      () async {
        when(
          () => web3.getTransactionCount(
            defaultSender.ethAddress,
            atBlock: const BlockNum.pending(),
          ),
        ).thenAnswer((_) async => 5);

        final nonce = await common.getNonce(defaultSender.ethAddress);
        expect(nonce, equals(BigInt.from(5)));
      },
    );
  });

  group('resolveChainId', () {
    test('fetches chainId from Web3Client and caches it in context', () async {
      when(() => web3.getChainId()).thenAnswer((_) async => chainId);

      final chainId1 = await common.resolveChainId();
      final chainId2 = await common.resolveChainId();

      expect(chainId1, equals(chainId));
      expect(chainId2, equals(chainId));

      // Only called once due to caching
      verify(() => web3.getChainId()).called(1);
    });

    test(
      'returns existing context.chainId without RPC call when already set',
      () async {
        context.chainId = chainId;

        final id = await common.resolveChainId();

        expect(id, equals(chainId));
        verifyNever(() => web3.getChainId());
      },
    );
  });

  group('create7702Context', () {
    test('creates context with converted delegate address and Web3Client', () {
      final ctx = create7702Context(
        rpcUrl: 'https://rpc.example.com',
        delegateAddress: implAddress,
      );

      expect(ctx.delegateAddress, equals(implAddress.ethAddress));
      expect(ctx.web3Client, isNotNull);
      expect(ctx.transformer, isNull);
      expect(ctx.chainId, isNull);
    });

    test('creates context with transformer when provided', () {
      BigInt transformer(BigInt gas) => gas * BigInt.from(12) ~/ BigInt.from(10);
      final ctx = create7702Context(
        rpcUrl: 'https://rpc.example.com',
        delegateAddress: implAddress,
        transformer: transformer,
      );

      expect(ctx.delegateAddress, equals(implAddress.ethAddress));
      expect(ctx.web3Client, isNotNull);
      expect(ctx.transformer, equals(transformer));

      // Test transformer functionality
      final testGas = BigInt.from(100);
      final transformedGas = ctx.transformer!(testGas);
      expect(transformedGas, equals(BigInt.from(120)));
    });

    test('transformer correctly modifies gas estimates', () {
      BigInt transformer(BigInt gas) => gas + BigInt.from(10000);
      final ctx = create7702Context(
        rpcUrl: 'https://rpc.example.com',
        delegateAddress: implAddress,
        transformer: transformer,
      );

      final result = ctx.transformer!(BigInt.from(50000));
      expect(result, equals(BigInt.from(60000)));
    });
  });
}

class TestCommon extends Eip7702Base with Eip7702Common {
  @override
  final Eip7702Context ctx;

  TestCommon(this.ctx);
}
