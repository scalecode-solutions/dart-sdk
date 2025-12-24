class DeleteTransactionRange {
  final int? hi;
  final int? low;

  DeleteTransactionRange({this.hi, this.low});

  static DeleteTransactionRange fromMessage(Map<String, dynamic> msg) {
    return DeleteTransactionRange(
      low: msg['low'] as int?,
      hi: msg['hi'] as int?,
    );
  }
}

class DeleteTransaction {
  /// Id of the latest applicable 'delete' transaction
  final int? clear;

  /// Ranges of Ids of deleted messages
  final List<DeleteTransactionRange>? delseq;

  DeleteTransaction({this.clear, this.delseq});

  static DeleteTransaction fromMessage(Map<String, dynamic> msg) {
    final delseqList = msg['delseq'] as List<dynamic>?;
    return DeleteTransaction(
      clear: msg['clear'] as int?,
      delseq:
          delseqList != null ? delseqList.map((del) => DeleteTransactionRange.fromMessage(del as Map<String, dynamic>)).toList() : [],
    );
  }
}
