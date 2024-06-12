import 'dart:typed_data';

class VarInt {
  // See RFC 9000 section 16
  late int msb;
  late Uint8List data;

  VarInt.fromInt(int initial, {int msbOverride = -1}) {
    msb = msbOverride == -1 ? getSmallestEncodingMSB(initial) : msbOverride;
    switch (msb) {
      case 0:
        data = Uint8List(1);
        break;
      case 1:
        data = Uint8List(2);
        break;
      case 2:
        data = Uint8List(4);
        break;
      case 3:
        data = Uint8List(8);
        break;
      default:
        throw 'Invalid MSB return. Number too big? Negative?';
    }
  }

  static int getSmallestEncodingMSB(int value) {
    if (value < 0) {
      return -1;
    } else if (value < 64) {
      return 0; // 00
    } else if (value < 16384) {
      return 1; // 01
    } else if (value < 1073741824) {
      return 2; // 10
    } else if (value < 4611686018427387904) {
      return 3; // 11
    }
    return -1;
  }
}
