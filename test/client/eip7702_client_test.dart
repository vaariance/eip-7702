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

class MockAuthorizationBuilder extends Mock implements AuthorizationBuilder {}

class MockSetCodeTxBuilder extends Mock implements SetCodeTxBuilder {}

void main() {
  setupMocktailFallbacks();

  late MockWeb3Client web3;
  late Eip7702Context ctx;
  late MockAuthorizationBuilder authBuilder;
  late MockSetCodeTxBuilder txBuilder;
  late Eip7702Client client;

  late Signer signer;

  setUp(() {
    web3 = MockWeb3Client();
    ctx = Eip7702Context(
      delegateAddress: implAddress.ethAddress,
      web3Client: web3,
    );

    authBuilder = MockAuthorizationBuilder();
    txBuilder = MockSetCodeTxBuilder();

    client = Eip7702Client(ctx, authBuilder, txBuilder);
    signer = Signer.eth(ethKey);
  });

  group('Eip7702Client.delegateAndCall', () {
    test(
      'builds authorization when needed and sends raw transaction',
      () async {
        final unsignedAuth = (
          chainId: chainId,
          delegateAddress: implAddress,
          nonce: customNonce,
        );

        final authTuple = (auth: unsignedAuth, signature: dummySignatureObj);

        when(
          () => authBuilder.buildAndSignIfNeeded(
            signer: signer,
            executor: any(named: "executor"),
          ),
        ).thenAnswer((_) async => authTuple);

        List<AuthorizationTuple>? capturedAuthList;
        when(
          () => txBuilder.buildSignAndEncodeRaw(
            signer: signer,
            to: nftAddress,
            data: calldata,
            authorizationList: any(named: 'authorizationList'),
          ),
        ).thenAnswer((invocation) async {
          capturedAuthList =
              invocation.namedArguments[#authorizationList]
                  as List<AuthorizationTuple>;
          return '0xdeadbeef';
        });

        when(
          () => web3.makeRPCCall('eth_sendRawTransaction', ['0xdeadbeef']),
        ).thenAnswer((_) async => '0xabcdef');

        final result = await client.delegateAndCall(
          signer: signer,
          to: nftAddress,
          data: calldata,
        );

        expect(result, equals('0xabcdef'));

        verify(
          () => authBuilder.buildAndSignIfNeeded(
            signer: signer,
            executor: any(named: "executor"),
          ),
        ).called(1);

        expect(capturedAuthList, isNotNull);
        expect(capturedAuthList, isNotEmpty);
        expect(capturedAuthList!.length, equals(1));
        expect(capturedAuthList!.first.auth.chainId, equals(chainId));
        expect(
          capturedAuthList!.first.auth.delegateAddress,
          equals(implAddress),
        );

        verify(
          () => web3.makeRPCCall('eth_sendRawTransaction', ['0xdeadbeef']),
        ).called(1);
      },
    );

    test(
      'skips authorization when already delegated (auth null from builder)',
      () async {
        when(
          () => authBuilder.buildAndSignIfNeeded(
            signer: signer,
            executor: any(named: "executor"),
          ),
        ).thenAnswer((_) async => null);

        List<AuthorizationTuple>? capturedAuthList;

        when(
          () => txBuilder.buildSignAndEncodeRaw(
            signer: signer,
            to: nftAddress,
            data: calldata,
            authorizationList: any(named: 'authorizationList'),
          ),
        ).thenAnswer((invocation) async {
          capturedAuthList =
              invocation.namedArguments[#authorizationList]
                  as List<AuthorizationTuple>;
          return '0xfeedface';
        });

        when(
          () => web3.makeRPCCall('eth_sendRawTransaction', ['0xfeedface']),
        ).thenAnswer((_) async => '0x123456');

        final result = await client.delegateAndCall(
          signer: signer,
          to: nftAddress,
          data: calldata,
        );

        expect(result, equals('0x123456'));

        verify(
          () => authBuilder.buildAndSignIfNeeded(
            signer: signer,
            executor: any(named: "executor"),
          ),
        ).called(1);

        expect(capturedAuthList, isNotNull);
        expect(capturedAuthList, isEmpty);

        verify(
          () => web3.makeRPCCall('eth_sendRawTransaction', ['0xfeedface']),
        ).called(1);
      },
    );
  });

  group('Eip7702Client.call', () {
    test('builds and sends transaction without authorization', () async {
      when(
        () => txBuilder.buildSignAndEncodeRaw(
          signer: signer,
          to: nftAddress,
          data: calldata,
          value: any(named: 'value'),
          authorizationList: any(named: 'authorizationList'),
        ),
      ).thenAnswer((invocation) async {
        final authList = invocation.namedArguments[#authorizationList]
            as List<AuthorizationTuple>;
        expect(authList, isEmpty);
        return '0xcallraw';
      });

      when(
        () => web3.makeRPCCall('eth_sendRawTransaction', ['0xcallraw']),
      ).thenAnswer((_) async => '0xcallhash');

      final result = await client.call(
        txSigner: signer,
        to: nftAddress,
        data: calldata,
      );

      expect(result, equals('0xcallhash'));

      verify(
        () => txBuilder.buildSignAndEncodeRaw(
          signer: signer,
          to: nftAddress,
          data: calldata,
          value: any(named: 'value'),
          authorizationList: any(named: 'authorizationList'),
        ),
      ).called(1);

      verify(
        () => web3.makeRPCCall('eth_sendRawTransaction', ['0xcallraw']),
      ).called(1);

      // Verify authorization builder was NOT called
      verifyZeroInteractions(authBuilder);
    });

    test('sends transaction with value when provided', () async {
      final value = BigInt.from(1000000000000000000); // 1 ETH

      BigInt? capturedValue;
      when(
        () => txBuilder.buildSignAndEncodeRaw(
          signer: signer,
          to: nftAddress,
          data: calldata,
          value: any(named: 'value'),
          authorizationList: any(named: 'authorizationList'),
        ),
      ).thenAnswer((invocation) async {
        capturedValue = invocation.namedArguments[#value] as BigInt?;
        return '0xvalueraw';
      });

      when(
        () => web3.makeRPCCall('eth_sendRawTransaction', ['0xvalueraw']),
      ).thenAnswer((_) async => '0xvaluehash');

      final result = await client.call(
        txSigner: signer,
        to: nftAddress,
        data: calldata,
        value: value,
      );

      expect(result, equals('0xvaluehash'));
      expect(capturedValue, equals(value));
    });

    test('works with null data for simple value transfers', () async {
      when(
        () => txBuilder.buildSignAndEncodeRaw(
          signer: signer,
          to: nftAddress,
          data: null,
          value: any(named: 'value'),
          authorizationList: any(named: 'authorizationList'),
        ),
      ).thenAnswer((_) async => '0xtransferraw');

      when(
        () => web3.makeRPCCall('eth_sendRawTransaction', ['0xtransferraw']),
      ).thenAnswer((_) async => '0xtransferhash');

      final result = await client.call(
        txSigner: signer,
        to: nftAddress,
      );

      expect(result, equals('0xtransferhash'));

      verify(
        () => txBuilder.buildSignAndEncodeRaw(
          signer: signer,
          to: nftAddress,
          data: null,
          value: any(named: 'value'),
          authorizationList: any(named: 'authorizationList'),
        ),
      ).called(1);
    });
  });

  group('Eip7702Client.revokeDelegation', () {
    test(
      'throws AssertionError when EOA is not delegating to delegateAddress',
      () async {
        final eoa = signer.ethPrivateKey.address;

        when(
          () => authBuilder.isDelegatedTo(eoa, implAddress.ethAddress),
        ).thenAnswer((_) async => false);

        when(
          () => authBuilder.resolveChainId(),
        ).thenAnswer((_) async => chainId);

        expect(
          () => client.revokeDelegation(signer: signer),
          throwsA(isA<AssertionError>()),
        );

        verify(
          () => authBuilder.isDelegatedTo(eoa, implAddress.ethAddress),
        ).called(1);
        verifyNever(
          () => authBuilder.buildUnsigned(
            eoa: eoa,
            delegateOverride: implAddress,
            nonceOverride: customNonce,
          ),
        );
        verifyNever(
          () => txBuilder.buildSignAndEncodeRaw(
            signer: signer,
            to: nftAddress,
            data: calldata,
            authorizationList: any(named: 'authorizationList'),
          ),
        );
      },
    );

    test(
      'builds zero-delegate authorization and sends raw tx when revoking',
      () async {
        final eoa = signer.ethPrivateKey.address;

        when(
          () => authBuilder.isDelegatedTo(eoa, implAddress.ethAddress),
        ).thenAnswer((_) async => true);

        when(
          () => authBuilder.resolveChainId(),
        ).thenAnswer((_) async => chainId);

        UnsignedAuthorization? capturedUnsigned;
        String? capturedDelegateOverride;

        when(
          () => authBuilder.buildUnsigned(
            eoa: eoa,
            executor: any(named: "executor"),
            delegateOverride: any(named: 'delegateOverride'),
            nonceOverride: any(named: 'nonceOverride'),
          ),
        ).thenAnswer((invocation) async {
          capturedDelegateOverride =
              invocation.namedArguments[#delegateOverride];

          final unsigned = (
            chainId: chainId,
            delegateAddress: zeroAddress,
            nonce: customNonce,
          );
          capturedUnsigned = unsigned;
          return unsigned;
        });

        List<AuthorizationTuple>? capturedAuthList;

        when(
          () => txBuilder.buildSignAndEncodeRaw(
            signer: signer,
            to: any(named: 'to'),
            data: any(named: 'data'),
            value: any(named: 'value'),
            authorizationList: any(named: 'authorizationList'),
          ),
        ).thenAnswer((invocation) async {
          capturedAuthList =
              invocation.namedArguments[#authorizationList]
                  as List<AuthorizationTuple>;
          return '0xdeadbeefcafebabe';
        });

        when(
          () => web3.makeRPCCall('eth_sendRawTransaction', [
            '0xdeadbeefcafebabe',
          ]),
        ).thenAnswer((_) async => '0xrevoketxhash');

        final result = await client.revokeDelegation(signer: signer);

        expect(result, equals('0xrevoketxhash'));

        verify(
          () => authBuilder.isDelegatedTo(eoa, implAddress.ethAddress),
        ).called(1);

        expect(capturedDelegateOverride, isNotNull);
        expect(
          capturedDelegateOverride!,
          equals('0x0000000000000000000000000000000000000000'),
        );

        expect(capturedUnsigned, isNotNull);
        expect(capturedUnsigned!.chainId, equals(chainId));
        expect(
          bytesToHex(
            capturedUnsigned!.delegateAddress.ethAddress.value,
            include0x: true,
          ),
          equals('0x0000000000000000000000000000000000000000'),
        );

        expect(capturedAuthList, isNotNull);
        expect(capturedAuthList!.length, equals(1));

        verify(
          () => web3.makeRPCCall('eth_sendRawTransaction', [
            '0xdeadbeefcafebabe',
          ]),
        ).called(1);
      },
    );
  });

  group('Eip7702Client (composition)', () {
    test(
      'delegateAndCall first time: builds auth + builds tx and sends typed 0x04',
      () async {
        final web3 = MockWeb3Client();

        final client = create7702Client(
          rpcUrl:
              'http://localhost:8545', // unused because customClient provided
          delegateAddress: implAddress,
          customClient: web3,
        );

        final signer = Signer.eth(ethKey);
        final eoa = signer.ethPrivateKey.address;

        when(() => web3.getCode(eoa)).thenAnswer((_) async => Uint8List(0));

        when(() => web3.getChainId()).thenAnswer((_) async => chainId);

        when(
          () =>
              web3.getTransactionCount(eoa, atBlock: const BlockNum.pending()),
        ).thenAnswer((_) async => customNonce.toInt());

        when(
          () => web3.getGasInEIP1559(),
        ).thenAnswer((_) async => [slow, normal, fast]);

        // 5) Gas estimation (make this loose; verify separately if you want strict)
        when(
          () => web3.estimateGas(
            sender: any(named: 'sender'),
            to: any(named: 'to'),
            data: any(named: 'data'),
            value: any(named: 'value'),
            maxPriorityFeePerGas: any(named: 'maxPriorityFeePerGas'),
            maxFeePerGas: any(named: 'maxFeePerGas'),
          ),
        ).thenAnswer((_) async => BigInt.from(21000));

        // 6) Capture raw tx
        String? capturedRaw;
        when(
          () => web3.makeRPCCall('eth_sendRawTransaction', any()),
        ).thenAnswer((invocation) async {
          final params = invocation.positionalArguments[1] as List<dynamic>;
          capturedRaw = params.first as String;
          return '0xabcdef';
        });

        // Act
        final hash = await client.delegateAndCall(
          signer: signer,
          to: nftAddress,
          data: calldata,
        );

        // Assert
        expect(hash, equals('0xabcdef'));
        expect(capturedRaw, isNotNull);
        expect(capturedRaw!.startsWith('0x'), isTrue);

        final rawBytes = hexToBytes(capturedRaw!);
        expect(rawBytes.isNotEmpty, isTrue);

        expect(rawBytes.first, equals(TransactionType.eip7702.value));

        verify(
          () => web3.makeRPCCall('eth_sendRawTransaction', any()),
        ).called(1);
      },
    );
  });

  group('create7702Client', () {
    test('creates client with managed Web3Client when customClient is null', () {
      final client = create7702Client(
        rpcUrl: 'https://rpc.example.com',
        delegateAddress: implAddress,
      );

      expect(client, isA<Eip7702Client>());
      expect(client.ctx.delegateAddress, equals(implAddress.ethAddress));
      expect(client.ctx.web3Client, isNotNull);
      expect(client.ctx.transformer, isNull);
      expect(client.ctx.chainId, isNull);
    });

    test('creates client with transformer in managed mode', () {
      BigInt transformer(BigInt gas) => gas * BigInt.from(15) ~/ BigInt.from(10);

      final client = create7702Client(
        rpcUrl: 'https://rpc.example.com',
        delegateAddress: implAddress,
        transformer: transformer,
      );

      expect(client, isA<Eip7702Client>());
      expect(client.ctx.transformer, isNotNull);

      // Test transformer functionality
      final result = client.ctx.transformer!(BigInt.from(100));
      expect(result, equals(BigInt.from(150)));
    });

    test('creates client with custom Web3Client when provided', () {
      final customWeb3 = MockWeb3Client();
      final client = create7702Client(
        rpcUrl: 'https://ignored.example.com', // should be ignored
        delegateAddress: implAddress,
        customClient: customWeb3,
      );

      expect(client, isA<Eip7702Client>());
      expect(client.ctx.delegateAddress, equals(implAddress.ethAddress));
      expect(client.ctx.web3Client, equals(customWeb3));
      expect(client.ctx.transformer, isNull);
    });

    test('applies transformer even with custom Web3Client', () {
      BigInt transformer(BigInt gas) => gas + BigInt.from(5000);

      final customWeb3 = MockWeb3Client();
      final client = create7702Client(
        rpcUrl: 'https://ignored.example.com',
        delegateAddress: implAddress,
        customClient: customWeb3,
        transformer: transformer,
      );

      expect(client.ctx.web3Client, equals(customWeb3));
      expect(client.ctx.transformer, isNotNull);

      final result = client.ctx.transformer!(BigInt.from(20000));
      expect(result, equals(BigInt.from(25000)));
    });

    test('client has properly initialized builders', () {
      final client = create7702Client(
        rpcUrl: 'https://rpc.example.com',
        delegateAddress: implAddress,
      );

      // Verify the client is fully initialized and functional
      expect(client, isA<Eip7702Client>());
      expect(client, isA<Eip7702ClientBase>());
    });
  });
}
