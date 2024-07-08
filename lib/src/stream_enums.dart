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
