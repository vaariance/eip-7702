import 'dart:typed_data';

import 'package:eip7702/eip7702.dart';
import 'package:test/test.dart';

import '../__test_utils__/fixtures.dart';

void main() {
  group('EIP7702MsgSignature.forge', () {
    test('normalizes parity v=0 to v=27, yParity=0', () {
      final r = BigInt.from(1);
      final s = BigInt.from(2);

      final sig = EIP7702MsgSignature.forge(r, s, 0);

      expect(sig.v, equals(27));
      expect(sig.yParity, equals(0));
      expect(sig.r, equals(r));
      expect(sig.s, equals(s));
    });

    test('normalizes parity v=1 to v=28, yParity=1', () {
      final r = BigInt.from(3);
      final s = BigInt.from(4);

      final sig = EIP7702MsgSignature.forge(r, s, 1);

      expect(sig.v, equals(28));
      expect(sig.yParity, equals(1));
      expect(sig.r, equals(r));
      expect(sig.s, equals(s));
    });

    test('keeps v=27 as is and sets yParity=0', () {
      final r = BigInt.from(5);
      final s = BigInt.from(6);

      final sig = EIP7702MsgSignature.forge(r, s, 27);

      expect(sig.v, equals(27));
      expect(sig.yParity, equals(0));
      expect(sig.r, equals(r));
      expect(sig.s, equals(s));
    });

    test('keeps v=28 as is and sets yParity=1', () {
      final r = BigInt.from(7);
      final s = BigInt.from(8);

      final sig = EIP7702MsgSignature.forge(r, s, 28);

      expect(sig.v, equals(28));
      expect(sig.yParity, equals(1));
      expect(sig.r, equals(r));
      expect(sig.s, equals(s));
    });

    test('throws Argument error if y parity is not 0 or 1', () {
      final r = BigInt.from(7);
      final s = BigInt.from(8);

      expect(() => EIP7702MsgSignature.forge(r, s, 29), throwsArgumentError);
    });

    test('normalizes s if s is greater than sep256k1n half order', () {
      BigInt sep256k1n = BigInt.parse(
        'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
        radix: 16,
      );

      final r = BigInt.from(9);
      // s = secp256k1n / 2 + 1 (greater than half order)
      final s = (sep256k1n >> 1) + BigInt.one; // 169

      final sig = EIP7702MsgSignature.forge(r, s, 0);

      final expectedS = sep256k1n - s; // 168;
      expect(sig.s, equals(expectedS));
      expect(sig.v, equals(28));
      expect(sig.yParity, equals(1));
    });
  });

  group('EIP7702MsgSignature.fromUint8List', () {
    test('parses 65-byte signature and normalizes v/yParity when v=0', () {
      final sig = EIP7702MsgSignature.fromUint8List(dummySignature);

      expect(sig.v, equals(27));
      expect(sig.yParity, equals(0));
      expect(sig.r, isNot(equals(BigInt.zero)));
      expect(sig.s, isNot(equals(BigInt.zero)));
      expect(sig.r, isNot(equals(sig.s)));
    });

    test('parses 65-byte signature and normalizes v/yParity when v=28', () {
      final sig = EIP7702MsgSignature.fromUint8List(dummySignature..[64] = 28);

      expect(sig.v, equals(28));
      expect(sig.yParity, equals(1));
      expect(sig.r, isNot(equals(BigInt.zero)));
      expect(sig.s, isNot(equals(BigInt.zero)));
    });

    test('throws ArgumentError when length != 65', () {
      final tooShort = Uint8List(64);
      final tooLong = Uint8List(66);

      expect(
        () => EIP7702MsgSignature.fromUint8List(tooShort),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => EIP7702MsgSignature.fromUint8List(tooLong),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
