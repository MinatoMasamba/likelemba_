// lib/core/network/connectivity_monitor.dart

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// 📶 Moniteur de connectivité réseau pour le mode Offline-First.
///
/// Fournit un [Stream] continu de l'état de connexion internet.
/// Utilisé pour déclencher la synchronisation automatique de l'Outbox
/// lorsque l'appareil repasse en ligne.
///
/// **Important :** Le [ConnectivityResult] ne garantit pas un accès effectif à Internet.
/// Pour une vérification plus fiable, utiliser [hasActualInternetConnection] en complément.
class ConnectivityMonitor {
  static const String tag = 'ConnectivityMonitor';

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  /// Stream exposant l'état de connexion (true = en ligne, false = hors ligne).
  Stream<bool> get onConnectivityChanged => _connectionStatusController.stream;

  /// État actuel de la connexion (optionnel, via getter asynchrone).
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  /// Initialise l'écoute des changements de connectivité.
  void initialize() {
    print('$tag.initialize - Démarrage de la surveillance réseau.');
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _isOnline(results);
      print('$tag.initialize - État réseau : ${online ? "En ligne" : "Hors ligne"}');
      _connectionStatusController.add(online);
    });

    // Vérification initiale
    _connectivity.checkConnectivity().then((results) {
      final online = _isOnline(results);
      print('$tag.initialize - État initial : ${online ? "En ligne" : "Hors ligne"}');
      _connectionStatusController.add(online);
    });
  }

  /// Libère les ressources (à appeler dans `dispose`).
  void dispose() {
    print('$tag.dispose - Arrêt de la surveillance réseau.');
    _subscription?.cancel();
    _connectionStatusController.close();
  }

  /// Vérifie si l'appareil a un accès effectif à Internet.
  /// (Ping vers un serveur fiable)
  Future<bool> hasActualInternetConnection() async {
    const method = 'hasActualInternetConnection';
    try {
      // Exemple : lookup Google DNS
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('$tag.$method - ✅ Connexion internet effective.');
        return true;
      }
    } on SocketException catch (_) {
      print('$tag.$method - ❌ Pas d\'accès internet (SocketException).');
    } catch (e) {
      print('$tag.$method - ❌ Erreur lors du lookup : $e');
    }
    return false;
  }

  // Helper pour convertir ConnectivityResult en bool
  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);
  }
}