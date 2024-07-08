import 'dart:typed_data';

import 'variable_length_int.dart';
import 'stream_enums.dart';

class QUICStream {
  VarInt? id;
  StreamInitiator initiator;
  StreamDirection direction;

  SendStreamState? sendState;
  RecvStreamState? recvState;

  StreamPriority priority;

  final List<int> _dataRecieved = [];
  List<int>? get dataRecieved =>
      recvState == RecvStreamState.recievedAll ? _dataRecieved : null;

  QUICStream(this.direction, this.initiator,
      {this.sendState, this.recvState, this.id, required this.priority});

  void recieve(Uint8List data, VarInt offset) {
    if (data.isEmpty) return;

    // TODO: Restrict this function by the recvState

    int offsetInt = offset.toInt();
    if (offsetInt + data.length > _dataRecieved.length) {
      _dataRecieved.addAll(List.filled(
          (_dataRecieved.length - data.length - offsetInt) * -1, 0));
    }

    _dataRecieved.replaceRange(offsetInt, offsetInt + data.length, data);
  }
}
