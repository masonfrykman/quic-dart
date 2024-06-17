import 'dart:typed_data';

import 'package:quic/src/variable_length_int.dart';

class QUICStream {
  VarInt? id;

  StreamInitiator initiator;
  StreamDirection direction;

  SendStreamState? sendState;
  RecvStreamState? recvState;

  StreamPriority priority;
}

enum StreamInitiator { client, server }

enum StreamDirection { unidirectional, bidirectional }

enum SendStreamState {
  ready,
  sending,
  sentFin,
  allDataRecieved,
  sentReset,
  resetRecieved
}

enum RecvStreamState {
  recieve,
  sizeKnown,
  recievedAll,
  recievedReset,
  appReadAllData,
  appReadReset
}

enum StreamPriority { low, normal, high, critical }
