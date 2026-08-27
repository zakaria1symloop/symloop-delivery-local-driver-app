import 'package:flutter/foundation.dart';
import '../models/package.dart';
import '../services/package_service.dart';
import '../services/api_service.dart';

class PackageProvider with ChangeNotifier {
  // Package lists by status
  List<Package> _toPickup = [];      // en_ramassage, not yet collected
  List<Package> _inPossession = [];  // en_ramassage, driver_collected_at set
  List<Package> _toDeliver = [];
  List<Package> _delivered = [];
  List<Package> _failed = [];

  // Loading states
  bool _isLoading = false;
  bool _isLoadingToPickup = false;
  bool _isLoadingToDeliver = false;
  bool _isLoadingDelivered = false;
  bool _isLoadingFailed = false;

  // Error state
  String? _error;

  // Getters
  List<Package> get toPickup => _toPickup;
  List<Package> get inPossession => _inPossession;
  List<Package> get toDeliver => _toDeliver;
  List<Package> get delivered => _delivered;
  List<Package> get failed => _failed;
  bool get isLoading => _isLoading;
  bool get isLoadingToPickup => _isLoadingToPickup;
  bool get isLoadingToDeliver => _isLoadingToDeliver;
  bool get isLoadingDelivered => _isLoadingDelivered;
  bool get isLoadingFailed => _isLoadingFailed;
  String? get error => _error;

  // Stats
  int get toPickupCount => _toPickup.length;
  int get inPossessionCount => _inPossession.length;
  int get toDeliverCount => _toDeliver.length;
  int get deliveredCount => _delivered.length;
  int get failedCount => _failed.length;
  int get totalCount => toDeliverCount + deliveredCount + failedCount;

  double get totalCollected {
    double total = 0;
    for (final p in _delivered) {
      total += p.totalToCollect;
    }
    return total;
  }

  double get deliveryRate {
    final handled = deliveredCount + failedCount;
    if (handled == 0) return 100.0;
    return (deliveredCount / handled) * 100;
  }

  /// Load all package data for a driver
  Future<void> loadAllData(int driverId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchToPickup(driverId),
        fetchToDeliver(driverId),
        fetchDelivered(driverId),
        fetchFailed(driverId),
      ]);
    } catch (e) {
      _error = 'Erreur de chargement des donnees';
      debugPrint('[PACKAGES] loadAllData error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch packages to pickup (en_ramassage) — split into not collected vs in possession
  Future<void> fetchToPickup(int driverId) async {
    _isLoadingToPickup = true;
    notifyListeners();
    try {
      final data = await PackageService.getDriverPackages(driverId, status: 'en_ramassage');
      final all = data.map((json) => Package.fromJson(json)).toList();
      _toPickup = all.where((p) => p.driverCollectedAt == null).toList();
      _inPossession = all.where((p) => p.driverCollectedAt != null).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erreur chargement ramassage';
    }
    _isLoadingToPickup = false;
    notifyListeners();
  }

  /// Fetch packages to deliver (en_cours_livraison)
  Future<void> fetchToDeliver(int driverId) async {
    _isLoadingToDeliver = true;
    notifyListeners();

    try {
      final data = await PackageService.getPackagesToDeliver(driverId);
      _toDeliver = data.map((json) => Package.fromJson(json)).toList();
      debugPrint('[PACKAGES] To deliver: ${_toDeliver.length}');
    } on ApiException catch (e) {
      _error = e.message;
      debugPrint('[PACKAGES] fetchToDeliver API error: ${e.message}');
    } catch (e) {
      _error = 'Erreur de chargement des colis a livrer';
      debugPrint('[PACKAGES] fetchToDeliver error: $e');
    }

    _isLoadingToDeliver = false;
    notifyListeners();
  }

  /// Fetch delivered packages (livre) for today
  Future<void> fetchDelivered(int driverId) async {
    _isLoadingDelivered = true;
    notifyListeners();

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final data = await PackageService.getDeliveredPackages(
        driverId,
        dateFrom: today,
      );
      _delivered = data.map((json) => Package.fromJson(json)).toList();
      debugPrint('[PACKAGES] Delivered today: ${_delivered.length}');
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erreur de chargement des colis livres';
    }

    _isLoadingDelivered = false;
    notifyListeners();
  }

  /// Fetch failed packages (echec_livraison)
  Future<void> fetchFailed(int driverId) async {
    _isLoadingFailed = true;
    notifyListeners();

    try {
      final data = await PackageService.getFailedPackages(driverId);
      _failed = data.map((json) => Package.fromJson(json)).toList();
      debugPrint('[PACKAGES] Failed: ${_failed.length}');
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erreur de chargement des echecs';
    }

    _isLoadingFailed = false;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh(int driverId) async {
    await loadAllData(driverId);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Mark package as delivered — phone verification required
  Future<Map<String, dynamic>> deliverPackage(int packageId, String recipientPhone, int driverId) async {
    try {
      final res = await PackageService.deliverPackage(packageId, recipientPhone);
      if (res['success'] == true) {
        await loadAllData(driverId); // refresh lists
      }
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Mark package as échec with reason
  Future<Map<String, dynamic>> failPackage(int packageId, String reason, int driverId) async {
    try {
      final res = await PackageService.failPackage(packageId, reason);
      if (res['success'] == true) {
        await loadAllData(driverId); // refresh lists
      }
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Record call attempt
  Future<Map<String, dynamic>> recordCall(int packageId, String outcome, {String? notes}) async {
    try {
      final res = await PackageService.recordCall(packageId, outcome, notes: notes);
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Clear all data (on logout)
  void clear() {
    _toPickup = [];
    _inPossession = [];
    _toDeliver = [];
    _delivered = [];
    _failed = [];
    _error = null;
    notifyListeners();
  }
}
