/// Status not assigned
const int statusNone = 0;

/// Local ID assigned, in progress to be sent.
const int statusQueued = 1;

/// Transmission started.
const int statusSending = 2;

/// At least one attempt was made to send the message.
const int statusFailed = 3;

/// Delivered to the server.
const int statusSent = 4;

/// Received by the client.
const int statusReceived = 5;

/// Read by the user.
const int statusRead = 6;

/// Message from another user.
const int statusToMe = 7;
