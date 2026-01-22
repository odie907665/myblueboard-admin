import 'package:flutter/material.dart';
import '../widgets/admin_scaffold.dart';
import '../services/api_service.dart';
import 'compose_email_screen.dart';

/// Screen for displaying and managing comprehensive client settings.
///
/// This screen shows three main sections:
/// 1. Client Information (basic client data, domain, organization type)
/// 2. School Information (contact details, PayPal settings, account options)
/// 3. App Settings (subscription details, enabled modules, payment history)
///
/// Each section has edit functionality with dedicated dialogs that call
/// backend API endpoints to persist changes.
class ClientSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> client;

  const ClientSettingsScreen({super.key, required this.client});

  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen> {
  // API service for making backend calls
  final ApiService _apiService = ApiService();

  // Loading and error state management
  bool isLoading = true;
  String? errorMessage;

  // Data from backend API calls
  Map<String, dynamic>? settingsData; // App settings (myAppSettings table)
  Map<String, dynamic>?
  schoolData; // School information (single school per client)

  // Mutable copy of client data for immediate UI updates after edits
  // This allows the UI to reflect changes without reloading from API
  late Map<String, dynamic> currentClientData;

  @override
  void initState() {
    super.initState();
    // Create mutable copy of client data for immediate UI updates
    currentClientData = Map<String, dynamic>.from(widget.client);
    // Load school and app settings from backend
    _loadClientSettings();
  }

  /// Fetches client settings, school data, and app settings from the backend.
  ///
  /// This method:
  /// 1. Calls the API using the client's schema_name
  /// 2. Populates settingsData (app settings) and schoolData (school info)
  /// 3. Handles loading states and error messages
  ///
  /// Can be called on pull-to-refresh or retry after error.
  Future<void> _loadClientSettings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _apiService.getClientSettings(
        currentClientData['schema_name'],
      );
      print('Client settings data received: $data');
      if (data != null) {
        print('Settings data: ${data['settings']}');
        print('Schools data: ${data['schools']}');
        setState(() {
          settingsData = data['settings'];
          // Get the first school (client only has one)
          final schools = data['schools'] as List?;
          schoolData = (schools != null && schools.isNotEmpty)
              ? schools[0]
              : null;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load client settings';
        });
      }
    } catch (e) {
      print('Error in _loadClientSettings: $e');
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Main scaffold with three possible states: loading, error, or content
    return AdminScaffold(
      title: 'Client Settings - ${currentClientData['name']}',
      selectedIndex: 1, // Highlights 'Clients' in the navigation menu
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  /// Builds the error state UI with retry button.
  /// Displayed when API call fails or returns an error.
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

  /// Builds the main content with three settings cards.
  ///
  /// Wrapped in RefreshIndicator to allow pull-to-refresh.
  /// Cards are conditionally rendered based on data availability.
  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadClientSettings, // Pull down to reload all settings
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works even when content fits
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Info Card - Always displayed (uses currentClientData)
            _buildClientInfoCard(),
            const SizedBox(height: 24),

            // School Information Card - Only if school data exists
            if (schoolData != null) ...[
              _buildSchoolCard(),
              const SizedBox(height: 24),
            ],

            // App Settings Card - Only if settings data exists
            if (settingsData != null) ...[
              _buildAppSettingsCard(),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the Client Information card.
  ///
  /// Displays:
  /// - Client name and domain (in header with gradient icon)
  /// - Schema name, organization type, account type
  /// - Edit button to modify client details
  /// - Get Admins button to view/email admin users
  ///
  /// Uses currentClientData (mutable) so UI updates immediately after edits.
  Widget _buildClientInfoCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient icon, client name/domain, and edit button
            Row(
              children: [
                // Brand gradient icon container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF001b3f),
                        Color(0xFF004aad),
                      ], // Brand colors
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business, color: Colors.white),
                ),
                const SizedBox(width: 16),
                // Client name and domain
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentClientData['name'] ?? 'Unknown Client',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentClientData['domain'] ?? 'No domain',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Edit button (opens _showEditClientDialog)
                IconButton(
                  onPressed: _showEditClientDialog,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Client Info',
                ),
              ],
            ),
            const Divider(height: 32),
            // Read-only client details
            _buildInfoRow(
              'Schema Name',
              currentClientData['schema_name'] ?? '',
            ),
            _buildInfoRow(
              'Organization Type',
              currentClientData['organization_type'] ?? '',
            ),
            _buildInfoRow(
              'Account Type',
              currentClientData['account_type'] ?? '',
            ),
            const SizedBox(height: 16),
            // Button to fetch and display admin users
            FilledButton.icon(
              onPressed: _showAdminsDialog,
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Get Admins'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF004aad),
                foregroundColor:
                    Colors.white, // Ensures white text in both themes
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
                const Expanded(
                  child: Text(
                    'School Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _showEditSchoolDialog,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit School Info',
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
            _buildInfoRow(
              'Zipcode',
              schoolData?['address_zipcode']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Booster Organization',
              schoolData?['booster_org'] ?? 'N/A',
            ),
            if (schoolData?['grade_levels'] != null &&
                (schoolData!['grade_levels'] as List).isNotEmpty)
              _buildInfoRow(
                'Grade Levels',
                (schoolData!['grade_levels'] as List).join(', '),
              ),
            if (schoolData?['school_groups'] != null &&
                (schoolData!['school_groups'] as List).isNotEmpty)
              _buildInfoRow(
                'School Groups',
                (schoolData!['school_groups'] as List).join(', '),
              ),

            const SizedBox(height: 16),
            _buildSectionTitle('Contact Information'),
            _buildInfoRow(
              'Contact Name',
              schoolData?['contact_fullname'] ?? 'N/A',
            ),
            _buildInfoRow('Phone 1', schoolData?['contact_phone1'] ?? 'N/A'),
            _buildInfoRow('Phone 2', schoolData?['contact_phone2'] ?? 'N/A'),
            _buildInfoRow(
              'Google Calendar Link',
              schoolData?['google_cal_link'] ?? 'N/A',
            ),
            _buildInfoRow(
              'Invoice Reply-To Email',
              schoolData?['invoices_reply_to_email'] ?? 'N/A',
            ),
            _buildInfoRow(
              'Returned Email Recipients',
              schoolData?['returned_email_recipients'] ?? 'N/A',
            ),

            const SizedBox(height: 16),
            _buildSectionTitle('Branding'),
            _buildInfoRow(
              'Primary Color',
              schoolData?['primary_color'] ?? 'N/A',
            ),
            _buildInfoRow(
              'Secondary Color',
              schoolData?['secondary_color'] ?? 'N/A',
            ),
            if (schoolData?['background_img'] != null)
              _buildInfoRow(
                'Background Image',
                schoolData?['background_img'] ?? '',
              ),
            if (schoolData?['email_banner'] != null)
              _buildInfoRow('Email Banner', schoolData?['email_banner'] ?? ''),

            const SizedBox(height: 16),
            _buildSectionTitle('PayPal Settings'),
            _buildInfoRow(
              'PayPal Fee Checkout',
              schoolData?['paypal_fee_checkout'] ?? 'N/A',
            ),
            _buildInfoRow(
              'PayPal Email',
              schoolData?['paypal_email_address'] ?? 'N/A',
            ),
            _buildInfoRow(
              'PayPal Fee %',
              schoolData?['paypal_fee_percentage'] ?? 'N/A',
            ),
            _buildInfoRow(
              'PayPal Fixed Fee',
              schoolData?['paypal_fixed_fee'] ?? 'N/A',
            ),
            _buildInfoRow(
              'PayPal MyShop Fee %',
              schoolData?['paypal_myshop_fee_percentage'] ?? 'N/A',
            ),
            _buildInfoRow(
              'PayPal MyShop Fixed Fee',
              schoolData?['paypal_myshop_fixed_fee'] ?? 'N/A',
            ),
            _buildInfoRow(
              'PayPal School Initials',
              schoolData?['paypal_school_initials'] ?? 'N/A',
            ),
            _buildBoolRow(
              'Advanced Checkout Active',
              schoolData?['activate_pp_advanced_checkout'] ?? false,
            ),

            const SizedBox(height: 16),
            _buildSectionTitle('Fee Support Settings'),
            if (schoolData?['request_fee_support_help_text'] != null &&
                schoolData!['request_fee_support_help_text'].isNotEmpty)
              _buildInfoRow(
                'Fee Support Help Text',
                schoolData?['request_fee_support_help_text'] ?? '',
              ),
            _buildInfoRow(
              'Fee Support Recipient',
              schoolData?['request_fee_support_recipient'] ?? 'N/A',
            ),
            _buildBoolRow('Can Split', schoolData?['can_split'] ?? false),
            _buildBoolRow('Can Unsplit', schoolData?['can_unsplit'] ?? false),

            const SizedBox(height: 16),
            _buildSectionTitle('Account Options'),
            _buildBoolRow(
              'Account Credits',
              schoolData?['account_credits'] ?? false,
            ),
            _buildBoolRow(
              'Enable Account Credits',
              schoolData?['enable_account_credits'] ?? false,
            ),
            _buildBoolRow(
              'Password Reset',
              schoolData?['password_reset'] ?? false,
            ),
            _buildBoolRow('Registration', schoolData?['registration'] ?? false),
            _buildBoolRow('Student ID', schoolData?['student_id'] ?? false),
            _buildBoolRow('Allergies', schoolData?['allergies'] ?? false),
            _buildBoolRow(
              'Food Allergies',
              schoolData?['food_allergies'] ?? false,
            ),
            _buildBoolRow(
              'OTC Medicines',
              schoolData?['otc_medicines'] ?? false,
            ),
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
                const Expanded(
                  child: Text(
                    'App Settings (myAppSettings)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _showEditAppSettingsDialog,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit App Settings',
                ),
              ],
            ),
            const Divider(height: 32),

            // General Settings
            _buildSectionTitle('General Settings'),
            _buildInfoRow('App Type', settingsData?['app_type'] ?? 'N/A'),
            _buildInfoRow(
              'Subscription Type',
              settingsData?['subscription_type'] ?? 'N/A',
            ),
            _buildInfoRow(
              'Date Created',
              settingsData?['date_created'] ?? 'N/A',
            ),
            _buildBoolRow('Trial Mode', settingsData?['is_trial'] ?? false),
            _buildBoolRow(
              'Block Emails',
              settingsData?['block_emails'] ?? false,
            ),
            _buildBoolRow('Suspended', settingsData?['suspended'] ?? false),
            _buildBoolRow('Locked', settingsData?['locked'] ?? false),
            _buildBoolRow('Exception', settingsData?['exception'] ?? false),

            const SizedBox(height: 16),
            _buildSectionTitle('Subscription Details'),
            _buildInfoRow('Renew Date', settingsData?['renew_date'] ?? 'N/A'),
            _buildInfoRow('Renew Cycle', settingsData?['renew_cycle'] ?? 'N/A'),
            _buildInfoRow(
              'Annual Price',
              '\$${settingsData?['annual_price'] ?? 'N/A'}',
            ),
            _buildInfoRow(
              'Max Users',
              settingsData?['max_users']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Max Emails/Day',
              settingsData?['max_emails_per_day']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Preferred Payment',
              settingsData?['preferred_payment'] ?? 'N/A',
            ),
            _buildInfoRow(
              'Commission %',
              settingsData?['commission_percentage'] ?? 'N/A',
            ),
            _buildBoolRow(
              'Integrated PP Merchant',
              settingsData?['integrated_pp_merchant'] ?? false,
            ),

            const SizedBox(height: 16),
            _buildSectionTitle('Payment History'),
            _buildInfoRow('Last Paid', settingsData?['last_paid'] ?? 'N/A'),
            _buildInfoRow(
              'Last Payment Method',
              settingsData?['last_payment_method'] ?? 'N/A',
            ),
            _buildInfoRow(
              'Last Payment Amount',
              settingsData?['last_payment_amount'] ?? 'N/A',
            ),

            const SizedBox(height: 16),
            _buildSectionTitle('Account Limits'),
            _buildInfoRow(
              'Parent Accounts',
              settingsData?['parent_accounts']?.toString() ?? '0',
            ),
            _buildInfoRow(
              'Student Accounts',
              settingsData?['student_accounts']?.toString() ?? '0',
            ),
            _buildInfoRow(
              'Directors Accounts',
              settingsData?['directors_accounts']?.toString() ?? '0',
            ),

            const SizedBox(height: 16),
            _buildSectionTitle('MyBlueBoard API'),
            _buildInfoRow(
              'Client ID',
              settingsData?['mybb_client_id'] ?? 'N/A',
            ),
            _buildInfoRow(
              'Files Max Size',
              settingsData?['myFiles_max_size'] ?? 'N/A',
            ),

            const SizedBox(height: 16),
            _buildSectionTitle('Enabled Modules'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFeatureChip('myEmail', settingsData?['myEmail'] == true),
                _buildFeatureChip('myBoard', settingsData?['myBoard'] == true),
                _buildFeatureChip('myFiles', settingsData?['myFiles'] == true),
                _buildFeatureChip(
                  'myFinancials',
                  settingsData?['myFinancials'] == true,
                ),
                _buildFeatureChip(
                  'myTickets',
                  settingsData?['myTickets'] == true,
                ),
                _buildFeatureChip('myChat', settingsData?['myChat'] == true),
                _buildFeatureChip(
                  'myAttendance Community',
                  settingsData?['myAttendanceComm'] == true,
                ),
                _buildFeatureChip('myForms', settingsData?['myForms'] == true),
                _buildFeatureChip(
                  'myInventory',
                  settingsData?['myInventory'] == true,
                ),
                _buildFeatureChip('myShop', settingsData?['myShop'] == true),
                _buildFeatureChip(
                  'myVolunteers',
                  settingsData?['myVolunteers'] == true,
                ),
                _buildFeatureChip(
                  'myMusic',
                  settingsData?['myDigitalLibrary'] == true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a styled section title within settings cards.
  /// Used to group related settings (e.g., "Basic Information", "PayPal Settings").
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF004aad), // Brand color for section headers
        ),
      ),
    );
  }

  /// Builds a label-value row for displaying read-only text data.
  /// Used throughout all three cards for consistent formatting.
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
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a label-value row for displaying boolean data.
  ///
  /// Shows:
  /// - Green "Yes" badge when true
  /// - Grey "No" badge when false
  ///
  /// Used for settings like "Trial Mode", "Suspended", account options, etc.
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
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ),
          // Badge showing Yes/No with color coding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: value ? Colors.green[100] : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? Colors.green[600]! : Colors.grey.shade300,
                width: value
                    ? 1.5
                    : 1, // Thicker border for green to make it more prominent
              ),
            ),
            child: Text(
              value ? 'Yes' : 'No',
              style: TextStyle(
                color: value ? Colors.green[800]! : Colors.grey.shade700,
                fontSize: 13,
                fontWeight:
                    FontWeight.w600, // Bolder font for better visibility
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a chip for displaying enabled/disabled module features.
  /// Used in the "Enabled Modules" section of App Settings card.
  Widget _buildFeatureChip(String label, bool enabled) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? Colors.green[800]! : Colors.grey.shade700,
          fontWeight: enabled
              ? FontWeight.w600
              : FontWeight.normal, // Bold when enabled
        ),
      ),
      backgroundColor: enabled ? Colors.green[100] : Colors.grey.shade100,
      side: BorderSide(
        color: enabled ? Colors.green[600]! : Colors.grey.shade300,
        width: enabled ? 1.5 : 1, // Thicker border for enabled modules
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  void _showAdminsDialog() async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final admins = await _apiService.getClientAdmins(
        currentClientData['schema_name'],
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (admins == null || admins.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Admins Found'),
              content: const Text(
                'No users with Admin Access were found for this client.',
              ),
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
                        const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                        ),
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
                        final fullName =
                            '${admin['first_name'] ?? ''} ${admin['last_name'] ?? ''}'
                                .trim();
                        final isActive = admin['is_active'] ?? false;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? const Color(0xFF004aad)
                                : Colors.grey,
                            child: Text(
                              (admin['first_name']?.toString().substring(
                                        0,
                                        1,
                                      ) ??
                                      admin['email']?.toString().substring(
                                        0,
                                        1,
                                      ) ??
                                      'A')
                                  .toUpperCase(),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isActive
                                            ? Colors.green.shade300
                                            : Colors.red.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isActive
                                            ? Colors.green.shade900
                                            : Colors.red.shade900,
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
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.white
                          : Theme.of(context).dialogBackgroundColor,
                      border: Border(
                        top: BorderSide(
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            // Extract email addresses from admins
                            final emailAddresses = admins
                                .map(
                                  (admin) => admin['email']?.toString() ?? '',
                                )
                                .where((email) => email.isNotEmpty)
                                .toList();

                            // Close the dialog
                            Navigator.of(context).pop();

                            // Navigate to compose email screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ComposeEmailScreen(
                                  toEmails: emailAddresses,
                                  subject:
                                      'Message to ${currentClientData['name']} Admins',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.email),
                          label: const Text('Email Admins'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF004aad),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
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

  void _showEditClientDialog() {
    final nameController = TextEditingController(
      text: currentClientData['name'],
    );
    final domainController = TextEditingController(
      text: currentClientData['domain'],
    );
    final orgTypeController = TextEditingController(
      text: currentClientData['organization_type'],
    );
    final accountTypeController = TextEditingController(
      text: currentClientData['account_type'],
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF004aad),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Edit Client Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Client Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: domainController,
                          decoration: const InputDecoration(
                            labelText: 'Domain',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: orgTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Organization Type',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: accountTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Account Type',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : Theme.of(context).dialogBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            final success = await _apiService.updateClient(
                              currentClientData['schema_name'],
                              {
                                'name': nameController.text,
                                'domain': domainController.text,
                                'organization_type': orgTypeController.text,
                                'account_type': accountTypeController.text,
                              },
                            );

                            if (mounted) {
                              Navigator.of(context).pop();
                              if (success) {
                                // Update the current client data
                                setState(() {
                                  currentClientData['name'] =
                                      nameController.text;
                                  currentClientData['domain'] =
                                      domainController.text;
                                  currentClientData['organization_type'] =
                                      orgTypeController.text;
                                  currentClientData['account_type'] =
                                      accountTypeController.text;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Client updated successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to update client'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF004aad),
                        foregroundColor: Colors.white,
                      ),
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

  void _showEditSchoolDialog() {
    if (schoolData == null) return;

    final formKey = GlobalKey<FormState>();

    // Boolean fields state
    final booleanFields = {
      'can_split': schoolData?['can_split'] ?? false,
      'can_unsplit': schoolData?['can_unsplit'] ?? false,
      'activate_pp_advanced_checkout':
          schoolData?['activate_pp_advanced_checkout'] ?? false,
      'account_credits': schoolData?['account_credits'] ?? false,
      'enable_account_credits': schoolData?['enable_account_credits'] ?? false,
      'password_reset': schoolData?['password_reset'] ?? false,
      'registration': schoolData?['registration'] ?? false,
      'student_id': schoolData?['student_id'] ?? false,
      'allergies': schoolData?['allergies'] ?? false,
      'food_allergies': schoolData?['food_allergies'] ?? false,
      'otc_medicines': schoolData?['otc_medicines'] ?? false,
      'gender': schoolData?['gender'] ?? false,
      'bus_number': schoolData?['bus_number'] ?? false,
    };

    final controllers = {
      'fullname': TextEditingController(text: schoolData?['fullname']),
      'address': TextEditingController(text: schoolData?['address']),
      'address_city': TextEditingController(text: schoolData?['address_city']),
      'address_state': TextEditingController(
        text: schoolData?['address_state'],
      ),
      'address_zipcode': TextEditingController(
        text: schoolData?['address_zipcode']?.toString(),
      ),
      'booster_org': TextEditingController(text: schoolData?['booster_org']),
      'contact_fullname': TextEditingController(
        text: schoolData?['contact_fullname'],
      ),
      'contact_phone1': TextEditingController(
        text: schoolData?['contact_phone1'],
      ),
      'contact_phone2': TextEditingController(
        text: schoolData?['contact_phone2'],
      ),
      'google_cal_link': TextEditingController(
        text: schoolData?['google_cal_link'],
      ),
      'invoices_reply_to_email': TextEditingController(
        text: schoolData?['invoices_reply_to_email'],
      ),
      'returned_email_recipients': TextEditingController(
        text: schoolData?['returned_email_recipients'],
      ),
      'primary_color': TextEditingController(
        text: schoolData?['primary_color'],
      ),
      'secondary_color': TextEditingController(
        text: schoolData?['secondary_color'],
      ),
      'paypal_fee_checkout': TextEditingController(
        text: schoolData?['paypal_fee_checkout'],
      ),
      'paypal_email_address': TextEditingController(
        text: schoolData?['paypal_email_address'],
      ),
      'paypal_fee_percentage': TextEditingController(
        text: schoolData?['paypal_fee_percentage'],
      ),
      'paypal_fixed_fee': TextEditingController(
        text: schoolData?['paypal_fixed_fee'],
      ),
      'paypal_myshop_fee_percentage': TextEditingController(
        text: schoolData?['paypal_myshop_fee_percentage'],
      ),
      'paypal_myshop_fixed_fee': TextEditingController(
        text: schoolData?['paypal_myshop_fixed_fee'],
      ),
      'paypal_school_initials': TextEditingController(
        text: schoolData?['paypal_school_initials'],
      ),
      'request_fee_support_help_text': TextEditingController(
        text: schoolData?['request_fee_support_help_text'],
      ),
      'request_fee_support_recipient': TextEditingController(
        text: schoolData?['request_fee_support_recipient'],
      ),
    };

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF004aad),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Edit School Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: controllers['fullname'],
                          decoration: const InputDecoration(
                            labelText: 'School Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['address'],
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controllers['address_city'],
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: controllers['address_state'],
                                decoration: const InputDecoration(
                                  labelText: 'State',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['address_zipcode'],
                          decoration: const InputDecoration(
                            labelText: 'Zipcode',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['booster_org'],
                          decoration: const InputDecoration(
                            labelText: 'Booster Organization',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: controllers['contact_fullname'],
                          decoration: const InputDecoration(
                            labelText: 'Contact Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['contact_phone1'],
                          decoration: const InputDecoration(
                            labelText: 'Phone 1',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['contact_phone2'],
                          decoration: const InputDecoration(
                            labelText: 'Phone 2',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['google_cal_link'],
                          decoration: const InputDecoration(
                            labelText: 'Google Calendar Link',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['invoices_reply_to_email'],
                          decoration: const InputDecoration(
                            labelText: 'Invoice Reply-To Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['returned_email_recipients'],
                          decoration: const InputDecoration(
                            labelText: 'Returned Email Recipients',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Branding',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controllers['primary_color'],
                                decoration: const InputDecoration(
                                  labelText: 'Primary Color',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: controllers['secondary_color'],
                                decoration: const InputDecoration(
                                  labelText: 'Secondary Color',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'PayPal Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: controllers['paypal_email_address'],
                          decoration: const InputDecoration(
                            labelText: 'PayPal Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['paypal_fee_checkout'],
                          decoration: const InputDecoration(
                            labelText: 'PayPal Fee Checkout',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller:
                                    controllers['paypal_fee_percentage'],
                                decoration: const InputDecoration(
                                  labelText: 'Fee %',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: controllers['paypal_fixed_fee'],
                                decoration: const InputDecoration(
                                  labelText: 'Fixed Fee',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['paypal_school_initials'],
                          decoration: const InputDecoration(
                            labelText: 'School Initials',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Account Options',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StatefulBuilder(
                          builder: (context, setState) => Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Can Split'),
                                value: booleanFields['can_split']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['can_split'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Can Unsplit'),
                                value: booleanFields['can_unsplit']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['can_unsplit'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Advanced Checkout Active'),
                                value:
                                    booleanFields['activate_pp_advanced_checkout']!,
                                onChanged: (value) => setState(
                                  () =>
                                      booleanFields['activate_pp_advanced_checkout'] =
                                          value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Account Credits'),
                                value: booleanFields['account_credits']!,
                                onChanged: (value) => setState(
                                  () =>
                                      booleanFields['account_credits'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Enable Account Credits'),
                                value: booleanFields['enable_account_credits']!,
                                onChanged: (value) => setState(
                                  () =>
                                      booleanFields['enable_account_credits'] =
                                          value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Password Reset'),
                                value: booleanFields['password_reset']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['password_reset'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Registration'),
                                value: booleanFields['registration']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['registration'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Student ID'),
                                value: booleanFields['student_id']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['student_id'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Allergies'),
                                value: booleanFields['allergies']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['allergies'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Food Allergies'),
                                value: booleanFields['food_allergies']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['food_allergies'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('OTC Medicines'),
                                value: booleanFields['otc_medicines']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['otc_medicines'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Gender'),
                                value: booleanFields['gender']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['gender'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Bus Number'),
                                value: booleanFields['bus_number']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['bus_number'] = value,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : Theme.of(context).dialogBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            // Build school data from controllers
                            final schoolData = <String, dynamic>{};
                            controllers.forEach((key, controller) {
                              if (controller.text.isNotEmpty) {
                                schoolData[key] = controller.text;
                              }
                            });

                            // Add boolean fields
                            schoolData.addAll(booleanFields);

                            final success = await _apiService.updateSchool(
                              currentClientData['schema_name'],
                              schoolData,
                            );

                            if (mounted) {
                              Navigator.of(context).pop();
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'School updated successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                // Reload settings to show updated data
                                _loadClientSettings();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to update school'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF004aad),
                        foregroundColor: Colors.white,
                      ),
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

  void _showEditAppSettingsDialog() {
    if (settingsData == null) return;

    final formKey = GlobalKey<FormState>();

    // Boolean fields state
    final booleanFields = {
      'is_trial': settingsData?['is_trial'] ?? false,
      'block_emails': settingsData?['block_emails'] ?? false,
      'suspended': settingsData?['suspended'] ?? false,
      'locked': settingsData?['locked'] ?? false,
      'exception': settingsData?['exception'] ?? false,
      'integrated_pp_merchant':
          settingsData?['integrated_pp_merchant'] ?? false,
      'myEmail': settingsData?['myEmail'] ?? false,
      'myBoard': settingsData?['myBoard'] ?? false,
      'myFiles': settingsData?['myFiles'] ?? false,
      'myFinancials': settingsData?['myFinancials'] ?? false,
      'myTickets': settingsData?['myTickets'] ?? false,
      'myChat': settingsData?['myChat'] ?? false,
      'myAttendanceComm': settingsData?['myAttendanceComm'] ?? false,
      'myForms': settingsData?['myForms'] ?? false,
      'myInventory': settingsData?['myInventory'] ?? false,
      'myShop': settingsData?['myShop'] ?? false,
      'myVolunteers': settingsData?['myVolunteers'] ?? false,
      'myDigitalLibrary': settingsData?['myDigitalLibrary'] ?? false,
    };

    final controllers = {
      'app_type': TextEditingController(text: settingsData?['app_type']),
      'subscription_type': TextEditingController(
        text: settingsData?['subscription_type'],
      ),
      'renew_cycle': TextEditingController(text: settingsData?['renew_cycle']),
      'renew_date': TextEditingController(text: settingsData?['renew_date']),
      'annual_price': TextEditingController(
        text: settingsData?['annual_price'],
      ),
      'max_users': TextEditingController(
        text: settingsData?['max_users']?.toString(),
      ),
      'max_emails_per_day': TextEditingController(
        text: settingsData?['max_emails_per_day']?.toString(),
      ),
      'preferred_payment': TextEditingController(
        text: settingsData?['preferred_payment'],
      ),
      'commission_percentage': TextEditingController(
        text: settingsData?['commission_percentage'],
      ),
      'last_paid': TextEditingController(text: settingsData?['last_paid']),
      'last_payment_method': TextEditingController(
        text: settingsData?['last_payment_method'],
      ),
      'last_payment_amount': TextEditingController(
        text: settingsData?['last_payment_amount'],
      ),
      'mybb_client_id': TextEditingController(
        text: settingsData?['mybb_client_id'],
      ),
      'myFiles_max_size': TextEditingController(
        text: settingsData?['myFiles_max_size'],
      ),
    };

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF004aad),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Edit App Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'General Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: controllers['app_type'],
                          decoration: const InputDecoration(
                            labelText: 'App Type',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['subscription_type'],
                          decoration: const InputDecoration(
                            labelText: 'Subscription Type',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Subscription Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: controllers['renew_cycle'],
                          decoration: const InputDecoration(
                            labelText: 'Renew Cycle',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['renew_date'],
                          decoration: InputDecoration(
                            labelText: 'Renew Date',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  controllers['renew_date']!.text =
                                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                }
                              },
                            ),
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['annual_price'],
                          decoration: const InputDecoration(
                            labelText: 'Annual Price',
                            border: OutlineInputBorder(),
                            prefixText: '\$',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controllers['max_users'],
                                decoration: const InputDecoration(
                                  labelText: 'Max Users',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: controllers['max_emails_per_day'],
                                decoration: const InputDecoration(
                                  labelText: 'Max Emails/Day',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['preferred_payment'],
                          decoration: const InputDecoration(
                            labelText: 'Preferred Payment',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['commission_percentage'],
                          decoration: const InputDecoration(
                            labelText: 'Commission %',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Payment History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: controllers['last_paid'],
                          decoration: InputDecoration(
                            labelText: 'Last Paid Date',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  controllers['last_paid']!.text =
                                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                }
                              },
                            ),
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['last_payment_method'],
                          decoration: const InputDecoration(
                            labelText: 'Last Payment Method',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['last_payment_amount'],
                          decoration: const InputDecoration(
                            labelText: 'Last Payment Amount',
                            border: OutlineInputBorder(),
                            prefixText: '\$',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'MyBlueBoard API',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: controllers['mybb_client_id'],
                          decoration: const InputDecoration(
                            labelText: 'Client ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controllers['myFiles_max_size'],
                          decoration: const InputDecoration(
                            labelText: 'Files Max Size',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Status Flags',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StatefulBuilder(
                          builder: (context, setState) => Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Trial Account'),
                                value: booleanFields['is_trial']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['is_trial'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Block Emails'),
                                value: booleanFields['block_emails']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['block_emails'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Suspended'),
                                value: booleanFields['suspended']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['suspended'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Locked'),
                                value: booleanFields['locked']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['locked'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Exception'),
                                value: booleanFields['exception']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['exception'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('Integrated PayPal Merchant'),
                                value: booleanFields['integrated_pp_merchant']!,
                                onChanged: (value) => setState(
                                  () =>
                                      booleanFields['integrated_pp_merchant'] =
                                          value,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Enabled Modules',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StatefulBuilder(
                          builder: (context, setState) => Column(
                            children: [
                              SwitchListTile(
                                title: const Text('myEmail Module'),
                                value: booleanFields['myEmail']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['myEmail'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('myBoard Module'),
                                value: booleanFields['myBoard']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['myBoard'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('myFiles Module'),
                                value: booleanFields['myFiles']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['myFiles'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('myFinancials Module'),
                                value: booleanFields['myFinancials']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['myFinancials'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('myTickets Module'),
                                value: booleanFields['myTickets']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['myTickets'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('myChat Module'),
                                value: booleanFields['myChat']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['myChat'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text(
                                  'myAttendance Community Module',
                                ),
                                value: booleanFields['myAttendanceComm']!,
                                onChanged: (value) => setState(
                                  () =>
                                      booleanFields['myAttendanceComm'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('myForms Module'),
                                value: booleanFields['myForms']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['myForms'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('myInventory Module'),
                                value: booleanFields['myInventory']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['myInventory'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('myShop Module'),
                                value: booleanFields['myShop']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['myShop'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('myVolunteers Module'),
                                value: booleanFields['myVolunteers']!,
                                onChanged: (value) => setState(
                                  () => booleanFields['myVolunteers'] = value,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text('myMusic Module'),
                                value: booleanFields['myDigitalLibrary']!,
                                onChanged: (value) => setState(
                                  () =>
                                      booleanFields['myDigitalLibrary'] = value,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : Theme.of(context).dialogBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            // Build settings data from controllers
                            final settingsData = <String, dynamic>{};
                            controllers.forEach((key, controller) {
                              // Always include date fields even if empty
                              if (key == 'renew_date' ||
                                  key == 'last_paid' ||
                                  controller.text.isNotEmpty) {
                                settingsData[key] = controller.text;
                              }
                            });

                            // Add boolean fields
                            settingsData.addAll(booleanFields);

                            final success = await _apiService.updateAppSettings(
                              currentClientData['schema_name'],
                              settingsData,
                            );

                            if (mounted) {
                              Navigator.of(context).pop();
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'App settings updated successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                // Reload settings to show updated data
                                _loadClientSettings();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Failed to update app settings',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF004aad),
                        foregroundColor: Colors.white,
                      ),
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
}
