part of '../eip7702.dart';

typedef HexString = String;

///    Build the digest to be signed for a 7702 tx.
///    This is ( 0x04 || rlp(bodyWithoutSig) ) underneath,
///    since `getUnsignedSerialized` already prefixes type 0x04.
Uint8List createTxPreImage(Unsigned7702Tx tx, {int? chainId}) {
  final unsignedTx = tx.getUnsignedSerialized(chainId: chainId);
  return unsignedTx;
}

///    Sign an Unsigned7702Tx with a Signer (raw or EthPrivateKey)
///    keccak256(preimage) -> sign
///    and return the Signed7702Tx tuple.
Signed7702Tx signTransaction(Signer signer, Unsigned7702Tx tx, {int? chainId}) {
  final preImage = createTxPreImage(tx, chainId: chainId);
  final signature = signer.sign(preImage);
  return (signature: signature, tx: tx);
}

///    Turn a Signed7702Tx into the raw hex string you send to RPC:
///    `eth_sendRawTransaction([ rawHex ])`
HexString parseRawTransaction(Signed7702Tx tx, {int? chainId}) {
  final rawBytes = tx.getSignedSerialized(chainId: chainId);
  return bytesToHex(rawBytes, include0x: true, padToEvenLength: true);
}
