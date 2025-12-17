import 'package:eip7702/eip7702.dart';
import 'package:test/test.dart';
import 'package:web3dart/src/utils/rlp.dart' as rlp;

import '../__test_utils__/fixtures.dart';

void main() {
  group('createAuthPreImage', () {
    test('builds canonical preimage with correct prefix and RLP payload', () {
      final unsigned = (
        chainId: chainId,
        delegateAddress: implAddress,
        nonce: customNonce,
      );

      final preImage = createAuthPreImage(unsigned);

      expect(preImage.isNotEmpty, isTrue);
      expect(preImage.first, equals(0x05));

      final payload = preImage.sublist(1);

      final expectedRlp = rlp.encode([
        chainId,
        implAddress.ethAddress.value,
        customNonce,
      ]);

      expect(payload, equals(expectedRlp));
    });

    test('same input produces deterministic preimage bytes', () {
      final unsigned = (
        chainId: chainId,
        delegateAddress: implAddress,
        nonce: customNonce,
      );

      final a = createAuthPreImage(unsigned);
      final b = createAuthPreImage(unsigned);

      expect(a, equals(b));
    });

    test('different nonces produce different preimages', () {
      final unsigned1 = (
        chainId: chainId,
        delegateAddress: implAddress,
        nonce: customNonce,
      );

      final unsigned2 = (
        chainId: chainId,
        delegateAddress: implAddress,
        nonce: BigInt.from(2),
      );

      final pre1 = createAuthPreImage(unsigned1);
      final pre2 = createAuthPreImage(unsigned2);

      expect(pre1, isNot(equals(pre2)));
    });
  });
}
