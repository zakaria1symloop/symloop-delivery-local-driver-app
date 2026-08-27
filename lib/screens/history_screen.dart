import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/package_provider.dart';
import '../models/package.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'all'; // all, livre, echec_livraison

  static const Color _primaryBlue = Color(0xFF3B82F6);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningAmber = Color(0xFFF59E0B);
  static const Color _errorRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final packages = context.read<PackageProvider>();
    if (auth.user != null) {
      await packages.loadAllData(auth.user!.id);
    }
  }

  List<Package> _getFilteredPackages(PackageProvider provider) {
    switch (_filter) {
      case 'livre':
        return provider.delivered;
      case 'echec_livraison':
        return provider.failed;
      default:
        // Combine delivered + failed, sort by date descending
        final all = [...provider.delivered, ...provider.failed];
        all.sort((a, b) {
          final aDate = a.deliveredAt ?? a.failedAt ?? a.updatedAt ?? '';
          final bDate = b.deliveredAt ?? b.failedAt ?? b.updatedAt ?? '';
          return bDate.compareTo(aDate);
        });
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Historique',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: Consumer<PackageProvider>(
        builder: (context, provider, child) {
          final packages = _getFilteredPackages(provider);
          final isLoading =
              provider.isLoadingDelivered || provider.isLoadingFailed;

          return Column(
            children: [
              // Filter chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: _buildFilterRow(provider, isDark),
              ),

              // Summary bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildSummaryBar(provider, isDark),
              ),

              // List
              Expanded(
                child: isLoading && packages.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: _primaryBlue,
                          strokeWidth: 2,
                        ),
                      )
                    : packages.isEmpty
                        ? _buildEmptyState(isDark)
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: _primaryBlue,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: packages.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildHistoryCard(packages[index], isDark),
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterRow(PackageProvider provider, bool isDark) {
    return Row(
      children: [
        _buildFilterChip('all', 'Tous', isDark),
        const SizedBox(width: 8),
        _buildFilterChip('livre', 'Livres', isDark),
        const SizedBox(width: 8),
        _buildFilterChip('echec_livraison', 'Echecs', isDark),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark) {
    final isSelected = _filter == value;

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryBlue
              : (isDark ? Colors.white.withAlpha(8) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? _primaryBlue
                : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar(PackageProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Livres',
            provider.deliveredCount.toString(),
            _successGreen,
            isDark,
          ),
          Container(
            width: 1,
            height: 30,
            color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8),
          ),
          _buildSummaryItem(
            'Echecs',
            provider.failedCount.toString(),
            _errorRed,
            isDark,
          ),
          Container(
            width: 1,
            height: 30,
            color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8),
          ),
          _buildSummaryItem(
            'Encaissé',
            '${provider.totalCollected.toStringAsFixed(0)} DA',
            _warningAmber,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Package package, bool isDark) {
    final isDelivered = package.isLivre;
    final color = isDelivered ? _successGreen : _errorRed;
    final icon = isDelivered ? Iconsax.tick_circle : Iconsax.close_circle;

    // Format date
    String dateStr = '';
    final dateRaw = package.deliveredAt ?? package.failedAt ?? package.updatedAt;
    if (dateRaw != null) {
      final date = DateTime.tryParse(dateRaw);
      if (date != null) {
        dateStr = DateFormat('dd/MM HH:mm').format(date.toLocal());
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.trackingNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    package.statusLabel,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Recipient
            _buildInfoRow(
              Iconsax.user,
              package.recipientName,
              isDark,
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              Iconsax.location,
              package.locationDisplay,
              isDark,
            ),

            // Failure reason
            if (package.echecReasonLabel != null) ...[
              const SizedBox(height: 4),
              _buildInfoRow(
                Iconsax.warning_2,
                package.echecReasonLabel!,
                isDark,
                color: _errorRed,
              ),
            ],

            // COD
            if (package.hasCOD) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _warningAmber.withAlpha(15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _warningAmber.withAlpha(40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'COD: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      package.codDisplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: _warningAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String value,
    bool isDark, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color ?? (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color ??
                  (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primaryBlue.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Iconsax.clipboard_text, size: 40, color: _primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun historique',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vos livraisons du jour apparaitront ici',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
