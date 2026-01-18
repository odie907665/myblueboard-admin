import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../config/environment.dart';

class AdminScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final int selectedIndex;

  const AdminScaffold({
    super.key,
    required this.body,
    required this.title,
    this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      drawer: isDesktop ? null : _buildDrawer(context, authProvider, user),
      body: Builder(
        builder: (scaffoldContext) => Row(
          children: [
            // Sidebar Navigation (only on desktop)
            if (isDesktop) ...[
              NavigationRail(
                extended: true,
                minExtendedWidth: 200,
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  _navigateToScreen(context, index);
                },
                leading: _buildLogoSection(context),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.business_outlined),
                    selectedIcon: Icon(Icons.business),
                    label: Text('Clients'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outlined),
                    selectedIcon: Icon(Icons.people),
                    label: Text('Users'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.account_balance_outlined),
                    selectedIcon: Icon(Icons.account_balance),
                    label: Text('Accounts'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.confirmation_number_outlined),
                    selectedIcon: Icon(Icons.confirmation_number),
                    label: Text('Tickets'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
            ],
            // Main Content Area
            Expanded(
              child: SafeArea(
                child: Column(
                  children: [
                    // Top App Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 24 : 8,
                        vertical: isDesktop ? 16 : 12,
                      ),
                      child: Row(
                        children: [
                          // Hamburger menu for mobile
                          if (!isDesktop) ...[
                            IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () {
                                Scaffold.of(scaffoldContext).openDrawer();
                              },
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isDesktop ? null : 18,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const Spacer(),
                        // Theme Toggle
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, _) {
                            return IconButton(
                              icon: Icon(
                                themeProvider.isDarkMode
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                              ),
                              onPressed: () => themeProvider.toggleTheme(),
                              tooltip: themeProvider.isDarkMode
                                  ? 'Switch to Light Mode'
                                  : 'Switch to Dark Mode',
                            );
                          },
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 8),
                          // User Profile Menu
                          PopupMenuButton<String>(
                            offset: const Offset(0, 50),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF004aad),
                                  child: Text(
                                    user?['email']?.toString().substring(0, 1).toUpperCase() ?? 'A',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      user?['email']?.toString() ?? 'Admin',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      user?['role']?.toString() ?? 'Administrator',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                            itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline),
                                  SizedBox(width: 12),
                                  Text('Profile'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'settings',
                              child: Row(
                                children: [
                                  Icon(Icons.settings_outlined),
                                  SizedBox(width: 12),
                                  Text('Settings'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Logout', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (String value) async {
                            if (value == 'logout') {
                              await authProvider.logout();
                              if (context.mounted) {
                                Navigator.of(context).pushReplacementNamed('/login');
                              }
                            } else if (value == 'settings') {
                              _navigateToScreen(context, 5);
                            } else if (value == 'profile') {
                              // TODO: Navigate to profile page
                            }
                          },
                        ),
                      ],
                      ],
                    ),
                  ),
                ),
                // Content Area
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.background,
                    child: body,
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    String route;
    switch (index) {
      case 0:
        route = '/dashboard';
        break;
      case 1:
        route = '/clients';
        break;
      case 2:
        route = '/users';
        break;
      case 3:
        route = '/accounts';
        break;
      case 4:
        route = '/tickets';
        break;
      case 5:
        route = '/settings';
        break;
      default:
        route = '/dashboard';
    }

    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  Widget _buildLogoSection(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF001b3f), Color(0xFF004aad)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            'assets/images/mybb_logo.png',
            width: 40,
            height: 40,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'myblueboard',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: EnvironmentConfig.isDev
                ? Colors.orange.withOpacity(0.2)
                : Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: EnvironmentConfig.isDev
                  ? Colors.orange
                  : Colors.green,
              width: 1,
            ),
          ),
          child: Text(
            EnvironmentConfig.isDev ? 'DEV' : 'PROD',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: EnvironmentConfig.isDev
                  ? Colors.orange
                  : Colors.green,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider, Map<String, dynamic>? user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF001b3f), Color(0xFF004aad)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        'assets/images/mybb_logo.png',
                        width: 32,
                        height: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'myblueboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: EnvironmentConfig.isDev
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    EnvironmentConfig.isDev ? 'DEV' : 'PROD',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  user?['email']?.toString() ?? 'Admin',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: selectedIndex == 0,
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Clients'),
            selected: selectedIndex == 1,
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Users'),
            selected: selectedIndex == 2,
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance),
            title: const Text('Accounts'),
            selected: selectedIndex == 3,
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.confirmation_number),
            title: const Text('Tickets'),
            selected: selectedIndex == 4,
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 4);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            selected: selectedIndex == 5,
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 5);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
