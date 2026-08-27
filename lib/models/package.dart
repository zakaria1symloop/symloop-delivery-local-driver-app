import 'package:flutter/material.dart';

class Package {
  final int id;
  final String trackingNumber;
  final String status;
  final String recipientName;
  final String recipientPhone;
  final String? recipientAddress;
  final String? senderName;
  final String? senderPhone;
  final String? communeName;
  final String? wilayaName;
  final double? codAmount;
  final double? shippingCost;
  final String? paymentType;
  final String? deliveryType;
  final String? driverAssignedAt;
  final String? driverCollectedAt;
  final bool pickupFree;
  final double? pickupFee;
  final String? deliveredAt;
  final String? failedAt;
  final String? echecReason;
  final String? lastCallStatus;
  final int callAttempts;
  final String? createdAt;
  final String? updatedAt;

  Package({
    required this.id,
    required this.trackingNumber,
    required this.status,
    required this.recipientName,
    required this.recipientPhone,
    this.recipientAddress,
    this.senderName,
    this.senderPhone,
    this.communeName,
    this.wilayaName,
    this.codAmount,
    this.shippingCost,
    this.paymentType,
    this.deliveryType,
    this.driverAssignedAt,
    this.driverCollectedAt,
    this.pickupFree = false,
    this.pickupFee,
    this.deliveredAt,
    this.failedAt,
    this.echecReason,
    this.lastCallStatus,
    this.callAttempts = 0,
    this.createdAt,
    this.updatedAt,
  });

  // Status helpers
  bool get isRamassage => status == 'en_ramassage';
  bool get isEnCoursLivraison => status == 'en_cours_livraison';
  bool get isLivre => status == 'livre';
  bool get isEchecLivraison => status == 'echec_livraison';

  // COD helpers
  bool get hasCOD => codAmount != null && codAmount! > 0;
  String get codDisplay =>
      hasCOD ? '${codAmount!.toStringAsFixed(0)} DA' : '0 DA';
  String get shippingDisplay =>
      shippingCost != null ? '${shippingCost!.toStringAsFixed(0)} DA' : '0 DA';

  /// Total amount to collect from client (COD + shipping if recipient pays)
  double get totalToCollect {
    double total = codAmount ?? 0;
    if (paymentType == 'recipient' && shippingCost != null) {
      total += shippingCost!;
    }
    return total;
  }

  String get totalToCollectDisplay => '${totalToCollect.toStringAsFixed(0)} DA';
  bool get hasAmountToCollect => totalToCollect > 0;

  // Location display
  String get locationDisplay {
    final parts = <String>[];
    if (communeName != null && communeName!.isNotEmpty) parts.add(communeName!);
    if (wilayaName != null && wilayaName!.isNotEmpty) parts.add(wilayaName!);
    return parts.isNotEmpty ? parts.join(', ') : 'Adresse non disponible';
  }

