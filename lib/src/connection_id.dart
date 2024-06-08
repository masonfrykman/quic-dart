import 'dart:math';
import 'dart:typed_data';

class QUICConnectionId {
  QUICConnectionIdType type;
  int sequence;
  Uint8List statelessResetToken = Uint8List(16);

  bool get statelessResetTokenIsCorrectLength =>
      statelessResetToken.lengthInBytes == 16;

  QUICConnectionId(this.type, this.sequence, this.statelessResetToken);

  QUICConnectionId.randomResetToken(this.type, this.sequence) {
    for (int i = 0; i < 16; i++) {
      statelessResetToken[i] = Random().nextInt(256);
    }
  }
}

enum QUICConnectionIdType { source, destination }
