import 'package:flutter/material.dart';
import '../widgets/admin_scaffold.dart';
import '../services/api_service.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool isLoading = true;
  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> filteredClients = [];
  String? errorMessage;
  bool showDevClients = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final clientsData = await _apiService.getClients();
      // Renewal data (subscription_type, renew_date, etc.) is now included in client response

      if (!mounted) return;

      setState(() {
        clients = clientsData;
        _applyClientFilter();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _applyClientFilter() {
    List<Map<String, dynamic>> baseClients;

    if (showDevClients) {
      // Show only acme* and signup* clients
      baseClients = clients.where((client) {
        final domain = client['domain']?.toString().toLowerCase() ?? '';
        return domain.startsWith('acme') || domain.startsWith('signup');
      }).toList();
    } else {
      // Show all clients except acme* and signup*
      baseClients = clients.where((client) {
        final domain = client['domain']?.toString().toLowerCase() ?? '';
        return !domain.startsWith('acme') && !domain.startsWith('signup');
      }).toList();
    }

    // Apply search filter on top of dev/regular filter
    final query = _searchController.text;
    if (query.isEmpty) {
      filteredClients = baseClients;
    } else {
      filteredClients = baseClients.where((client) {
        final name = client['name']?.toString().toLowerCase() ?? '';
        final domain = client['domain']?.toString().toLowerCase() ?? '';
        final schemaName =
            client['schema_name']?.toString().toLowerCase() ?? '';
        final searchLower = query.toLowerCase();

        return name.contains(searchLower) ||
            domain.contains(searchLower) ||
            schemaName.contains(searchLower);
      }).toList();
    }
  }

  void _filterClients(String query) {
    setState(() {
      _applyClientFilter();
    });
  }

  int _getRegularClientsCount() {
    return clients.where((client) {
      final domain = client['domain']?.toString().toLowerCase() ?? '';
      return !domain.startsWith('acme') && !domain.startsWith('signup');
    }).length;
  }

  int _getDevClientsCount() {
    return clients.where((client) {
      final domain = client['domain']?.toString().toLowerCase() ?? '';
      return domain.startsWith('acme') || domain.startsWith('signup');
    }).length;
  }

  void _toggleDevMode(bool showDev) {
    setState(() {
      showDevClients = showDev;
      _applyClientFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Client Management',
      selectedIndex: 1,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildErrorState()
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Actions
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                'Search clients by name, domain, or schema...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: _filterClients,
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: _showAddClientDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Client'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Stats Overview
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatButton(
                          'Total Clients',
                          '${_getRegularClientsCount()}',
                          Icons.business,
                          const Color(0xFF004aad),
                          !showDevClients,
                          () => _toggleDevMode(false),
                        ),
                        const SizedBox(width: 12),
                        _buildStatButton(
                          'Dev Clients',
                          '${_getDevClientsCount()}',
                          Icons.code,
                          Colors.orange,
                          showDevClients,
                          () => _toggleDevMode(true),
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          'Filtered',
                          '${filteredClients.length}',
                          Icons.filter_list,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Clients View
                  Expanded(
                    child: filteredClients.isEmpty
                        ? _buildEmptyState()
                        : _buildClientsList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatButton(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(isSelected ? 1.0 : 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$label: ',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load clients',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(errorMessage ?? 'Unknown error'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loadClients,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No clients found',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Get started by adding your first client',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _showAddClientDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Client'),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    return RefreshIndicator(
      onRefresh: _loadClients,
      child: Card(
        elevation: 0,
        child: ListView.separated(
          itemCount: filteredClients.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final client = filteredClients[index];
            final name = client['name'] ?? 'Unknown Client';
            final domain = client['domain'] ?? 'No domain';
            final city = client['address_city'] ?? '';
            final state = client['address_state'] ?? '';
            final subscriptionType = client['subscription_type'] ?? 'N/A';
            final renewalDateStr = client['renew_date'];

            String location = '';
            if (city.isNotEmpty && state.isNotEmpty) {
              location = '$city, $state';
            } else if (city.isNotEmpty) {
              location = city;
            } else if (state.isNotEmpty) {
              location = state;
            }

            // Calculate days until renewal
            int? daysUntilRenewal;
            Color countdownColor = Colors.green;
            String renewalDisplay = 'N/A';

            if (renewalDateStr != null &&
                renewalDateStr.toString().isNotEmpty) {
              try {
                final renewalDate = DateTime.parse(renewalDateStr.toString());
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final renewal = DateTime(
                  renewalDate.year,
                  renewalDate.month,
                  renewalDate.day,
                );
                daysUntilRenewal = renewal.difference(today).inDays;

                // Format renewal date
                renewalDisplay =
                    '${renewalDate.month}/${renewalDate.day}/${renewalDate.year}';

                // Color coding based on days until renewal
                if (daysUntilRenewal <= 30) {
                  countdownColor = Colors.red;
                } else if (daysUntilRenewal <= 60) {
                  countdownColor = Colors.orange;
                } else {
                  countdownColor = Colors.green;
                }
              } catch (e) {
                // Invalid date format
              }
            }

            return InkWell(
              onTap: () => _showClientDetails(client),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Leading icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF001b3f), Color(0xFF004aad)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            domain,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.card_membership,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                subscriptionType,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                renewalDisplay,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              location,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Trailing countdown
                    if (daysUntilRenewal != null) ...[
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: countdownColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: countdownColor, width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              daysUntilRenewal < 0
                                  ? '${daysUntilRenewal.abs()}'
                                  : '$daysUntilRenewal',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: countdownColor,
                              ),
                            ),
                            Text(
                              daysUntilRenewal < 0 ? 'days\noverdue' : 'days',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: countdownColor,
                                height: 1.1,
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
          },
        ),
      ),
    );
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Client'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Client Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Save school
              Navigator.of(context).pop();
            },
            child: const Text('Add Client'),
          ),
        ],
      ),
    );
  }

  void _showEditClientDialog(Map<String, dynamic> client) {
    // TODO: Implement edit client dialog
  }

  void _showClientDetails(Map<String, dynamic> client) {
    Navigator.pushNamed(context, '/client-settings', arguments: client);
  }
}
