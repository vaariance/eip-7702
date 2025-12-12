import 'dart:math';
import 'package:web3dart/web3dart.dart';

final EthPrivateKey ethKey = EthPrivateKey.createRandom(Random(0x01));
final rawKey = ethKey.privateKey;

final EthPrivateKey ethKey2 = EthPrivateKey.createRandom(Random(0x02));
final rawkey2 = ethKey2.privateKey;
