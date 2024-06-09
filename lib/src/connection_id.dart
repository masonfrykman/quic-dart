import 'dart:math';
import 'dart:typed_data';

class QUICConnectionId {
  QUICConnectionIdType type;
  int sequence;
  Uint8List statelessResetToken = Uint8List(16);

  bool get statelessResetTokenIsCorrectLength =>
      statelessResetToken.lengthInBytes == 16;

  QUICConnectionId(this.type, this.sequence, this.statelessResetToken) {
    checkResetToken();
  }

  QUICConnectionId.randomResetToken(this.type, this.sequence) {
    for (int i = 0; i < 16; i++) {
      statelessResetToken[i] = Random().nextInt(256);
    }
  }

  int checkResetToken() {
    if (statelessResetToken.lengthInBytes == 16) {
      return 0;
    }

    int returnCounter = 0;
    if (statelessResetToken.lengthInBytes < 16) {
      // TODO: If another method of generating a token is added, this needs to be updated.
      for (int i = statelessResetToken.lengthInBytes; i < 16; i++) {
        statelessResetToken[i] = Random().nextInt(256);
        returnCounter++;
      }
    } else if (statelessResetToken.lengthInBytes > 16) {
      returnCounter = 16 - statelessResetToken.lengthInBytes;
      statelessResetToken.removeRange(16, statelessResetToken.length);
    }
    return returnCounter;
  }
}

enum QUICConnectionIdType { source, destination }
