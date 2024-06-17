import 'dart:math';
import 'dart:typed_data';

class VarInt {
  // See RFC 9000 section 16
  late int msb;
  late Uint8List data;

  VarInt.fromInt(int initial, {int msbOverride = -1}) {
    msb = msbOverride == -1 ? getSmallestEncodingMSB(initial) : msbOverride;
    switch (msb) {
      case 0: // 6-bit integer
        data = Uint8List(1);
        break;
      case 1: // 14-bit integer
        data = Uint8List(2);
        break;
      case 2: // 30-bit integer
        data = Uint8List(4);
        break;
      case 3: // 62-bit integer
        data = Uint8List(8);
        break;
      default:
        throw 'Invalid MSB return. Number too big? Negative?';
    }

    // Calculate bits
    int power = 8 * data.length - 3;
    for (int i = 0; i < data.length; i++) {
      int restrictedNumRep = 0;
      for (int n = (i == 0 ? 5 : 7); n >= 0; n--) {
        // The weird tertiary operator above ensures the first two MSBs stay
        // open for the encoding described in RFC 9000 section 16.
        int place = pow(2, power) as int;
        if (initial / place >= 1) {
          initial -= place;
          restrictedNumRep += pow(2, n) as int;
        }
        data[i] = restrictedNumRep;
        power--;
      }
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
