import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreStatusHelper {
  static StreamController<DocumentSnapshot>? _controller;
  static StreamSubscription<DocumentSnapshot>? _subscription;
  static DocumentSnapshot? _lastSnapshot;

  static Stream<DocumentSnapshot> get stream {
    if (_controller == null) {
      _controller = StreamController<DocumentSnapshot>.broadcast(
        onListen: () {
          // If we already have a last snapshot, immediately deliver it to new listeners
          if (_lastSnapshot != null) {
            _controller?.add(_lastSnapshot!);
          }
          
          _subscription ??= FirebaseFirestore.instance
              .collection('settings')
              .doc('store')
              .snapshots()
              .listen(
                (snapshot) {
                  _lastSnapshot = snapshot;
                  _controller?.add(snapshot);
                },
                onError: (error) {
                  _controller?.addError(error);
                },
              );
        },
        onCancel: () {
          // Keep the Firestore subscription alive to prevent the JS SDK watch-stream
          // teardown/assertion crash (ID: ca9 / b815).
        },
      );
    }
    return _controller!.stream;
  }
}
