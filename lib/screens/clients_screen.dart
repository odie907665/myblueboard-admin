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
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final clientsData = await _apiService.getClients();
      setState(() {
        clients = clientsData;
        filteredClients = clientsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _filterClients(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredClients = clients;
      } else {
        filteredClients = clients.where((client) {
          final name = client['name']?.toString().toLowerCase() ?? '';
          final domain = client['domain']?.toString().toLowerCase() ?? '';
          final schemaName = client['schema_name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          
          return name.contains(searchLower) || 
                 domain.contains(searchLower) ||
                 schemaName.contains(searchLower);
        }).toList();
      }
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
                                hintText: 'Search clients by name, domain, or schema...',
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
                  Row(
                    children: [
                      _buildStatChip(
                        'Total Clients',
                        '${clients.length}',
                        Icons.business,
                        const Color(0xFF004aad),
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

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
            
            String location = '';
            if (city.isNotEmpty && state.isNotEmpty) {
              location = '$city, $state';
            } else if (city.isNotEmpty) {
              location = city;
            } else if (state.isNotEmpty) {
              location = state;
            }

            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF001b3f), Color(0xFF004aad)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.business, color: Colors.white, size: 24),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(domain),
                  if (location.isNotEmpty)
                    Text(
                      location,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditClientDialog(client),
              ),
              onTap: () => _showClientDetails(client),
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
    final name = client['name'] ?? 'Unknown';
    final domain = client['domain'] ?? 'No domain';
    final schemaName = client['schema_name'] ?? '';
    final orgType = client['organization_type'] ?? 'Unknown';
    final accountType = client['account_type'] ?? 'N/A';
    final city = client['address_city'] ?? '';
    final state = client['address_state'] ?? '';
    final zipcode = client['address_zipcode']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.business, color: Color(0xFF004aad)),
            const SizedBox(width: 12),
            Expanded(child: Text(name)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Domain', domain),
              _buildDetailRow('Schema Name', schemaName),
              _buildDetailRow('Organization Type', orgType),
              _buildDetailRow('Account Type', accountType),
              if (city.isNotEmpty) _buildDetailRow('City', city),
              if (state.isNotEmpty) _buildDetailRow('State', state),
              if (zipcode.isNotEmpty) _buildDetailRow('Zipcode', zipcode),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(
                context,
                '/client-settings',
                arguments: client,
              );
            },
            icon: const Icon(Icons.settings),
            label: const Text('Show Client Settings'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditClientDialog(client);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
