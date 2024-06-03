import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class UDPEndpoint {
  // Controlled by the class.
  RawDatagramSocket? _bindedSocket;
  StreamSubscription<RawSocketEvent>? _connectionListener;

  List<(Uint8List data, dynamic host, int port)> _writeQueue = [];
  int _writeFailures = 0;

  // Provided by constructor.
  dynamic _host;
  int _port;

  /// The delegate of the endpoint. The listener will use these methods to inform of incoming data ([UDPEndpointDelegate.endpointRecievedData]) and write failures ([UDPEndpointDelegate.endpointFailedToSend]).
  UDPEndpointDelegate? delegate;

  // ********************
  // * Host & Port mgmt *
  // ********************

  /// Host that is used to bind the socket. Use [setHost] to set this parameter after construction.
  dynamic get host => _host;

  /// Port that is used to bind the socket. Use [setPort] to set this parameter after construction.
  int get port => _port;

  /// Sets the host that's binded to.  This will cause the listener and socket to close.
  ///
  /// If [restartListening] is set to true, it will call [bind] and [startListening]. Otherwise, it will leave the socket open and [bind] must be called seperately.
  Future<void> setHost(dynamic newValue, {bool restartListening = true}) async {
    await stopListening();
    await unbind();
    _host = newValue;
    if (restartListening) {
      await startListening();
    }
  }

  /// Sets the port that's binded to. This will cause the listener and socket to close.
  ///
  /// If [restartListening] is set to true, it will call [bind] and [startListening]. Otherwise, it will leave the socket open and [bind] must be called seperately.
  Future<void> setPort(int newValue, {bool restartListening = true}) async {
    await stopListening();
    await unbind();
    _port = newValue;
    if (restartListening) {
      await startListening();
    }
  }

  UDPEndpoint(this._host, this._port);

  // ******************
  // * Socket binding *
  // ******************

  /// Whether the socket is binded to. Use [bind] to bind the socket to the [host] and [port].
  bool get isBinded => _bindedSocket != null;

  /// Binds to the socket using [host] and [port].
  Future<void> bind() async {
    if (_bindedSocket != null) {
      return;
    }
    _bindedSocket = await RawDatagramSocket.bind(_host, _port);
  }

  /// Unbinds the socket. The listener will be canceled via [stopListening], if it exists.
  Future<bool> unbind() async {
    await stopListening();
    if (_bindedSocket != null) {
      _bindedSocket!.close();
      _bindedSocket = null;
      return true;
    }
    return false;
  }

  // ************************
  // * Socket listener mgmt *
  // ************************

  bool get isListening => _connectionListener != null;

  /// Starts listening to the binded socket.
  ///
  /// If the socket is not binded, it will attempt to bind.
  ///
  /// Passes any datagrams recieved to [delegate] using the [UDPEndpointDelegate.endpointRecievedData] method. Otherwise, data is practically thrown away.
  /// To send data, use the [write] method. Any datagrams that can't be sent (fail 3 times) will be sent back to the [delegate] using the [UDPEndpointDelegate.endpointFailedToSend] method.
  Future<void> startListening() async {
    await bind();
    _connectionListener = _bindedSocket!.listen(
        (event) => _eventProcessor(event),
        onDone: () async => await stopListening());

    if (_writeQueue.isNotEmpty) {
      _bindedSocket!.writeEventsEnabled =
          true; // Ensure data starts getting sent.
    }
  }

  void _eventProcessor(RawSocketEvent event) {
    switch (event) {
      case RawSocketEvent.read:
        if (!isBinded) break;
        Datagram? packet = _bindedSocket!.receive();
        if (packet == null) break;

        delegate?.endpointRecievedData(this, packet);
        break;
      case RawSocketEvent.write:
        if (!isBinded || _writeQueue.isEmpty) break;

        if (_writeFailures >= 3) {
          delegate?.endpointFailedToSend(this, _writeQueue.first);
          _writeQueue.removeAt(0);
          _writeFailures = 0;
        }

        var sendCall = _bindedSocket!.send(
            _writeQueue.first.$1, _writeQueue.first.$2, _writeQueue.first.$3);
        if (sendCall > 0) {
          // Success
          _writeQueue.removeAt(0);
          _writeFailures = 0;
        } else {
          // Failure, retry. (up to 3 times)
          _writeFailures++;
        }

        if (_writeQueue.isNotEmpty) {
          _bindedSocket!.writeEventsEnabled = true;
        }
        break;
      default:
        break;
    }
  }

  /// Closes the listener, if it exists.
  Future<bool> stopListening() async {
    if (isListening) {
      await _connectionListener!.cancel();
      _connectionListener = null;
      return true;
    }
    return false;
  }

  /// Sends a datagram of data to a host and port.
  ///
  /// The parameters are added to a queue that is sent on a first come, first serve basis as [RawSocketEvent.write] events are fired on the listener.
  ///
  /// If [isListening] is false, the data will not be sent until the listener starts.
  void write(Uint8List data, dynamic to, int toPort) {
    _writeQueue.add((data, to, toPort));
    if (isBinded) {
      _bindedSocket!.writeEventsEnabled = true;
    }
  }
}

mixin UDPEndpointDelegate {
  void endpointRecievedData(UDPEndpoint endpoint, Datagram data);
  void endpointFailedToSend(UDPEndpoint endpoint,
      (Uint8List data, dynamic host, int port) problematicParameters);
}
