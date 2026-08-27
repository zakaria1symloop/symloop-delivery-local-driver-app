import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class PackageService {
  /// Fetch packages for a driver filtered by status
  /// status: en_cours_livraison, livre, echec_livraison
  static Future<List<dynamic>> getDriverPackages(
    int driverId, {
    String? status,
    String? dateFrom,
    String? dateTo,
    int? page,
    int? perPage,
  }) async {
    String endpoint = ApiConfig.driverPackages(driverId);
    final params = <String>[];

    if (status != null) params.add('status=$status');
    if (dateFrom != null) params.add('date_from=$dateFrom');
    if (dateTo != null) params.add('date_to=$dateTo');
    if (page != null) params.add('page=$page');
    if (perPage != null) params.add('per_page=$perPage');

    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }

    debugPrint('[PACKAGES] GET $endpoint');

    try {
      final response = await ApiService.get(endpoint);
      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> packages;

        if (data is List) {
          packages = data;
        } else if (data is Map && data['data'] != null) {
          // Paginated response: { data: { data: [...], meta: {...} } }
          packages = data['data'] as List<dynamic>;
        } else {
          packages = [];
        }

        debugPrint('[PACKAGES] Found ${packages.length} packages (status=$status)');
        return packages;
      }

      debugPrint('[PACKAGES] Response success=false');
      return [];
    } on ApiException catch (e) {
      debugPrint('[PACKAGES] ERROR: ${e.statusCode} - ${e.message}');
      rethrow;
    }
  }

  /// Get packages to deliver (en_cours_livraison)
  static Future<List<dynamic>> getPackagesToDeliver(int driverId) async {
    return getDriverPackages(driverId, status: 'en_cours_livraison');
  }

  /// Get delivered packages (livre)
  static Future<List<dynamic>> getDeliveredPackages(
    int driverId, {
    String? dateFrom,
  }) async {
    return getDriverPackages(driverId, status: 'livre', dateFrom: dateFrom);
  }

  /// Get failed delivery packages (echec_livraison)
  static Future<List<dynamic>> getFailedPackages(int driverId) async {
    return getDriverPackages(driverId, status: 'echec_livraison');
  }

  /// Get today's packages for all terminal statuses (delivered + failed)
  static Future<Map<String, List<dynamic>>> getTodayHistory(int driverId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final results = await Future.wait([
      getDriverPackages(driverId, status: 'livre', dateFrom: today),
      getDriverPackages(driverId, status: 'echec_livraison', dateFrom: today),
    ]);

    return {
      'delivered': results[0],
      'failed': results[1],
    };
  }

  /// Mark package as delivered (livré) — requires phone verification
  static Future<Map<String, dynamic>> deliverPackage(int packageId, String recipientPhone) async {
    return await ApiService.post(ApiConfig.driverDeliver, body: {
      'package_id': packageId,
      'recipient_phone': recipientPhone,
    });
  }

  /// Mark package as failed (échec) — requires reason
  static Future<Map<String, dynamic>> failPackage(int packageId, String echecReason) async {
    return await ApiService.post(ApiConfig.driverFail, body: {
      'package_id': packageId,
      'echec_reason': echecReason,
    });
  }

  /// Record a call attempt
  static Future<Map<String, dynamic>> recordCall(int packageId, String outcome, {String? notes}) async {
    final data = <String, dynamic>{
      'package_id': packageId,
      'outcome': outcome,
    };
    if (notes != null) data['notes'] = notes;
    return await ApiService.post(ApiConfig.driverRecordCall, body: data);
  }

  /// Mark pickup package as physically collected by driver (stays en_ramassage)
  static Future<Map<String, dynamic>> pickupCollected(int packageId) async {
    return await ApiService.post(ApiConfig.driverPickupCollected, body: {
      'package_id': packageId,
    });
  }
}
