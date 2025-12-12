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
    ctx = Eip7702Context(delegateAddress: implAddress, web3Client: web3);

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

  group('Eip7702Client.revokeDelegation', () {
    test(
      'throws AssertionError when EOA is not delegating to delegateAddress',
      () async {
        final eoa = signer.ethPrivateKey.address;

        when(
          () => authBuilder.isDelegatedTo(eoa, implAddress),
        ).thenAnswer((_) async => false);

        when(
          () => authBuilder.resolveChainId(),
        ).thenAnswer((_) async => chainId);

        expect(
          () => client.revokeDelegation(signer: signer),
          throwsA(isA<AssertionError>()),
        );

        verify(() => authBuilder.isDelegatedTo(eoa, implAddress)).called(1);
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
          () => authBuilder.isDelegatedTo(eoa, implAddress),
        ).thenAnswer((_) async => true);

        when(
          () => authBuilder.resolveChainId(),
        ).thenAnswer((_) async => chainId);

        UnsignedAuthorization? capturedUnsigned;
        EthereumAddress? capturedDelegateOverride;

        when(
          () => authBuilder.buildUnsigned(
            eoa: eoa,
            executor: any(named: "executor"),
            delegateOverride: any(named: 'delegateOverride'),
            nonceOverride: any(named: 'nonceOverride'),
          ),
        ).thenAnswer((invocation) async {
          capturedDelegateOverride =
              invocation.namedArguments[#delegateOverride] as EthereumAddress;

          final unsigned = (
            chainId: chainId,
            delegateAddress: EthereumAddress(Uint8List(20)),
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

        verify(() => authBuilder.isDelegatedTo(eoa, implAddress)).called(1);

        expect(capturedDelegateOverride, isNotNull);
        expect(
          bytesToHex(capturedDelegateOverride!.value, include0x: true),
          equals('0x0000000000000000000000000000000000000000'),
        );

        expect(capturedUnsigned, isNotNull);
        expect(capturedUnsigned!.chainId, equals(chainId));
        expect(
          bytesToHex(capturedUnsigned!.delegateAddress.value, include0x: true),
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
}
