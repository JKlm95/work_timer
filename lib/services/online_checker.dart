import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstrakcja pod testy ([WorkRepository]) i produkcję ([ConnectivityOnlineChecker]).
abstract class OnlineChecker {
  Future<bool> check();
}

class ConnectivityOnlineChecker implements OnlineChecker {
  ConnectivityOnlineChecker([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> check() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}
