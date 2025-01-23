import 'package:eth_sig_util/model/typed_data.dart';
import 'package:rly_network_flutter_sdk/src/gsn/utils.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import '../wallet.dart' as rly_wallet;
import 'eip_712_transaction.dart';

// The public rlp package does not work with zksync specific chains.
// For now we are importing a version that does work directly from the source of web3dart.
// If this changes in the future will be bring the correct encoding inhouse
// ignore: implementation_imports
import 'package:web3dart/src/utils/rlp.dart' as rlp;

class ZKSyncChain {
  // The RPC URL of the node you are accessing for the given ZKSync chain.
  final String rpcUrl;

  /// ZKSync bakes 712 support in at the protocol level.
  /// Therefore, these values should be defined at the chain level.
  /// This ensures that the necessary parameters are correctly set
  /// and managed within the blockchain network, providing a seamless
  /// and efficient integration of the 712 standard.
  final EIP712Domain eip712domain;

  ZKSyncChain({required this.rpcUrl, required this.eip712domain});

  Future<String> sendTransaction(
      ZKSyncEip712Transaction transaction, rly_wallet.Wallet wallet) async {
    final eip712Data = {
      'domain': eip712domain.toJson(),
      'types': ZKSyncEip712Transaction.types,
      'primaryType': ZKSyncEip712Transaction.primaryType,
      'message': transaction.toMap(),
    };

    final String customSignature = wallet.signTypedData(eip712Data);
    final serializedTx = transaction.toList(customSignature);
    final rawTx = hexToUint8List(
        concatHex(["0x71", bytesToHex(rlp.encode(serializedTx))]));
    Web3Client client = getEthClient(rpcUrl);

    final String hash = await client.sendRawTransaction(rawTx);

    return hash;
  }
}
