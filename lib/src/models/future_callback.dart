import 'dart:async';

class FutureCallback {
  final DateTime? ts;
  final Completer<dynamic>? completer;

  FutureCallback({this.ts, this.completer});
}
