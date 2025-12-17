import 'package:eip7702/eip7702.dart';
import 'package:test/test.dart';
import 'package:web3dart/src/utils/rlp.dart' as rlp;

import '../__test_utils__/fixtures.dart';

void main() {
  group('createTxPreImage', () {
    final tx = Unsigned7702Tx(
      from: defaultSender.ethAddress,
      to: defaultSender.ethAddress,
      gasLimit: BigInt.from(21000),
      nonce: customNonce.toInt(),
      value: valueEtherAmount,
      data: calldata,
      maxFeePerGas: testGas,
      maxPriorityFeePerGas: testGas,
    );
    test('encodes normal eip1559 tx when authlist is empty', () {
      final preImage = createTxPreImage(tx, chainId: chainId.toInt());

      expect(preImage.isNotEmpty, isTrue);
      expect(
        preImage.first,
        equals(TransactionType.eip1559.value),
        reason: 'Expected type prefix 0x02 for EIP-1559 transactions',
      );

      final body = preImage.sublist(1);

      final expectedBody = encodeEIP1559ToRlp(tx, null, chainId);
      final expectedRlp = rlp.encode(expectedBody);

      expect(body, equals(expectedRlp));
    });

    test('includes type prefix and correct RLP-encoded body', () {
      tx.authorizationList = [
        (
          auth: (
            chainId: chainId,
            delegateAddress: implAddress,
            nonce: customNonce,
          ),
          signature: dummySignatureObj,
        ),
      ];
      final preImage = createTxPreImage(tx, chainId: chainId.toInt());

      expect(preImage.isNotEmpty, isTrue);
      expect(
        preImage.first,
        equals(TransactionType.eip7702.value),
        reason: 'Expected type prefix 0x04 for EIP-7702 transactions',
      );

      final body = preImage.sublist(1);

      final expectedBody = encodeEIP1559ToRlp(tx, null, chainId);
      final expectedRlp = rlp.encode(expectedBody);

      expect(body, equals(expectedRlp));
    });

    test('Throws if chainid is not resolvable', () {
      tx.authorizationList = const [];
      expect(
        () => createTxPreImage(tx, chainId: null),
        throwsA(isA<Exception>()),
        reason: 'Chain ID must be provided to create a valid pre-image',
      );
    });
  });
}
