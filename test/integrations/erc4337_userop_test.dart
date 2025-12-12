import 'package:test/test.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import 'package:eip7702/eip7702.dart';

import '../__test_utils__/fixtures.dart';
import '../__test_utils__/keys.dart';

void main() {
  group('ERC-4337 + EIP-7702 integration', () {
    late Signer signer;
    late UnsignedAuthorization unsignedAuth;
    late AuthorizationTuple authTuple;
    late EthereumAddress recoveredAddr;

    setUp(() async {
      signer = Signer.eth(ethKey);

      unsignedAuth = (
        chainId: chainId,
        delegateAddress: implAddress,
        nonce: customNonce,
      );

      authTuple = signAuthorization(signer, unsignedAuth);

      final preImage = createAuthPreImage(authTuple.auth);
      final digest = keccak256(preImage);
      final recoveredPubKey = ecRecover(digest, authTuple.signature);
      final recoveredAddress = EthereumAddress(
        publicKeyToAddress(recoveredPubKey),
      );
      recoveredAddr = recoveredAddress;
    });

    group('validateUserOp', () {
      test('sets sender when op["sender"] is null', () {
        final op = <String, dynamic>{'callData': '0xdeadbeef'};

        validateUserOp(authTuple, op);

        expect(op['sender'], isNotNull);
        expect(op['sender'], equals(recoveredAddr.eip55With0x));
      });

      test(
        'accepts when sender matches recovered signer (case-insensitive)',
        () {
          final op = <String, dynamic>{
            'sender': recoveredAddr.eip55With0x,
            'callData': '0x1234',
          };

          validateUserOp(authTuple, op);

          expect(op['sender'], equals(recoveredAddr.eip55With0x));
        },
      );

      test('throws when sender does not match recovered signer', () {
        final op = <String, dynamic>{
          'sender': '0x0000000000000000000000000000000000000000',
          'callData': '0x1234',
        };

        expect(
          () => validateUserOp(authTuple, op),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('addEip7702AuthToOp', () {
      test('adds authorization field without modifying existing keys', () {
        final op = <String, dynamic>{
          'sender': recoveredAddr.eip55With0x,
          'callGasLimit': '0x5208',
        };

        final updated = addEip7702AuthToOp(authTuple, op);

        expect(updated['sender'], equals(recoveredAddr.eip55With0x));
        expect(updated['callGasLimit'], equals('0x5208'));
        expect(updated['authorization'], isNotNull);
        expect(updated['authorization'], isA<Map<String, dynamic>>());
      });
    });

    group('canonicalizeUserOp', () {
      test(
        'removes factory/factoryData, keeps sender, and attaches authorization',
        () {
          final op = <String, dynamic>{
            'factory': '0xfac7ory0000000000000000000000000000000000',
            'factoryData': '0xdeadbeef',
            'callData': '0xabc123',
          };

          final canonical = canonicalizeUserOp(authTuple, op);

          // sender should have been inferred by validateUserOp.
          expect(canonical['sender'], equals(recoveredAddr.eip55With0x));

          // factory fields should be removed.
          expect(canonical.containsKey('factory'), isFalse);
          expect(canonical.containsKey('factoryData'), isFalse);

          // initCode should NOT be added when factory was present.
          expect(canonical.containsKey('initCode'), isFalse);

          // authorization should be attached.
          expect(canonical['authorization'], isNotNull);
          expect(canonical['authorization'], isA<Map<String, dynamic>>());
        },
      );

      test(
        'sets initCode to "0x" when no factory is present and adds authorization',
        () {
          final op = <String, dynamic>{
            // no sender: should be inferred
            'callData': '0xabcdef',
          };

          final canonical = canonicalizeUserOp(authTuple, op);

          // sender inferred.
          expect(canonical['sender'], equals(recoveredAddr.eip55With0x));

          // initCode should be set to "0x" when factory is absent.
          expect(canonical['initCode'], equals('0x'));

          // authorization should be attached.
          expect(canonical['authorization'], isNotNull);
          expect(canonical['authorization'], isA<Map<String, dynamic>>());
        },
      );
    });
  });
}
