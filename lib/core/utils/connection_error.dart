/// Errores de red/conectividad que conviene mostrar con un mensaje amigable.
bool isConnectionError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('socketexception') ||
      message.contains('clientexception') ||
      message.contains('connection reset') ||
      message.contains('connection refused') ||
      message.contains('connection closed') ||
      message.contains('connection timed out') ||
      message.contains('failed host lookup') ||
      message.contains('network is unreachable') ||
      message.contains('handshakeexception') ||
      message.contains('timed out') ||
      message.contains('no address associated with hostname');
}
