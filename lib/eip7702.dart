library;

import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wallet/wallet.dart';
// ignore: implementation_imports
import "package:web3dart/src/utils/rlp.dart" as rlp;
import "package:web3dart/web3dart.dart";

part 'package:eip7702/types/authorization_tuple.dart';
part 'package:eip7702/types/set_code_tx.dart';
part 'package:eip7702/types/signer_interface.dart';
part 'package:eip7702/types/signer_interface.freezed.dart';
part 'package:eip7702/utils/encoding.dart';
part 'package:eip7702/signing/tx_signer.dart';
part 'package:eip7702/signing/auth_signer.dart';
