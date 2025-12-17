import 'dart:typed_data';

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
  late AuthorizationBuilder builder;

  late Signer signer;

  setUp(() {
    web3 = MockWeb3Client();
    ctx = Eip7702Context(
      delegateAddress: implAddress.ethAddress,
      web3Client: web3,
    );
    builder = AuthorizationBuilder(ctx);
    signer = Signer.eth(ethKey);
  });

  group('buildUnsigned', () {
    eoa() => signer.ethPrivateKey.address;
    test(
      'resolves chainId, nonce and uses context.delegateAddress by default',
      () async {
        when(() => web3.getChainId()).thenAnswer((_) async => chainId);
        when(
          () => web3.getTransactionCount(
            eoa(),
            atBlock: const BlockNum.pending(),
          ),
        ).thenAnswer((_) async => customNonce.toInt());

        final unsigned = await builder.buildUnsigned(eoa: eoa());

        expect(unsigned.chainId, equals(chainId));
        expect(unsigned.nonce, equals(customNonce));
        expect(unsigned.delegateAddress, equals(ctx.delegateAddress.with0x));
      },
    );

    test('respects delegateOverride when provided', () async {
      when(() => web3.getChainId()).thenAnswer((_) async => chainId);
      when(
        () =>
            web3.getTransactionCount(eoa(), atBlock: const BlockNum.pending()),
      ).thenAnswer((_) async => customNonce.toInt());

      final unsigned = await builder.buildUnsigned(
        eoa: eoa(),
        delegateOverride: zeroAddress,
      );

      expect(unsigned.chainId, equals(chainId));
      expect(unsigned.nonce, equals(customNonce));
      expect(unsigned.delegateAddress, equals(zeroAddress));
    });

    test(
      'respects nonceOverride and does not call getTransactionCount',
      () async {
        final nonceOverride = BigInt.from(999);

        when(() => web3.getChainId()).thenAnswer((_) async => chainId);

        final unsigned = await builder.buildUnsigned(
          eoa: eoa(),
          nonceOverride: nonceOverride,
        );

        expect(unsigned.chainId, equals(chainId));
        expect(unsigned.nonce, equals(nonceOverride));

        verifyNever(
          () => web3.getTransactionCount(
            eoa(),
            atBlock: const BlockNum.pending(),
          ),
        );
      },
    );
  });

  group('buildAndSign', () {
    test(
      'produces an authorization tuple whose signer matches the EOA',
      () async {
        final eoa = signer.ethPrivateKey.address;
        when(() => web3.getChainId()).thenAnswer((_) async => chainId);
        when(
          () =>
              web3.getTransactionCount(eoa, atBlock: const BlockNum.pending()),
        ).thenAnswer((_) async => customNonce.toInt());

        final tuple = await builder.buildAndSign(signer: signer);

        expect(tuple.auth.chainId, equals(chainId));
        expect(tuple.auth.delegateAddress, equals(ctx.delegateAddress.with0x));
        expect(tuple.auth.nonce, equals(customNonce));

        final preImage = createAuthPreImage(tuple.auth);
        final digest = keccak256(preImage);
        final recoveredPubKey = ecRecover(digest, tuple.signature);
        final recoveredAddr = EthereumAddress(
          publicKeyToAddress(recoveredPubKey),
        );

        expect(recoveredAddr.eip55With0x, equals(eoa.eip55With0x));
      },
    );
  });

  group('buildAndSignIfNeeded', () {
    eoa() => signer.ethPrivateKey.address;
    test(
      'returns null when EOA is already delegating to ctx.delegateAddress',
      () async {
        final code = Uint8List.fromList([
          0xEF,
          0x01,
          0x00,
          ...ctx.delegateAddress.value,
        ]);

        when(() => web3.getCode(eoa())).thenAnswer((_) async => code);

        final tuple = await builder.buildAndSignIfNeeded(signer: signer);

        expect(tuple, isNull);
      },
    );

    test('builds and signs when not yet delegated', () async {
      when(() => web3.getCode(eoa())).thenAnswer((_) async => Uint8List(0));
      when(() => web3.getChainId()).thenAnswer((_) async => chainId);
      when(
        () =>
            web3.getTransactionCount(eoa(), atBlock: const BlockNum.pending()),
      ).thenAnswer((_) async => customNonce.toInt());

      final tuple = await builder.buildAndSignIfNeeded(signer: signer);

      expect(tuple, isNotNull);
      expect(tuple!.auth.nonce, equals(customNonce));

      final preImage = createAuthPreImage(tuple.auth);
      final digest = keccak256(preImage);
      final recoveredPubKey = ecRecover(digest, tuple.signature);
      final recoveredAddr = EthereumAddress(
        publicKeyToAddress(recoveredPubKey),
      );

      expect(recoveredAddr.eip55With0x, equals(eoa().eip55With0x));
    });
  });
}
