import 'package:flutter/material.dart';
import '../widgets/admin_scaffold.dart';
import '../services/api_service.dart';

class ClientSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> client;

  const ClientSettingsScreen({super.key, required this.client});

  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen> {
  final ApiService _apiService = ApiService();
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? settingsData;
  Map<String, dynamic>? schoolData;

  @override
  void initState() {
    super.initState();
    _loadClientSettings();
  }

  Future<void> _loadClientSettings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _apiService.getClientSettings(widget.client['schema_name']);
      if (data != null) {
        setState(() {
          settingsData = data['settings'];
          // Get the first school (client only has one)
          final schools = data['schools'] as List?;
          schoolData = (schools != null && schools.isNotEmpty) ? schools[0] : null;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load client settings';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Client Settings - ${widget.client['name']}',
      selectedIndex: 1,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
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
            'Failed to load settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(errorMessage ?? 'Unknown error'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loadClientSettings,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadClientSettings,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Info Card
            _buildClientInfoCard(),
            const SizedBox(height: 24),

            // School Information
            if (schoolData != null) ...[
              _buildSchoolCard(),
              const SizedBox(height: 24),
            ],

            // App Settings
            if (settingsData != null) ...[
              _buildAppSettingsCard(),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfoCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF001b3f), Color(0xFF004aad)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.client['name'] ?? 'Unknown Client',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.client['domain'] ?? 'No domain',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow('Schema Name', widget.client['schema_name'] ?? ''),
            _buildInfoRow('Organization Type', widget.client['organization_type'] ?? ''),
            _buildInfoRow('Account Type', widget.client['account_type'] ?? ''),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _showAdminsDialog,
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Get Admins'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF004aad),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, color: Color(0xFF004aad)),
                const SizedBox(width: 12),
                const Text(
                  'School Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Basic Info
            _buildSectionTitle('Basic Information'),
            _buildInfoRow('School Name', schoolData?['fullname'] ?? 'N/A'),
            _buildInfoRow('Address', schoolData?['address'] ?? 'N/A'),
            _buildInfoRow('City', schoolData?['address_city'] ?? 'N/A'),
            _buildInfoRow('State', schoolData?['address_state'] ?? 'N/A'),
            _buildInfoRow('Zipcode', schoolData?['address_zipcode']?.toString() ?? 'N/A'),
            _buildInfoRow('Booster Organization', schoolData?['booster_org'] ?? 'N/A'),
            if (schoolData?['grade_levels'] != null && (schoolData!['grade_levels'] as List).isNotEmpty)
              _buildInfoRow('Grade Levels', (schoolData!['grade_levels'] as List).join(', ')),
            if (schoolData?['school_groups'] != null && (schoolData!['school_groups'] as List).isNotEmpty)
              _buildInfoRow('School Groups', (schoolData!['school_groups'] as List).join(', ')),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Contact Information'),
            _buildInfoRow('Contact Name', schoolData?['contact_fullname'] ?? 'N/A'),
            _buildInfoRow('Phone 1', schoolData?['contact_phone1'] ?? 'N/A'),
            _buildInfoRow('Phone 2', schoolData?['contact_phone2'] ?? 'N/A'),
            _buildInfoRow('Google Calendar Link', schoolData?['google_cal_link'] ?? 'N/A'),
            _buildInfoRow('Invoice Reply-To Email', schoolData?['invoices_reply_to_email'] ?? 'N/A'),
            _buildInfoRow('Returned Email Recipients', schoolData?['returned_email_recipients'] ?? 'N/A'),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Branding'),
            _buildInfoRow('Primary Color', schoolData?['primary_color'] ?? 'N/A'),
            _buildInfoRow('Secondary Color', schoolData?['secondary_color'] ?? 'N/A'),
            if (schoolData?['background_img'] != null)
              _buildInfoRow('Background Image', schoolData?['background_img'] ?? ''),
            if (schoolData?['email_banner'] != null)
              _buildInfoRow('Email Banner', schoolData?['email_banner'] ?? ''),
            
            const SizedBox(height: 16),
            _buildSectionTitle('PayPal Settings'),
            _buildInfoRow('PayPal Fee Checkout', schoolData?['paypal_fee_checkout'] ?? 'N/A'),
            _buildInfoRow('PayPal Email', schoolData?['paypal_email_address'] ?? 'N/A'),
            _buildInfoRow('PayPal Fee %', schoolData?['paypal_fee_percentage'] ?? 'N/A'),
            _buildInfoRow('PayPal Fixed Fee', schoolData?['paypal_fixed_fee'] ?? 'N/A'),
            _buildInfoRow('PayPal MyShop Fee %', schoolData?['paypal_myshop_fee_percentage'] ?? 'N/A'),
            _buildInfoRow('PayPal MyShop Fixed Fee', schoolData?['paypal_myshop_fixed_fee'] ?? 'N/A'),
            _buildInfoRow('PayPal School Initials', schoolData?['paypal_school_initials'] ?? 'N/A'),
            _buildBoolRow('Advanced Checkout Active', schoolData?['activate_pp_advanced_checkout'] ?? false),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Fee Support Settings'),
            if (schoolData?['request_fee_support_help_text'] != null && schoolData!['request_fee_support_help_text'].isNotEmpty)
              _buildInfoRow('Fee Support Help Text', schoolData?['request_fee_support_help_text'] ?? ''),
            _buildInfoRow('Fee Support Recipient', schoolData?['request_fee_support_recipient'] ?? 'N/A'),
            _buildBoolRow('Can Split', schoolData?['can_split'] ?? false),
            _buildBoolRow('Can Unsplit', schoolData?['can_unsplit'] ?? false),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Account Options'),
            _buildBoolRow('Account Credits', schoolData?['account_credits'] ?? false),
            _buildBoolRow('Enable Account Credits', schoolData?['enable_account_credits'] ?? false),
            _buildBoolRow('Password Reset', schoolData?['password_reset'] ?? false),
            _buildBoolRow('Registration', schoolData?['registration'] ?? false),
            _buildBoolRow('Student ID', schoolData?['student_id'] ?? false),
            _buildBoolRow('Allergies', schoolData?['allergies'] ?? false),
            _buildBoolRow('Food Allergies', schoolData?['food_allergies'] ?? false),
            _buildBoolRow('OTC Medicines', schoolData?['otc_medicines'] ?? false),
            _buildBoolRow('Gender', schoolData?['gender'] ?? false),
            _buildBoolRow('Bus Number', schoolData?['bus_number'] ?? false),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettingsCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Color(0xFF004aad)),
                const SizedBox(width: 12),
                const Text(
                  'App Settings (myAppSettings)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            
            // General Settings
            _buildSectionTitle('General Settings'),
            _buildInfoRow('App Type', settingsData?['app_type'] ?? 'N/A'),
            _buildInfoRow('Subscription Type', settingsData?['subscription_type'] ?? 'N/A'),
            _buildInfoRow('Date Created', settingsData?['date_created'] ?? 'N/A'),
            _buildBoolRow('Trial Mode', settingsData?['is_trial'] ?? false),
            _buildBoolRow('Block Emails', settingsData?['block_emails'] ?? false),
            _buildBoolRow('Suspended', settingsData?['suspended'] ?? false),
            _buildBoolRow('Locked', settingsData?['locked'] ?? false),
            _buildBoolRow('Exception', settingsData?['exception'] ?? false),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Subscription Details'),
            _buildInfoRow('Renew Date', settingsData?['renew_date'] ?? 'N/A'),
            _buildInfoRow('Renew Cycle', settingsData?['renew_cycle'] ?? 'N/A'),
            _buildInfoRow('Annual Price', '\$${settingsData?['annual_price'] ?? 'N/A'}'),
            _buildInfoRow('Max Users', settingsData?['max_users']?.toString() ?? 'N/A'),
            _buildInfoRow('Max Emails/Day', settingsData?['max_emails_per_day']?.toString() ?? 'N/A'),
            _buildInfoRow('Preferred Payment', settingsData?['preferred_payment'] ?? 'N/A'),
            _buildInfoRow('Commission %', settingsData?['commission_percentage'] ?? 'N/A'),
            _buildBoolRow('Integrated PP Merchant', settingsData?['integrated_pp_merchant'] ?? false),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Payment History'),
            _buildInfoRow('Last Paid', settingsData?['last_paid'] ?? 'N/A'),
            _buildInfoRow('Last Payment Method', settingsData?['last_payment_method'] ?? 'N/A'),
            _buildInfoRow('Last Payment Amount', settingsData?['last_payment_amount'] ?? 'N/A'),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Account Limits'),
            _buildInfoRow('Parent Accounts', settingsData?['parent_accounts']?.toString() ?? '0'),
            _buildInfoRow('Student Accounts', settingsData?['student_accounts']?.toString() ?? '0'),
            _buildInfoRow('Directors Accounts', settingsData?['directors_accounts']?.toString() ?? '0'),
            
            const SizedBox(height: 16),
            _buildSectionTitle('MyBlueBoard API'),
            _buildInfoRow('Client ID', settingsData?['mybb_client_id'] ?? 'N/A'),
            _buildInfoRow('Files Max Size', settingsData?['myFiles_max_size'] ?? 'N/A'),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Enabled Modules'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFeatureChip('Email', settingsData?['myEmail'] == true),
                _buildFeatureChip('Board', settingsData?['myBoard'] == true),
                _buildFeatureChip('Files', settingsData?['myFiles'] == true),
                _buildFeatureChip('Financials', settingsData?['myFinancials'] == true),
                _buildFeatureChip('Attendance', settingsData?['myAttendance'] == true),
                _buildFeatureChip('Chat', settingsData?['myAttentanceComm'] == true),
                _buildFeatureChip('Forms', settingsData?['myForms'] == true),
                _buildFeatureChip('Inventory', settingsData?['myInventory'] == true),
                _buildFeatureChip('Shop', settingsData?['myShop'] == true),
                _buildFeatureChip('Timesheets', settingsData?['myTimesheets'] == true),
                _buildFeatureChip('Volunteers', settingsData?['myVolunteers'] == true),
                _buildFeatureChip('Digital Library', settingsData?['myDigitalLibrary'] == true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF004aad),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoolRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: value ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? Colors.green.shade300 : Colors.grey.shade300,
              ),
            ),
            child: Text(
              value ? 'Yes' : 'No',
              style: TextStyle(
                color: value ? Colors.green.shade900 : Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, bool enabled) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? Colors.green.shade900 : Colors.grey.shade700,
        ),
      ),
      backgroundColor: enabled ? Colors.green.shade50 : Colors.grey.shade100,
      side: BorderSide(
        color: enabled ? Colors.green.shade300 : Colors.grey.shade300,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  void _showAdminsDialog() async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final admins = await _apiService.getClientAdmins(widget.client['schema_name']);
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (admins == null || admins.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Admins Found'),
              content: const Text('No users with Admin Access were found for this client.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Show admins dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF004aad),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Admin Users',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${admins.length} ${admins.length == 1 ? 'user' : 'users'} with Admin Access',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // List of admins
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: admins.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final admin = admins[index];
                        final fullName = '${admin['first_name'] ?? ''} ${admin['last_name'] ?? ''}'.trim();
                        final isActive = admin['is_active'] ?? false;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isActive ? const Color(0xFF004aad) : Colors.grey,
                            child: Text(
                              (admin['first_name']?.toString().substring(0, 1) ?? 
                               admin['email']?.toString().substring(0, 1) ?? 'A').toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            fullName.isNotEmpty ? fullName : 'No name',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                admin['email'] ?? 'No email',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (admin['type'] != null)
                                    Chip(
                                      label: Text(
                                        admin['type'],
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isActive ? Colors.green.shade300 : Colors.red.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isActive ? Colors.green.shade900 : Colors.red.shade900,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade800),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (mounted) Navigator.of(context).pop();
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load admins: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
