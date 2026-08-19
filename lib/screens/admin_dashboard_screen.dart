import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/spot_controller.dart';
import '../models/spot_model.dart';
import '../controllers/review_controller.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../constants/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authCtrl = context.read<AuthController>();
      final currentUserRole = authCtrl.currentUser?.role ?? 'tourist';
      if (currentUserRole == 'admin') {
        context.read<AdminController>().loadPendingReports(currentUserRole);
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: success ? AppColors.primary : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showRejectDialog(
      String spotId, String spotName, String currentUserRole) {
    final TextEditingController reasonController = TextEditingController();
    final spotCtrl = context.read<SpotController>();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final dx = sin(_shakeController.value * 2 * pi * 3) * 10;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Reject Reason',
                      style: TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.bold)),
                  content: TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'Enter reason for rejection',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.error, width: 2),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (reasonController.text.isEmpty) {
                          _shakeController.forward(from: 0.0);
                        } else {
                          final reason = reasonController.text.trim();
                          Navigator.pop(context);
                          spotCtrl.rejectSpot(spotId, reason, currentUserRole);
                          _showSnackbar('$spotName rejected', success: true);
                        }
                      },
                      child: const Text('Reject',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final spotCtrl = context.watch<SpotController>();
    final adminCtrl = context.watch<AdminController>();
    final authCtrl = context.watch<AuthController>();
    final currentUserRole = authCtrl.currentUser?.role ?? 'tourist';

    final pendingSpots = spotCtrl.pendingSpots;
    final pendingReports = adminCtrl.pendingReports;

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.errorDark,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Admin Hub',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.errorDark, AppColors.error],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20.0),
                    child: Icon(Icons.admin_panel_settings,
                        size: 80, color: Colors.white24),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildListDelegate([
                _buildStatCard('Pending Spots', '${pendingSpots.length}',
                    Icons.pending_actions, Colors.orange),
                _buildStatCard('User Reports', '${pendingReports.length}',
                    Icons.report_problem, AppColors.error),
                _buildStatCard('Total Users', '${adminCtrl.totalUsers}',
                    Icons.people, Colors.blue),
                _buildStatCard(
                    'Suspended Users',
                    '${adminCtrl.suspendedUsersCount}',
                    Icons.block,
                    Colors.deepPurple),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildExpansionSection(
                    'Pending Spot Approvals',
                    Icons.pending_actions,
                    pendingSpots.isEmpty
                        ? [
                            const ListTile(
                              title: Text('No pending spots',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          ]
                        : pendingSpots
                            .map((spot) => _buildApprovalTile(
                                  spot,
                                  onApprove: () =>
                                      _approveSpot(spot, currentUserRole),
                                  onReject: () => _showRejectDialog(
                                      spot.id, spot.name, currentUserRole),
                                ))
                            .toList(),
                  ),

                  const SizedBox(height: 16),
                  _buildExpansionSection(
                    'User Reports Queue',
                    Icons.report_problem,
                    pendingReports.isEmpty
                        ? [
                            const ListTile(
                              title: Text('No pending reports',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          ]
                        : pendingReports
                            .map((r) =>
                                _buildReportTile(r, adminCtrl, currentUserRole))
                            .toList(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, val, child) {
        return Transform.scale(scale: val, child: child);
      },
      child: Card(
        elevation: 6,
        shadowColor: color.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionSection(
      String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon, color: AppColors.error),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: children,
      ),
    );
  }

  Future<void> _approveSpot(SpotModel spot, String currentUserRole) async {
    try {
      await context.read<SpotController>().approveSpot(spot.id, currentUserRole);
      if (!mounted) return;
      _showSnackbar('${spot.name} approved and now live!', success: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Could not approve ${spot.name}: $e');
    }
  }

  void _showSpotReviewSheet(SpotModel spot,
      {required VoidCallback onApprove, required VoidCallback onReject}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          builder: (ctx, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              if (spot.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    spot.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: AppColors.backgroundGrey,
                      child: const Icon(Icons.broken_image,
                          size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(spot.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${spot.category} • ${spot.city}, ${spot.state}',
                  style: const TextStyle(color: Colors.grey)),
              const Divider(height: 28),
              _buildDetailRow(Icons.location_on, 'Address', spot.address),
              _buildDetailRow(Icons.attach_money, 'Price range', spot.priceRange),
              _buildDetailRow(Icons.schedule, 'Best time', spot.bestTime),
              _buildDetailRow(Icons.checklist, 'Things to do', spot.thingsToDo),
              _buildDetailRow(Icons.notes, 'Description', spot.description),
              _buildDetailRow(Icons.person, 'Submitted by', spot.submittedBy),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onReject();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onApprove();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalTile(SpotModel spot,
      {required VoidCallback onApprove, required VoidCallback onReject}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: spot.imageUrl.isNotEmpty
            ? Image.network(spot.imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported))
            : Container(
                width: 48,
                height: 48,
                color: AppColors.backgroundGrey,
                child: const Icon(Icons.place, color: Colors.grey),
              ),
      ),
      title:
          Text(spot.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${spot.category} • ${spot.city}, ${spot.state}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => _showSpotReviewSheet(spot,
          onApprove: onApprove,
          onReject: () => _confirmAction(
                title: 'Reject Submission',
                content: 'Are you sure you want to reject "${spot.name}"?',
                onConfirm: onReject,
              )),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            tooltip: 'Approve',
            onPressed: onApprove,
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.cancel, color: AppColors.error, size: 28),
            tooltip: 'Reject',
            onPressed: () {
              _confirmAction(
                title: 'Reject Submission',
                content: 'Are you sure you want to reject "${spot.name}"?',
                onConfirm: onReject,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportTile(
    Map<String, dynamic> report,
    AdminController adminCtrl,
    String currentUserRole,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),
      title: Text(
        "Target: ${report['target_type']} (${report['target_id']})",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        "Reason: ${report['reason']}",
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (report['target_type'] == 'review')
            IconButton(
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              icon: const Icon(
                Icons.delete,
                color: AppColors.error,
              ),
              tooltip: 'Delete Review & Resolve',
              onPressed: () {
                _confirmAction(
                  title: 'Delete Content',
                  content: 'Delete this review and resolve the report?',
                  onConfirm: () {
                    adminCtrl.resolveReport(
                      report['id'],
                      'delete_review',
                      currentUserRole,
                      reviewIdToDelete: report['target_id'],
                    );

                    _showSnackbar(
                      'Review deleted and report resolved',
                      success: true,
                    );
                  },
                );
              },
            ),
          IconButton(
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
            tooltip: 'Dismiss Report',
            onPressed: () {
              adminCtrl.dismissReport(
                report['id'],
                currentUserRole,
              );

              _showSnackbar(
                'Report dismissed',
                success: true,
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmAction({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