  // Status label in French
  String get statusLabel {
    switch (status) {
      case 'en_cours_livraison':
        return 'En cours de livraison';
      case 'livre':
        return 'Livre';
      case 'echec_livraison':
        return 'Echec livraison';
      case 'en_attente':
        return 'En attente';
      case 'pris_en_charge':
        return 'Pris en charge';
      case 'au_hub':
        return 'Au hub';
      case 'en_transit':
        return 'En transit';
      case 'arrive_destination':
        return 'Arrive a destination';
      case 'retour':
        return 'Retour';
      case 'retour_expediteur':
        return 'Retour expediteur';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  // Status color for UI
  Color get statusColor {
    switch (status) {
      case 'en_cours_livraison':
        return const Color(0xFF3B82F6);
      case 'livre':
        return const Color(0xFF10B981);
      case 'echec_livraison':
        return const Color(0xFFEF4444);
      case 'en_attente':
        return const Color(0xFF6B7280);
      case 'en_transit':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  // Status icon
  IconData get statusIcon {
    switch (status) {
      case 'en_cours_livraison':
        return Icons.local_shipping;
      case 'livre':
        return Icons.check_circle;
      case 'echec_livraison':
        return Icons.cancel;
      default:
        return Icons.inventory_2;
    }
  }

  // Call status label in French
  String? get callStatusLabel {
    if (lastCallStatus == null) return null;
    switch (lastCallStatus) {
      case 'joint':
        return 'Joint';
      case 'pas_de_reponse':
        return 'Pas de r\u00e9ponse';
      case 'reporte':
        return 'Report\u00e9';
      case 'refuse':
        return 'Refuse';
      case 'injoignable':
        return 'Injoignable';
      default:
        return lastCallStatus;
    }
  }

  // Call status color
  Color get callStatusColor {
    switch (lastCallStatus) {
      case 'joint':
        return const Color(0xFF10B981);
      case 'pas_de_reponse':
        return const Color(0xFFF59E0B);
      case 'reporte':
        return const Color(0xFF3B82F6);
      case 'refuse':
        return const Color(0xFFEF4444);
      case 'injoignable':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  // Failure reason label in French
  String? get echecReasonLabel {
    if (echecReason == null) return null;
    switch (echecReason) {
      case 'recipient_absent':
        return 'Destinataire absent';
      case 'wrong_address':
        return 'Mauvaise adresse';
      case 'refused':
        return 'Colis refuse';
      case 'unreachable':
        return 'Injoignable';
      case 'damaged':
        return 'Colis endommage';
      case 'postponed':
        return 'Reporte';
      default:
        return echecReason;
    }
  }

  /// Safely extract name from String or Map
  static String? _extractName(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return value['name']?.toString();
    return value.toString();
  }

  factory Package.fromJson(Map<String, dynamic> json) {
    // Handle nested recipient_commune → { name, wilaya: { name } }
    String? communeName;
    String? wilayaName;

    final commune = json['recipient_commune'];
    if (commune is Map) {
      communeName = commune['name']?.toString();
      final wilaya = commune['wilaya'];
      if (wilaya is Map) {
        wilayaName = wilaya['name']?.toString();
      }
    } else {
      communeName =
          _extractName(json['recipient_commune']) ??
          _extractName(json['destination_commune']);
      wilayaName = _extractName(json['destination_wilaya']);
    }

    return Package(
      id: json['id'],
      trackingNumber: json['tracking_number'] ?? '',
      status: json['status'] ?? 'en_attente',
      recipientName: json['recipient_name'] ?? 'Destinataire inconnu',
      recipientPhone: json['recipient_phone'] ?? '',
      recipientAddress: json['recipient_address'],
      senderName: json['sender_name'],
      senderPhone: json['sender_phone'],
      communeName: communeName,
      wilayaName: wilayaName,
      codAmount: json['cod_amount'] != null
          ? double.tryParse(json['cod_amount'].toString())
          : null,
      shippingCost: json['shipping_cost'] != null
          ? double.tryParse(json['shipping_cost'].toString())
          : null,
      paymentType: json['payment_type'],
      deliveryType: json['delivery_type'],
      driverAssignedAt: json['driver_assigned_at'],
      driverCollectedAt: json['driver_collected_at'],
      pickupFree: json['pickup_free'] == true || json['pickup_free'] == 1,
      pickupFee: json['pickup_fee'] != null
          ? double.tryParse(json['pickup_fee'].toString())
          : null,
      deliveredAt: json['delivered_at'],
      failedAt: json['failed_at'],
      echecReason: json['echec_reason'],
      lastCallStatus: json['last_call_status'],
      callAttempts: json['call_attempts'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tracking_number': trackingNumber,
      'status': status,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'recipient_address': recipientAddress,
      'cod_amount': codAmount,
      'shipping_cost': shippingCost,
      'payment_type': paymentType,
      'delivery_type': deliveryType,
    };
  }
}
