import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> stats = {
    'clients': 0,
    'users': 0,
    'accounts': 0,
    'tickets': 0,
    'clients_30_days': 0,
    'clients_30_60_days': 0,
  };

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final apiService = ApiService();
      final dashboardStats = await apiService.getDashboardStats(
        forceRefresh: forceRefresh,
      );

      if (dashboardStats != null && dashboardStats['success'] == true) {
        if (!mounted) return;
        final statsData = dashboardStats['stats'] as Map<String, dynamic>?;
        if (statsData != null) {
          setState(() {
            stats = {
              'clients': statsData['clients'] ?? 0,
              'users': statsData['users'] ?? 0,
              'accounts': statsData['accounts'] ?? 0,
              'tickets': statsData['tickets'] ?? 0,
              'clients_30_days': statsData['clients_30_days'] ?? 0,
              'clients_30_60_days': statsData['clients_30_60_days'] ?? 0,
            };
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Invalid dashboard data format';
            isLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          errorMessage = 'Failed to load dashboard data';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final crossAxisCount = isDesktop ? 4 : 2;

    return AdminScaffold(
      title: 'Dashboard',
      selectedIndex: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: isLoading
              ? null
              : () => _loadDashboardData(forceRefresh: true),
          tooltip: 'Refresh Dashboard',
        ),
      ],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadDashboardData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards Grid
                    GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: isDesktop ? 1.8 : 1.3,
                      children: [
                        _buildStatCard(
                          context,
                          'Clients',
                          stats['clients'].toString(),
                          Icons.business,
                          const Color(0xFF004aad),
                          '+12%',
                          isDesktop,
                        ),
                        _buildRenewalStatCard(
                          context,
                          'Renewals',
                          stats['clients_30_days'] ?? 0,
                          stats['clients_30_60_days'] ?? 0,
                          Icons.calendar_today,
                          Colors.green,
                          isDesktop,
                        ),
                        _buildStatCard(
                          context,
                          'Accounts',
                          stats['accounts'].toString(),
                          Icons.account_balance,
                          Colors.orange,
                          '+5%',
                          isDesktop,
                        ),
                        _buildStatCard(
                          context,
                          'Tickets',
                          stats['tickets'].toString(),
                          Icons.confirmation_number,
                          Colors.purple,
                          '-3%',
                          isDesktop,
                        ),
                      ],
                    ),

                    SizedBox(height: isDesktop ? 32 : 24),

                    // Quick Actions and Recent Activity
                    isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quick Actions
                              Expanded(
                                flex: 2,
                                child: _buildQuickActionsCard(
                                  context,
                                  isDesktop,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Recent Activity
                              Expanded(
                                child: _buildRecentActivityCard(
                                  context,
                                  isDesktop,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildQuickActionsCard(context, isDesktop),
                              const SizedBox(height: 16),
                              _buildRecentActivityCard(context, isDesktop),
                            ],
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, bool isDesktop) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? null : 18,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickAction(
              context,
              'Add New Client',
              'Create a new client organization',
              Icons.add_business,
              const Color(0xFF004aad),
              () {
                Navigator.of(context).pushNamed('/clients');
              },
            ),
            const Divider(height: 24),
            _buildQuickAction(
              context,
              'Add New User',
              'Create a new user account',
              Icons.person_add,
              Colors.green,
              () {
                Navigator.of(context).pushNamed('/users');
              },
            ),
            const Divider(height: 24),
            _buildQuickAction(
              context,
              'View Reports',
              'Generate and view system reports',
              Icons.analytics,
              Colors.orange,
              () {},
            ),
            const Divider(height: 24),
            _buildQuickAction(
              context,
              'Manage Tickets',
              'View and manage support tickets',
              Icons.support_agent,
              Colors.purple,
              () {
                Navigator.of(context).pushNamed('/tickets');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(BuildContext context, bool isDesktop) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? null : 18,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              context,
              'New client created',
              '2 hours ago',
              Icons.business,
              const Color(0xFF004aad),
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              context,
              'User account updated',
              '5 hours ago',
              Icons.person,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              context,
              'Ticket resolved',
              '1 day ago',
              Icons.check_circle,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              context,
              'Account activated',
              '2 days ago',
              Icons.account_balance,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
    bool isDesktop,
  ) {
    final isPositive = trend.startsWith('+');
    return Card(
      elevation: 0,
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final iconSize = availableWidth < 120
              ? 18.0
              : (isDesktop ? 24.0 : 20.0);
          final valueFontSize = availableWidth < 120
              ? 20.0
              : (isDesktop ? 32.0 : 24.0);

          return ClipRect(
            child: Padding(
              padding: EdgeInsets.all(
                availableWidth < 120 ? 8 : (isDesktop ? 16 : 12),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width:
                      availableWidth -
                      (availableWidth < 120 ? 16 : (isDesktop ? 32 : 24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(
                              availableWidth < 120 ? 6 : (isDesktop ? 10 : 8),
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: iconSize),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: availableWidth < 120
                                  ? 4
                                  : (isDesktop ? 8 : 6),
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              trend,
                              style: TextStyle(
                                fontSize: availableWidth < 120
                                    ? 9
                                    : (isDesktop ? 12 : 10),
                                fontWeight: FontWeight.bold,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: availableWidth < 120
                            ? 8
                            : (isDesktop ? 16 : 12),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: valueFontSize,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: availableWidth < 120
                              ? 11
                              : (isDesktop ? 14 : 12),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRenewalStatCard(
    BuildContext context,
    String title,
    int clients30Days,
    int clients30To60Days,
    IconData icon,
    Color color,
    bool isDesktop,
  ) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final iconSize = availableWidth < 120
              ? 18.0
              : (isDesktop ? 24.0 : 20.0);

          return ClipRect(
            child: Padding(
              padding: EdgeInsets.all(
                availableWidth < 120 ? 4 : (isDesktop ? 12 : 8),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: availableWidth - (availableWidth < 120 ? 8 : (isDesktop ? 24 : 16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(
                              availableWidth < 120 ? 6 : (isDesktop ? 10 : 8),
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: iconSize),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: availableWidth < 120 ? 6 : (isDesktop ? 10 : 8),
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: availableWidth < 120
                              ? 11
                              : (isDesktop ? 14 : 12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$clients30Days',
                                  style: TextStyle(
                                    fontSize: availableWidth < 120
                                        ? 18
                                        : (isDesktop ? 24 : 20),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  '≤30 days',
                                  style: TextStyle(
                                    fontSize: availableWidth < 120
                                        ? 9
                                        : (isDesktop ? 11 : 10),
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$clients30To60Days',
                                  style: TextStyle(
                                    fontSize: availableWidth < 120
                                        ? 18
                                        : (isDesktop ? 24 : 20),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  '31-60 days',
                                  style: TextStyle(
                                    fontSize: availableWidth < 120
                                        ? 9
                                        : (isDesktop ? 11 : 10),
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                time,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
