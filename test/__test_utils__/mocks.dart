import 'dart:typed_data';

import 'package:eip7702/eip7702.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

class MockWeb3Client extends Mock implements Web3Client {}

class MockUnsigned7702Tx extends Mock implements Unsigned7702Tx {}

void setupMocktailFallbacks() {
  registerFallbackValue(EthereumAddress(Uint8List(20)));
  registerFallbackValue(EtherAmount.inWei(BigInt.zero));
  registerFallbackValue(Uint8List(0));
  registerFallbackValue(BigInt.zero);
}
