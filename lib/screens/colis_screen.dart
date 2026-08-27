import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/auth_provider.dart';
import '../providers/package_provider.dart';
import '../models/package.dart';
import '../services/package_service.dart';

class ColisScreen extends StatefulWidget {
  const ColisScreen({super.key});

  @override
  State<ColisScreen> createState() => _ColisScreenState();
}

class _ColisScreenState extends State<ColisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _primaryBlue = Color(0xFF3B82F6);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _warningAmber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _driverId {
    final user = context.read<AuthProvider>().user;
    return user?.id ?? 0;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final packages = context.read<PackageProvider>();
    if (auth.user != null) {
      await packages.loadAllData(auth.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Mes Colis',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(10)
                    : Colors.black.withAlpha(8),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                color: _primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor:
                  isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 12),
              tabs: [
                _buildTab('Ramassage',
                    context.watch<PackageProvider>().toPickupCount),
                _buildTab('En possession',
                    context.watch<PackageProvider>().inPossessionCount),
                _buildTab('\u00c0 livrer',
                    context.watch<PackageProvider>().toDeliverCount),
                _buildTab('Livr\u00e9s',
                    context.watch<PackageProvider>().deliveredCount),
                _buildTab('\u00c9checs',
                    context.watch<PackageProvider>().failedCount),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPackageList(
            statusKey: 'toPickup',
            emptyIcon: Iconsax.box_add,
            emptyTitle: 'Aucun ramassage',
            emptySubtitle: 'Les colis \u00e0 r\u00e9cup\u00e9rer appara\u00eetront ici',
            emptyColor: _warningAmber,
          ),
          _buildPackageList(
            statusKey: 'inPossession',
            emptyIcon: Iconsax.box_tick,
            emptyTitle: 'Aucun colis en possession',
            emptySubtitle: 'Les colis ramass\u00e9s appara\u00eetront ici',
            emptyColor: _successGreen,
          ),
          _buildPackageList(
            statusKey: 'toDeliver',
            emptyIcon: Iconsax.truck,
            emptyTitle: 'Aucun colis \u00e0 livrer',
            emptySubtitle: 'Les colis assign\u00e9s appara\u00eetront ici',
            emptyColor: _primaryBlue,
          ),
          _buildPackageList(
            statusKey: 'delivered',
            emptyIcon: Iconsax.tick_circle,
            emptyTitle: 'Aucun colis livr\u00e9',
            emptySubtitle:
                'Les colis livr\u00e9s aujourd\'hui appara\u00eetront ici',
            emptyColor: _successGreen,
          ),
          _buildPackageList(
            statusKey: 'failed',
            emptyIcon: Iconsax.close_circle,
            emptyTitle: 'Aucun \u00e9chec',
            emptySubtitle:
                'Les \u00e9checs de livraison appara\u00eetront ici',
            emptyColor: _errorRed,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab label
  // ---------------------------------------------------------------------------
  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Package list per tab
  // ---------------------------------------------------------------------------
  Widget _buildPackageList({
    required String statusKey,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required Color emptyColor,
  }) {
    return Consumer<PackageProvider>(
      builder: (context, provider, child) {
        final bool isLoading;
        final List<Package> packages;

        switch (statusKey) {
          case 'toPickup':
            isLoading = provider.isLoadingToPickup;
            packages = provider.toPickup;
            break;
          case 'inPossession':
            isLoading = provider.isLoadingToPickup;
            packages = provider.inPossession;
            break;
          case 'toDeliver':
            isLoading = provider.isLoadingToDeliver;
            packages = provider.toDeliver;
            break;
          case 'delivered':
            isLoading = provider.isLoadingDelivered;
            packages = provider.delivered;
            break;
          case 'failed':
            isLoading = provider.isLoadingFailed;
            packages = provider.failed;
            break;
          default:
            isLoading = false;
            packages = [];
        }

        if (isLoading && packages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: _primaryBlue,
              strokeWidth: 2,
            ),
          );
        }

        if (packages.isEmpty) {
          return _buildEmptyWidget(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
            color: emptyColor,
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          color: _primaryBlue,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildPackageCard(
                  packages[index],
                  showActions: statusKey == 'toDeliver' || statusKey == 'toPickup',
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Package card
  // ---------------------------------------------------------------------------
  Widget _buildPackageCard(Package package, {bool showActions = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showPackageDetail(package),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141414) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(8)
                : Colors.black.withAlpha(6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: tracking (monospace) + status badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: package.statusColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      package.statusIcon,
                      color: package.statusColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.trackingNumber,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          package.isRamassage
                              ? (package.senderName ?? package.recipientName)
                              : package.recipientName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (package.isRamassage)
                          Text(
                            'Expéditeur',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple.shade400,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: package.statusColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      package.statusLabel,
                      style: TextStyle(
                        color: package.statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Phone
              Row(
                children: [
                  Icon(
                    Iconsax.call,
                    size: 14,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    package.recipientPhone,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Address
              if (package.recipientAddress != null &&
                  package.recipientAddress!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Iconsax.home,
                      size: 14,
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        package.recipientAddress!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // Location (commune / wilaya)
              Row(
                children: [
                  Icon(
                    Iconsax.location,
                    size: 14,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      package.locationDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Failure reason (if failed)
              if (package.echecReasonLabel != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Iconsax.warning_2, size: 14, color: _errorRed),
                    const SizedBox(width: 8),
                    Text(
                      package.echecReasonLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _errorRed,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),

              // Money display — different for pickup vs delivery
              Row(
                children: [
                  if (package.status == 'en_ramassage') ...[
                    // PICKUP: show gratuit/payant badge + pickup fee
                    if (package.pickupFree)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _successGreen.withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _successGreen.withAlpha(40)),
                        ),
                        child: const Text('Gratuit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: _successGreen)),
                      )
                    else ...[
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
                            Text('À collecter: ', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                            Text('${(package.pickupFee ?? 0).toStringAsFixed(0)} DA', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: _warningAmber)),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    // DELIVERY: show total to collect (COD + shipping)
                    if (package.hasAmountToCollect)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _successGreen.withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _successGreen.withAlpha(40)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('À encaisser: ', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                            Text(package.totalToCollectDisplay, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: _successGreen)),
                          ],
                        ),
                      ),
                    if (package.hasAmountToCollect) const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(6) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Livraison: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          Text(package.shippingDisplay, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // Call status indicator
              if (package.lastCallStatus != null ||
                  package.callAttempts > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: package.callStatusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      package.callStatusLabel ?? 'Non appel\u00e9',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: package.callStatusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${package.callAttempts} appel${package.callAttempts > 1 ? 's' : ''})',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],

              // Action buttons
              if (showActions) ...[
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: isDark
                      ? Colors.white.withAlpha(6)
                      : Colors.black.withAlpha(6),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Iconsax.call,
                        label: 'Appeler',
                        color: _primaryBlue,
                        isDark: isDark,
                        onTap: () => _showCallSheet(package),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (package.status == 'en_ramassage')
                      Expanded(
                        child: _buildActionButton(
                          icon: Iconsax.box_add,
                          label: 'Ramasser',
                          color: _warningAmber,
                          isDark: isDark,
                          onTap: () => _showRamassageConfirm(package),
                        ),
                      )
                    else
                      Expanded(
                        child: _buildActionButton(
                          icon: Iconsax.tick_circle,
                          label: 'Livrer',
                          color: _successGreen,
                          isDark: isDark,
                          onTap: () => _showDeliverSheet(package),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Iconsax.close_circle,
                        label: '\u00c9chec',
                        color: _errorRed,
                        isDark: isDark,
                        onTap: () => _showFailSheet(package),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action button widget
  // ---------------------------------------------------------------------------
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withAlpha(isDark ? 20 : 12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withAlpha(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CALL BOTTOM SHEET
  // ---------------------------------------------------------------------------
  void _showCallSheet(Package package) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final outcomes = <_CallOutcomeOption>[
      _CallOutcomeOption(
        key: 'joint',
        label: 'Joint (contact\u00e9)',
        icon: Iconsax.tick_circle,
        color: _successGreen,
      ),
      _CallOutcomeOption(
        key: 'pas_de_reponse',
        label: 'Pas de r\u00e9ponse',
        icon: Iconsax.call_slash,
        color: _warningAmber,
      ),
      _CallOutcomeOption(
        key: 'reporte',
        label: 'Report\u00e9',
        icon: Iconsax.clock,
        color: _primaryBlue,
      ),
      _CallOutcomeOption(
        key: 'refuse',
        label: 'Refuse',
        icon: Iconsax.slash,
        color: _errorRed,
      ),
      _CallOutcomeOption(
        key: 'injoignable',
        label: 'Injoignable',
        icon: Iconsax.call_remove,
        color: _errorRed,
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141414) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          const Icon(Iconsax.call, color: _primaryBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'R\u00e9sultat de l\'appel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            package.recipientName,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (package.callAttempts > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withAlpha(8)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${package.callAttempts} appel${package.callAttempts > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Outcome buttons
                ...outcomes.map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildOutcomeButton(
                        option: o,
                        isDark: isDark,
                        isSelected: package.lastCallStatus == o.key,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _handleRecordCall(package, o.key);
                        },
                      ),
                    )),

                const SizedBox(height: 8),

                // Direct call button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _callRecipient(package.recipientPhone);
                    },
                    icon: const Icon(Iconsax.call, size: 18),
                    label: Text(
                      'Appeler ${package.recipientPhone}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryBlue,
                      side: BorderSide(color: _primaryBlue.withAlpha(60)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutcomeButton({
    required _CallOutcomeOption option,
    required bool isDark,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? option.color.withAlpha(20)
                : (isDark
                    ? Colors.white.withAlpha(6)
                    : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? option.color.withAlpha(60)
                  : (isDark
                      ? Colors.white.withAlpha(8)
                      : Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Icon(option.icon, size: 20, color: option.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? option.color
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
              if (isSelected)
                Icon(Iconsax.tick_circle5,
                    size: 20, color: option.color),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRecordCall(Package package, String outcome) async {
    final provider = context.read<PackageProvider>();
    final result = await provider.recordCall(package.id, outcome);

    if (!mounted) return;

    if (result['success'] == true) {
      Fluttertoast.showToast(
        msg: 'Appel enregistr\u00e9',
        backgroundColor: _successGreen,
        textColor: Colors.white,
        gravity: ToastGravity.BOTTOM,
      );
      // Refresh data to get updated call status
      await _loadData();
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Erreur lors de l\'enregistrement',
        backgroundColor: _errorRed,
        textColor: Colors.white,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // DELIVER BOTTOM SHEET
  // ---------------------------------------------------------------------------
  void _showDeliverSheet(Package package) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    // Pre-fill hint with last 4 digits
    final phoneLast4 = package.recipientPhone.length >= 4
        ? package.recipientPhone
            .substring(package.recipientPhone.length - 4)
        : package.recipientPhone;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141414) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Success icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _successGreen.withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.tick_circle,
                          color: _successGreen,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Confirmez la livraison',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        package.trackingNumber,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Total amount to collect display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: package.hasAmountToCollect
                              ? _successGreen.withAlpha(10)
                              : (isDark
                                  ? Colors.white.withAlpha(6)
                                  : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: package.hasAmountToCollect
                                ? _successGreen.withAlpha(30)
                                : (isDark
                                    ? Colors.white.withAlpha(8)
                                    : Colors.grey.shade200),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Montant \u00e0 encaisser',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              package.totalToCollectDisplay,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: package.hasAmountToCollect
                                    ? _successGreen
                                    : (isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600),
                              ),
                            ),
                            // Only show total amount — no COD/frais breakdown
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone verification
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              'T\u00e9l\u00e9phone du destinataire',
                          hintText:
                              'Terminer par ...$phoneLast4',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                          ),
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          prefixIcon: const Icon(Iconsax.call,
                              color: _successGreen, size: 20),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withAlpha(6)
                              : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withAlpha(10)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withAlpha(10)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: _successGreen, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: _errorRed),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Le t\u00e9l\u00e9phone est requis';
                          }
                          if (v.trim().length < 4) {
                            return 'Num\u00e9ro trop court';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  setSheetState(
                                      () => isSubmitting = true);

                                  final provider =
                                      context.read<PackageProvider>();
                                  final driverId = _driverId;
                                  final result =
                                      await provider.deliverPackage(
                                    package.id,
                                    phoneController.text.trim(),
                                    driverId,
                                  );

                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);

                                  if (result['success'] == true) {
                                    Fluttertoast.showToast(
                                      msg:
                                          'Colis marqu\u00e9 comme livr\u00e9',
                                      backgroundColor: _successGreen,
                                      textColor: Colors.white,
                                      gravity: ToastGravity.BOTTOM,
                                    );
                                  } else {
                                    Fluttertoast.showToast(
                                      msg: result['message'] ??
                                          'Erreur lors de la livraison',
                                      backgroundColor: _errorRed,
                                      textColor: Colors.white,
                                      gravity: ToastGravity.BOTTOM,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _successGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            disabledBackgroundColor:
                                _successGreen.withAlpha(100),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Confirmer la livraison',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FAIL BOTTOM SHEET
  // ---------------------------------------------------------------------------
  void _showRamassageConfirm(Package package) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.read<AuthProvider>().user;
    final driverId = user?.id ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          bool isLoading = false;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141414) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Icon(Iconsax.box_add, size: 48, color: _warningAmber),
                const SizedBox(height: 12),
                Text(
                  'Confirmer le ramassage',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confirmez que vous avez récupéré ce colis chez l\'expéditeur',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),
                // Package info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(6) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white.withAlpha(8) : Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(package.trackingNumber, style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                      const SizedBox(height: 4),
                      Text('Expéditeur: ${package.recipientName}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      Text(package.locationDisplay, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Amount to collect — highlighted
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: package.pickupFree
                        ? _successGreen.withAlpha(10)
                        : _warningAmber.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: package.pickupFree
                          ? _successGreen.withAlpha(30)
                          : _warningAmber.withAlpha(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        package.pickupFree ? 'Ramassage gratuit' : 'Montant à collecter',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package.pickupFree
                            ? 'Gratuit'
                            : '${(package.pickupFee ?? 0).toStringAsFixed(0)} DA',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: package.pickupFree ? _successGreen : _warningAmber,
                        ),
                      ),
                      if (!package.pickupFree)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'L\'expéditeur doit payer ce montant',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ),
                      if (package.pickupFree)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Vous serez payé au SD',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      setState(() => isLoading = true);
                      try {
                        final res = await PackageService.pickupCollected(package.id);
                        if (res['success'] == true) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          Fluttertoast.showToast(msg: 'Colis ramassé avec succès', backgroundColor: _successGreen);
                          if (mounted) {
                            context.read<PackageProvider>().loadAllData(driverId);
                          }
                        } else {
                          Fluttertoast.showToast(msg: res['message'] ?? 'Erreur', backgroundColor: _errorRed);
                          setState(() => isLoading = false);
                        }
                      } catch (e) {
                        Fluttertoast.showToast(msg: 'Erreur de connexion', backgroundColor: _errorRed);
                        setState(() => isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _warningAmber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Confirmer le ramassage', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFailSheet(Package package) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final reasons = <_FailReasonOption>[
      _FailReasonOption(
        key: 'recipient_absent',
        label: 'Absent',
        icon: Iconsax.user_remove,
      ),
      _FailReasonOption(
        key: 'wrong_address',
        label: 'Adresse incorrecte',
        icon: Iconsax.location_slash,
      ),
      _FailReasonOption(
        key: 'refused',
        label: 'Refus du colis',
        icon: Iconsax.slash,
      ),
      _FailReasonOption(
        key: 'unreachable',
        label: 'Injoignable',
        icon: Iconsax.call_remove,
      ),
      _FailReasonOption(
        key: 'inaccessible_zone',
        label: 'Zone inaccessible',
        icon: Iconsax.danger,
      ),
      _FailReasonOption(
        key: 'other',
        label: 'Autre',
        icon: Iconsax.more_circle,
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141414) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _errorRed.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Iconsax.close_circle,
                              color: _errorRed, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'D\u00e9clarer un \u00e9chec',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                package.trackingNumber,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'S\u00e9lectionnez le motif de l\'\u00e9chec',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reason grid (2 columns)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.6,
                      children: reasons.map((r) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: isSubmitting
                                ? null
                                : () async {
                                    setSheetState(
                                        () => isSubmitting = true);

                                    final provider =
                                        context.read<PackageProvider>();
                                    final driverId = _driverId;
                                    final result =
                                        await provider.failPackage(
                                      package.id,
                                      r.key,
                                      driverId,
                                    );

                                    if (!ctx.mounted) return;
                                    Navigator.pop(ctx);

                                    if (result['success'] == true) {
                                      Fluttertoast.showToast(
                                        msg:
                                            '\u00c9chec enregistr\u00e9',
                                        backgroundColor: _warningAmber,
                                        textColor: Colors.white,
                                        gravity: ToastGravity.BOTTOM,
                                      );
                                    } else {
                                      Fluttertoast.showToast(
                                        msg: result['message'] ??
                                            'Erreur lors de l\'enregistrement',
                                        backgroundColor: _errorRed,
                                        textColor: Colors.white,
                                        gravity: ToastGravity.BOTTOM,
                                      );
                                    }
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withAlpha(6)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withAlpha(8)
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(r.icon,
                                      size: 18, color: _errorRed),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      r.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (isSubmitting) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: _errorRed,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DETAIL BOTTOM SHEET
  // ---------------------------------------------------------------------------
  void _showPackageDetail(Package package) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToDeliver = package.status == 'en_cours_livraison';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tracking number + status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: package.statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        package.statusIcon,
                        color: package.statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package.trackingNumber,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: package.statusColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              package.statusLabel,
                              style: TextStyle(
                                color: package.statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recipient info
                // Show sender for ramassage, recipient for delivery
                if (package.isRamassage && package.senderName != null) ...[
                  _buildDetailSection(
                    'Expéditeur (ramassage)',
                    Iconsax.user,
                    [
                      _buildDetailRow('Nom', package.senderName!, isDark),
                      if (package.senderPhone != null)
                        _buildDetailRow('Téléphone', package.senderPhone!, isDark),
                      _buildDetailRow('Commune', package.locationDisplay, isDark),
                    ],
                    isDark,
                  ),
                ] else ...[
                  _buildDetailSection(
                    'Destinataire',
                    Iconsax.user,
                    [
                      _buildDetailRow('Nom', package.recipientName, isDark),
                      _buildDetailRow(
                          'Téléphone', package.recipientPhone, isDark),
                      if (package.recipientAddress != null)
                        _buildDetailRow(
                            'Adresse', package.recipientAddress!, isDark),
                      _buildDetailRow(
                          'Commune', package.locationDisplay, isDark),
                    ],
                    isDark,
                  ),
                ],
                const SizedBox(height: 16),

                // Package info
                _buildDetailSection(
                  'Colis',
                  Iconsax.box,
                  [
                    _buildDetailRow(
                        'À encaisser', package.totalToCollectDisplay, isDark,
                        valueColor: _successGreen),
                    if (package.paymentType != null)
                      _buildDetailRow(
                        'Paiement',
                        package.paymentType == 'cod'
                            ? 'Contre remboursement'
                            : (package.paymentType == 'sender'
                                ? 'Exp\u00e9diteur'
                                : package.paymentType!),
                        isDark,
                      ),
                    if (package.deliveryType != null)
                      _buildDetailRow(
                        'Type',
                        package.deliveryType == 'home_delivery'
                            ? 'Livraison \u00e0 domicile'
                            : 'Stop desk',
                        isDark,
                      ),
                  ],
                  isDark,
                ),

                // Call info
                if (package.lastCallStatus != null ||
                    package.callAttempts > 0) ...[
                  const SizedBox(height: 16),
                  _buildDetailSection(
                    'Appels',
                    Iconsax.call,
                    [
                      _buildDetailRow(
                        'Dernier statut',
                        package.callStatusLabel ?? 'Aucun',
                        isDark,
                        valueColor: package.lastCallStatus != null
                            ? package.callStatusColor
                            : null,
                      ),
                      _buildDetailRow(
                        'Tentatives',
                        '${package.callAttempts}',
                        isDark,
                      ),
                    ],
                    isDark,
                  ),
                ],

                // Failure reason
                if (package.echecReasonLabel != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailSection(
                    'Motif d\'\u00e9chec',
                    Iconsax.warning_2,
                    [
                      _buildDetailRow(
                        'Raison',
                        package.echecReasonLabel!,
                        isDark,
                        valueColor: _errorRed,
                      ),
                    ],
                    isDark,
                  ),
                ],

                // Status timeline
                const SizedBox(height: 16),
                _buildStatusTimeline(package, isDark),

                const SizedBox(height: 24),

                // Quick action buttons (call + navigate)
                if (package.recipientPhone.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _callRecipient(package.recipientPhone),
                            icon: const Icon(Iconsax.call, size: 20),
                            label: const Text(
                              'Appeler',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (package.recipientAddress != null &&
                          package.recipientAddress!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _navigateToAddress(package),
                              icon: const Icon(Iconsax.map, size: 20),
                              label: const Text(
                                'Naviguer',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _warningAmber,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // Livrer / Echec buttons (only in detail of "to deliver")
                if (isToDeliver)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showDeliverSheet(package);
                            },
                            icon: const Icon(Iconsax.tick_circle,
                                size: 20),
                            label: const Text(
                              'Livrer',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _successGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showFailSheet(package);
                            },
                            icon: const Icon(Iconsax.close_circle,
                                size: 20),
                            label: const Text(
                              '\u00c9chec',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _errorRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Status timeline
  // ---------------------------------------------------------------------------
  Widget _buildStatusTimeline(Package package, bool isDark) {
    final steps = <_TimelineStep>[];

    // Build timeline based on available data
    if (package.createdAt != null) {
      steps.add(_TimelineStep(
        label: 'Cr\u00e9\u00e9',
        date: _formatDate(package.createdAt!),
        color: Colors.grey,
        isCompleted: true,
      ));
    }

    if (package.driverAssignedAt != null) {
      steps.add(_TimelineStep(
        label: 'Assign\u00e9 au chauffeur',
        date: _formatDate(package.driverAssignedAt!),
        color: _primaryBlue,
        isCompleted: true,
      ));
    }

    steps.add(_TimelineStep(
      label: 'En cours de livraison',
      date: '',
      color: _primaryBlue,
      isCompleted: package.isEnCoursLivraison ||
          package.isLivre ||
          package.isEchecLivraison,
    ));

    if (package.isLivre) {
      steps.add(_TimelineStep(
        label: 'Livr\u00e9',
        date: package.deliveredAt != null
            ? _formatDate(package.deliveredAt!)
            : '',
        color: _successGreen,
        isCompleted: true,
      ));
    } else if (package.isEchecLivraison) {
      steps.add(_TimelineStep(
        label: '\u00c9chec livraison',
        date: package.failedAt != null
            ? _formatDate(package.failedAt!)
            : '',
        color: _errorRed,
        isCompleted: true,
      ));
    }

    return _buildDetailSection(
      'Historique',
      Iconsax.clock,
      steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isLast = i == steps.length - 1;

        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: step.isCompleted
                          ? step.color
                          : (isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300),
                      shape: BoxShape.circle,
                    ),
                    child: step.isCompleted
                        ? const Icon(Icons.check,
                            size: 8, color: Colors.white)
                        : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 24,
                      color: step.isCompleted
                          ? step.color.withAlpha(60)
                          : (isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: step.isCompleted
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: step.isCompleted
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400),
                        ),
                      ),
                      if (step.date.isNotEmpty)
                        Text(
                          step.date,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      isDark,
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/${dt.year} $hour:$minute';
    } catch (_) {
      return dateStr;
    }
  }

  // ---------------------------------------------------------------------------
  // Detail section & row helpers
  // ---------------------------------------------------------------------------
  Widget _buildDetailSection(
    String title,
    IconData icon,
    List<Widget> children,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(8)
              : Colors.black.withAlpha(6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ??
                    (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------
  Widget _buildEmptyWidget({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // External actions: call & navigate
  // ---------------------------------------------------------------------------
  Future<void> _callRecipient(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Impossible d\'ouvrir le t\u00e9l\u00e9phone',
          backgroundColor: _errorRed,
          textColor: Colors.white,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  Future<void> _navigateToAddress(Package package) async {
    final parts = <String>[];
    if (package.recipientAddress != null) parts.add(package.recipientAddress!);
    if (package.communeName != null) parts.add(package.communeName!);
    if (package.wilayaName != null) parts.add(package.wilayaName!);
    parts.add('Algeria');
    final query = Uri.encodeQueryComponent(parts.join(', '));

    final geoUri = Uri.parse('geo:0,0?q=$query');
    final mapsUri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Impossible d\'ouvrir la navigation',
          backgroundColor: _errorRed,
          textColor: Colors.white,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }
}

// =============================================================================
// Helper data classes
// =============================================================================

class _CallOutcomeOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const _CallOutcomeOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _FailReasonOption {
  final String key;
  final String label;
  final IconData icon;

  const _FailReasonOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class _TimelineStep {
  final String label;
  final String date;
  final Color color;
  final bool isCompleted;

  const _TimelineStep({
    required this.label,
    required this.date,
    required this.color,
    required this.isCompleted,
  });
}
