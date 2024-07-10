enum StreamInitiator { client, server }

enum StreamDirection { unidirectional, bidirectional }

enum SendStreamState {
  ready, // Stream is ready to send
  sending, // The data is being sent
  sentFin, // All the data has been sent out at least once
  allDataRecieved, // All the data has been acknowledged as being recieved
  sentReset, // We sent a reset
  resetRecieved // The other endpoint acknowledged our reset
}

enum RecvStreamState {
  recieve, // Recieving data
  sizeKnown, // Has recieved the data, the final size is known, if we missed data it will need to be retransmitted.
  recievedAll, // All data has been recieved
  recievedReset // Recieved a reset (error occured!)
}

enum StreamPriority { low, normal, high, critical }
