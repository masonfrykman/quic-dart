import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class UDPEndpoint {
  // Controlled by the class.
  RawDatagramSocket? _bindedSocket;
  StreamSubscription<RawSocketEvent>? _connectionListener;
  UDPEndpointDelegate? delegate;

  List<(Uint8List data, dynamic host, int port)> _writeQueue = [];

  // Provided by constructor.
  dynamic _host;
  int _port;

  // ********************
  // * Host & Port mgmt *
  // ********************

  dynamic get host => _host;
  int get port => _port;

  Future<void> setHost(dynamic newValue, {bool restartListening = true}) async {
    await stopListening();
    _host = newValue;
    if(restartListening) {
      await startListening();
    }
  }

  Future<void> setPort(int newValue, {bool restartListening = true}) async {
    await stopListening();
    _port = newValue;
    if(restartListening) {
      await startListening();
    }
  }

  UDPEndpoint(this._host, this._port);

  // ************************
  // * Socket listener mgmt *
  // ************************

  Future<void> startListening() async {
    _bindedSocket = await RawDatagramSocket.bind(_host, _port);
    _connectionListener = _bindedSocket!.listen((event) => _eventProcessor(event), onDone: () async => await stopListening());
  }

  void _eventProcessor(RawSocketEvent event) {
    switch(event) {
      case RawSocketEvent.read:
        Datagram? packet = _bindedSocket!.receive();
        if(packet == null) break;

        delegate?.endpointRecievedData(this, packet);
        break;
      case RawSocketEvent.write:
        if(_bindedSocket == null || _writeQueue.isEmpty) {
          break;
        }

        var sendCall = _bindedSocket!.send(_writeQueue.first.$1, _writeQueue.first.$2, _writeQueue.first.$3);
        if(sendCall > 0) { // Success
          _writeQueue.removeAt(0);
        }

        if(_writeQueue.isNotEmpty) {
          _bindedSocket!.writeEventsEnabled = true;
        }
        break;
      default:
        break;
    }
  }

  Future<bool> stopListening() async {
    bool wasListening = false;
    if(_connectionListener != null) {
      await _connectionListener!.cancel();
      _connectionListener = null;
      wasListening = true;
    }
    if(_bindedSocket != null) {
      _bindedSocket!.close();
      _bindedSocket = null;
      wasListening = true;
    }
    return wasListening;
  }

  void write(Uint8List data, dynamic to, int toPort) {
    _writeQueue.add((data, to, toPort));
    if(_bindedSocket != null) {
      _bindedSocket!.writeEventsEnabled = true;
    }
  }
  
}

mixin UDPEndpointDelegate {
  void endpointRecievedData(UDPEndpoint endpoint, Datagram data);
}