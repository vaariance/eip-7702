import 'dart:typed_data';

import 'package:eip1559/eip1559.dart';
import 'package:eip7702/eip7702.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import 'keys.dart';

// simple smart account
final implAddress = '0xe6Cae83BdE06E4c305530e199D7217f42808555B';

// erc 721 mint : execute -> safeMint
final Uint8List calldata = hexToBytes(
  "b61d27f6000000000000000000000000ebe46f55b40c0875354ac749893fe45ce28e133300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000002440d097c30000000000000000000000002c4ac5c1a7a5bc33684b8040d3687983fcd23f9100000000000000000000000000000000000000000000000000000000",
);

// 0.001 eth
final value = BigInt.from(0.001e18);
final valueEtherAmount = EtherAmount.inWei(value);

final Uint8List dummySignature = hexToBytes(
  "ee2eb84d326637ae9c4eb2febe1f74dc43e6bb146182ef757ebf0c7c6e0d29dc2530d8b5ec0ab1d0d6ace9359e1f9b117651202e8a7f1f664ce6978621c7d5fb1b",
);

// base sepolia
final nftAddress = '0xEBE46f55b40C0875354Ac749893fe45Ce28e1333';

final chainId = BigInt.from(84532);

final customNonce = BigInt.from(0x78);

final defaultSender = ethKey.address.with0x;

final testGas = EtherAmount.fromInt(EtherUnit.gwei, 21000);

final dummySignatureObj = EIP7702MsgSignature.fromUint8List(dummySignature);

final slow = Fee(
  maxFeePerGas: BigInt.from(10),
  maxPriorityFeePerGas: BigInt.from(1),
  estimatedGas: BigInt.zero,
);
final normal = Fee(
  maxFeePerGas: BigInt.from(20),
  maxPriorityFeePerGas: BigInt.from(2),
  estimatedGas: BigInt.one,
);
final fast = Fee(
  maxFeePerGas: BigInt.from(30),
  maxPriorityFeePerGas: BigInt.from(3),
  estimatedGas: BigInt.two,
);
