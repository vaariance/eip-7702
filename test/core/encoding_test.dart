import 'package:eip7702/eip7702.dart';
import 'package:test/test.dart';

import '../__test_utils__/fixtures.dart';

void main() {
  group('encodeAuthorizationTupleToRlp', () {
    test('encodes tuple fields in correct order', () {
      final unsignedAuth = (
        chainId: chainId,
        delegateAddress: implAddress,
        nonce: customNonce,
      );

      final tuple = (auth: unsignedAuth, signature: dummySignatureObj);
      final encoded = encodeAuthorizationTupleToRlp(tuple);

      expect(encoded.length, equals(6));
      expect(encoded[0], equals(chainId));
      expect(encoded[1], equals(implAddress.ethAddress.value));
      expect(encoded[2], equals(customNonce));
      expect(encoded[3], equals(dummySignatureObj.yParity));
      expect(encoded[4], equals(dummySignatureObj.r));
      expect(encoded[5], equals(dummySignatureObj.s));
    });
  });

  group('encodeAuthorizationListToRlp', () {
    test('encodes a list of authorization tuples as nested lists', () {
      final auth1 = (
        chainId: chainId,
        delegateAddress: implAddress,
        nonce: customNonce,
      );

      final auth2 = (
        chainId: chainId,
        delegateAddress: zeroAddress,
        nonce: BigInt.from(2),
      );

      final list = [
        (auth: auth1, signature: dummySignatureObj),
        (auth: auth2, signature: dummySignatureObj),
      ];

      final encodedList = encodeAuthorizationListToRlp(list);
      expect(encodedList.length, equals(2));
      for (final item in encodedList) {
        expect(item, isA<List<dynamic>>());
        expect(item.length, equals(6));
      }

      final first = encodedList[0];
      expect(first[0], equals(chainId));
      expect(first[1], equals(implAddress.ethAddress.value));
      expect(first[2], equals(customNonce));

      final second = encodedList[1];
      expect(second[0], equals(chainId));
      expect(second[1], equals(zeroAddress.ethAddress.value));
      expect(second[2], equals(BigInt.from(2)));
    });
  });

  group('encodeEIP1559ToRlp', () {
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
    test('encodes base EIP-1559 fields without authorization or signature', () {
      final encoded = encodeEIP1559ToRlp(tx, null, chainId);

      expect(encoded.length, greaterThanOrEqualTo(8));

      expect(encoded[0], equals(chainId));
      expect(encoded[1], equals(tx.nonce));
      expect(encoded[2], equals(tx.maxPriorityFeePerGas!.getInWei));
      expect(encoded[3], equals(tx.maxFeePerGas!.getInWei));
      expect(encoded[4], equals(tx.gasLimit));

      // `to`
      expect(encoded[5], equals(defaultSender.ethAddress.value));

      // value, data, accessList
      expect(encoded[6], equals(tx.value!.getInWei));
      expect(encoded[7], equals(tx.data));
      expect(encoded[8], equals(tx.accessList));
    });

    test('includes authorizationList when present (EIP-7702)', () {
      final unsignedAuth = (
        chainId: chainId,
        delegateAddress: implAddress,
        nonce: customNonce,
      );

      final authTuple = (auth: unsignedAuth, signature: dummySignatureObj);

      tx.authorizationList = [authTuple];

      final encoded = encodeEIP1559ToRlp(tx, null, chainId);

      expect(encoded.length, greaterThanOrEqualTo(10));

      final encodedAuthList = encoded[9];
      expect(encodedAuthList, isA<List<dynamic>>());
      expect((encodedAuthList as List<dynamic>).length, equals(1));

      final firstAuth = encodedAuthList.first as List<dynamic>;
      expect(firstAuth.length, equals(6));
      expect(firstAuth[0], equals(chainId));
      expect(firstAuth[1], equals(implAddress.ethAddress.value));
      expect(firstAuth[2], equals(customNonce));
    });

    test('appends signature fields when signature is provided', () {
      final txSig = dummySignatureObj;

      final encoded = encodeEIP1559ToRlp(tx, txSig, chainId);

      // last three elements should be yParity, r, s.
      final yParity = encoded[encoded.length - 3];
      final r = encoded[encoded.length - 2];
      final s = encoded[encoded.length - 1];

      expect(yParity, equals(txSig.yParity));
      expect(r, equals(txSig.r));
      expect(s, equals(txSig.s));
    });
  });
}
