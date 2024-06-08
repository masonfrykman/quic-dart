class QUICConnectionId {
  QUICConnectionIdType type;
  int sequence;
  List<int> statelessResetToken;

  QUICConnectionId(this.type, this.sequence, this.statelessResetToken);
}

enum QUICConnectionIdType { source, destination }
