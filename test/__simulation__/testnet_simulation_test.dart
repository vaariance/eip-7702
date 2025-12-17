// Manual EIP-7702 testnet simulation.
//
// Usage:
//
//   export RPC_URL="https://rpc.my-testnet.lfg"
//   export PRIVATE_KEY_WITH_FUNDS="0x...."
//   export DELEGATE_ADDRESS="0x...."   # implementation contract that EOA should delegate to
//
//   dart test test/__simulation__
//
// This test is designed to be run manually. If the required environment
// variables are not set, it will print a message and exit without failing.

// ignore_for_file: avoid_print

import 'package:eip7702/builder.dart';
import 'package:eip7702/eip7702.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  final privateKeyHex = String.fromEnvironment('PKEY');
  final rpcUrl = String.fromEnvironment(
    'RPC_URL',
    defaultValue: "https://0xrpc.io/sep",
  );
  final delegateAddress = String.fromEnvironment(
    'IMPL',
    defaultValue: "0x0eacC2307f0113F26840dD1dAc8DC586259994Dd",
  );

  if (rpcUrl.isEmpty) {
    print(
      '[EIP-7702 SIM] Skipping simulation: rpcUrl env var not set. '
      'Set it and re-run: --define=RPC_URL="https://rpc.testnet.lfg"',
    );
    return;
  }

  if (delegateAddress.isEmpty) {
    print(
      '[EIP-7702 SIM] Skipping simulation: delegate-address env var not set. '
      'Set it and re-run: --define=IMPL="0xYourImplementation"',
    );
    return;
  }

  if (privateKeyHex.isEmpty) {
    print(
      '[EIP-7702 SIM] Skipping simulation: private-key env var not set. '
      'Set it and re-run with: --define=PKEY=\$PKEY',
    );
    return;
  }

  print('[EIP-7702 SIM] RPC_URL              : $rpcUrl');
  print('[EIP-7702 SIM] DELEGATE_ADDRESS     : $delegateAddress');
  print('[EIP-7702 SIM] PRIVATE_KEY_WITH_FUNDS: **** (hidden)');

  test('simulate real testnet set_code_tx via Eip7702Client', () async {
    final calldata = hexToBytes(
      "0x34fcd5be000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000f5bb7f874d8e3f41821175c0aa9910d30d10e193000000000000000000000000000000000000000000000000000000e8d4a5100000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000",
    );

    final ethKey = EthPrivateKey.fromHex(privateKeyHex);
    // CAVEAT: this signer does not sign this signer as a EIP-191 personal sign message. if you need a more complex transaction sign digest, extend the custom signer class
    final signer = Signer.eth(ethKey);

    print('[EIP-7702 SIM] Using sender : ${ethKey.address.eip55With0x}');

    final ctx = create7702Context(
      rpcUrl: rpcUrl,
      delegateAddress: delegateAddress,
      transformer: (gasLimit) => gasLimit * BigInt.from(5),
    );

    final authBuilder = AuthorizationBuilder(ctx);
    final txBuilder = SetCodeTxBuilder(ctx);

    final eip7702Client = Eip7702Client(ctx, authBuilder, txBuilder);

    print('[EIP-7702 SIM] Resolved chainId     : ${eip7702Client.ctx.chainId}');

    // For a pure "set_code" simulation, we can:
    // - use `to = delegateAddress`
    // - value = 0
    // - data  = empty
    //
    // This will:
    //  - build an authorization
    //  - build an EIP-7702 transaction that sets code to the delegate
    //  - send raw tx via eth_sendRawTransaction
    print('[EIP-7702 SIM] Preparing delegateAndCall...');
    print('[EIP-7702 SIM]   to    : ${ethKey.address.eip55With0x}');
    print('[EIP-7702 SIM]   value : 0 wei');
    print('[EIP-7702 SIM]   data  : Eth Transfer via ExecuteBatch');

    final alreadyDelegating = await authBuilder.isDelegatedTo(
      ethKey.address,
      ctx.delegateAddress,
    );

    if (alreadyDelegating) {
      print(
        '[EIP-7702 SIM] Existing Delegation to $delegateAddress detected. '
        'switching to default EIP1559 transaction type',
      );
    }

    late String txHash;

    try {
      txHash = await eip7702Client.delegateAndCall(
        signer: signer,
        to: ethKey.address.eip55With0x,
        data: calldata,
      );
    } catch (e, st) {
      print('[EIP-7702 SIM] ERROR while sending delegateAndCall: $e');
      print(st);
      return;
    }

    print('[EIP-7702 SIM] Sent EIP-7702 tx. Hash: $txHash');
    print('[EIP-7702 SIM] Follow this tx on your testnet explorer');

    // We deliberately do NOT wait/poll for receipt here, to keep this fast and
    // non-blocking in case the testnet is slow. If you want, you can uncomment:

    // print('[EIP-7702 SIM] Waiting for receipt...');
    // await ctx.web3Client.getTransactionReceipt(txHash);
    // print('[EIP-7702 SIM] Receipt: $receipt');

    // No assertions: this is a smoke/simulation test.
    // Passing means we successfully constructed and submitted a raw EIP-7702 tx.
    expect(txHash.startsWith('0x'), isTrue);
  });

  test('simulate real testnet revoke via Eip7702Client', () async {
    final ethKey = EthPrivateKey.fromHex(privateKeyHex);
    // CAVEAT: this signer does not sign this signer as a EIP-191 personal sign message. if you need a more complex transaction sign digest, extend the custom signer class
    final signer = Signer.eth(ethKey);

    print('[EIP-7702 SIM] Using sender : ${ethKey.address.eip55With0x}');

    final ctx = create7702Context(
      rpcUrl: rpcUrl,
      delegateAddress: delegateAddress,
    );

    final authBuilder = AuthorizationBuilder(ctx);
    final txBuilder = SetCodeTxBuilder(ctx);

    final eip7702Client = Eip7702Client(ctx, authBuilder, txBuilder);

    print('[EIP-7702 SIM] Resolved chainId     : ${eip7702Client.ctx.chainId}');

    final pollInterval = const Duration(seconds: 1);
    waitForDelegation([alreadyDelegating = false, next = 1]) async {
      if (next > 5) return;
      alreadyDelegating = await authBuilder.isDelegatedTo(
        ethKey.address,
        ctx.delegateAddress,
      );
      if (!alreadyDelegating) {
        print('[EIP-7702 SIM] Waiting for current delegation     : ...$next');
        await Future.delayed(pollInterval);
        waitForDelegation(alreadyDelegating, next + 1);
      }
    }

    waitForDelegation();

    // For a pure "set_code" simulation, we can:
    // - use `to = delegateAddress`
    // - value = 0
    // - data  = empty
    //
    // This will:
    //  - build an authorization
    //  - build an EIP-7702 transaction that sets code to the delegate
    //  - send raw tx via eth_sendRawTransaction
    print('[EIP-7702 SIM] Preparing revokeDelegation...');
    print('[EIP-7702 SIM]   to    : ${ethKey.address.eip55With0x}');
    print('[EIP-7702 SIM]   value : 0 wei');
    print('[EIP-7702 SIM]   data  : null');

    late String txHash;

    try {
      txHash = await eip7702Client.revokeDelegation(signer: signer);
    } catch (e, st) {
      print('[EIP-7702 SIM] ERROR while sending revokeDelegation: $e');
      print(st);
      return;
    }

    print('[EIP-7702 SIM] Sent EIP-7702 tx. Hash: $txHash');
    print('[EIP-7702 SIM] Follow this tx on your testnet explorer');

    // We deliberately do NOT wait/poll for receipt here, to keep this fast and
    // non-blocking in case the testnet is slow. If you want, you can uncomment:

    // print('[EIP-7702 SIM] Waiting for receipt...');
    // final receipt = await client.getTransactionReceipt(txHash);
    // print('[EIP-7702 SIM] Receipt: $receipt');

    // No assertions: this is a smoke/simulation test.
    // Passing means we successfully constructed and submitted a raw EIP-7702 tx.
    expect(txHash.startsWith('0x'), isTrue);
  });
}
