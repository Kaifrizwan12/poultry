import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/route_manager.dart';
import 'package:farm_mgt_auth/modules/accounts_reports/accounts_reports_scope.dart';
import 'package:farm_mgt_auth/modules/accounts_reports/controllers/accounts_reports_nav_controller.dart';
import 'package:farm_mgt_auth/modules/accounts_reports/views/accounts_reports_screen.dart';
import 'package:farm_mgt_auth/modules/auth/models/user_model.dart';
import 'package:farm_mgt_auth/modules/home/home_screen.dart';
import 'package:farm_mgt_auth/modules/invoicing/controllers/invoicing_nav_controller.dart';
import 'package:farm_mgt_auth/modules/invoicing/invoicing_scope.dart';
import 'package:farm_mgt_auth/modules/invoicing/views/invoicing_screen.dart';
import 'package:farm_mgt_auth/modules/invoicing/views/transactions_screen.dart';
import 'package:farm_mgt_auth/modules/poultry/poultry_scope.dart';
import 'package:farm_mgt_auth/modules/poultry/views/poultry_screen.dart';
import 'package:farm_mgt_auth/modules/settings/views/settings_screen.dart';
import 'package:farm_mgt_auth/modules/settings/widgets/settings_scope.dart';
import 'package:farm_mgt_auth/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.initialModuleIndex,
    this.initialSettingsCategoryId,
  });

  final int initialModuleIndex;
  final String? initialSettingsCategoryId;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex;
  bool _railExtended = true;
  bool _desktopExpanded = true;

  final List<_ShellModule> _modules = const [
    _ShellModule('Home', Icons.home_outlined),
    _ShellModule('Settings', Icons.tune_outlined),
    _ShellModule('Invoicing', Icons.receipt_long_outlined),
    _ShellModule('Transactions', Icons.swap_horiz_outlined),
    _ShellModule('Poultry', Icons.egg_outlined),
    _ShellModule('Reports', Icons.bar_chart_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialModuleIndex;
  }

  void _selectModule(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = LocalStorageService.cachedUser();

    return SettingsScope(
      initialCategoryId: widget.initialSettingsCategoryId,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (width < 600) {
            return _buildMobileShell(context, user);
          }
          if (width <= 1024) {
            return _buildTabletShell(context, user);
          }
          return _buildDesktopShell(context, user);
        },
      ),
    );
  }

  Widget _buildMobileShell(BuildContext context, UserModel? user) {
    return _wrapMobileModuleScope(
      Builder(builder: (context) {
        return Scaffold(
          appBar: _buildMobileAppBar(context),
          drawer: Drawer(
            backgroundColor: AppTheme.sidebarBg,
            child: Container(
              color: AppTheme.sidebarBg,
              child: Column(
                children: [
                  _DrawerHeader(user: user),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      itemCount: _modules.length,
                      itemBuilder: (context, index) {
                        final module = _modules[index];
                        final selected = _selectedIndex == index;
                        return _ShellDrawerTile(
                          module: module,
                          selected: selected,
                          onTap: () {
                            _selectModule(index);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: _buildBody(includeModuleScope: false),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _mobileIndexFromShellIndex(_selectedIndex),
            onTap: (value) => _selectModule(_shellIndexFromMobileIndex(value)),
            selectedLabelStyle: AppTheme.navLabel(AppTheme.terra600),
            unselectedLabelStyle: AppTheme.navLabel(AppTheme.textSecondary),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.tune_outlined),
                label: 'Settings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                label: 'Invoicing',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.swap_horiz_outlined),
                label: 'Transactions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                label: 'Reports',
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _wrapMobileModuleScope(Widget child) {
    switch (_selectedIndex) {
      case 2:
      case 3:
        return InvoicingScope(child: child);
      case 5:
        return AccountsReportsScope(child: child);
      default:
        return child;
    }
  }

  PreferredSizeWidget? _buildMobileAppBar(BuildContext context) {
    if (_selectedIndex == 2 || _selectedIndex == 3) {
      final nav = context.watch<InvoicingNavController>();
      if (!nav.showMobileMenu) return null;
    }
    if (_selectedIndex == 5) {
      final nav = context.watch<AccountsReportsNavController>();
      if (nav.selectedSection != 'menu') return null;
    }

    return AppBar(
      title: Text(_modules[_selectedIndex].title),
    );
  }

  Widget _buildTabletShell(BuildContext context, UserModel? user) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: _railExtended
                ? AppTheme.sidebarWidthExpanded
                : AppTheme.sidebarWidthCollapsed + 12,
            color: AppTheme.sidebarBg,
            child: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        setState(() => _railExtended = !_railExtended);
                      },
                      color: AppTheme.sidebarActiveText,
                      icon: Icon(
                        _railExtended
                            ? Icons.keyboard_double_arrow_left
                            : Icons.keyboard_double_arrow_right,
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  Expanded(
                    child: NavigationRail(
                      extended: _railExtended,
                      backgroundColor: AppTheme.sidebarBg,
                      selectedIndex: _selectedIndex,
                      labelType: _railExtended
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.selected,
                      selectedIconTheme: const IconThemeData(
                          color: AppTheme.sidebarActiveText),
                      unselectedIconTheme:
                          const IconThemeData(color: AppTheme.sidebarText),
                      selectedLabelTextStyle:
                          AppTheme.navLabel(AppTheme.sidebarActiveText),
                      unselectedLabelTextStyle:
                          AppTheme.navLabel(AppTheme.sidebarText),
                      destinations: _modules
                          .map(
                            (module) => NavigationRailDestination(
                              icon: Icon(module.icon),
                              selectedIcon: _ActiveIcon(icon: module.icon),
                              label: Text(module.title),
                            ),
                          )
                          .toList(),
                      onDestinationSelected: _selectModule,
                    ),
                  ),
                  if (_railExtended && user != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        user.email,
                        style: AppTheme.navLabel(AppTheme.sidebarText),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildDesktopShell(BuildContext context, UserModel? user) {
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _desktopExpanded
                ? AppTheme.sidebarWidthExpanded
                : AppTheme.sidebarWidthCollapsed,
            color: AppTheme.sidebarBg,
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    height: 64,
                    padding: EdgeInsets.symmetric(
                      horizontal: _desktopExpanded ? 20 : 10,
                    ),
                    alignment: Alignment.centerLeft,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // During width animation, avoid showing title row if space is tight.
                        final showExpandedHeader =
                            _desktopExpanded && constraints.maxWidth >= 150;
                        return showExpandedHeader
                            ? Row(
                                children: const [
                                  Icon(Icons.agriculture,
                                      color: AppTheme.sidebarActiveText,
                                      size: 22),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Farm Management',
                                      style: TextStyle(
                                        color: AppTheme.sidebarActiveText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Center(
                                child: Icon(Icons.agriculture,
                                    color: AppTheme.sidebarActiveText,
                                    size: 22),
                              );
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      itemCount: _modules.length,
                      itemBuilder: (context, index) {
                        final module = _modules[index];
                        final selected = _selectedIndex == index;
                        return _SidebarItem(
                          title: module.title,
                          icon: module.icon,
                          expanded: _desktopExpanded,
                          selected: selected,
                          onTap: () => _selectModule(index),
                        );
                      },
                    ),
                  ),
                  if (_desktopExpanded && user != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        user.email,
                        style: AppTheme.navLabel(AppTheme.sidebarText),
                      ),
                    ),
                  IconButton(
                    onPressed: () {
                      setState(() => _desktopExpanded = !_desktopExpanded);
                    },
                    color: AppTheme.sidebarActiveText,
                    icon: Icon(
                      _desktopExpanded
                          ? Icons.keyboard_double_arrow_left
                          : Icons.keyboard_double_arrow_right,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody({bool includeModuleScope = true}) {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return SettingsScreen(
          onOpenHome: () {
            Navigator.of(context).pushReplacementNamed(RouteManager.home);
          },
        );
      case 2:
        return includeModuleScope
            ? const InvoicingScope(child: InvoicingScreen())
            : const InvoicingScreen();
      case 3:
        return includeModuleScope
            ? const InvoicingScope(child: TransactionsScreen())
            : const TransactionsScreen();
      case 4:
        return const PoultryScope(child: PoultryScreen());
      case 5:
        return includeModuleScope
            ? const AccountsReportsScope(child: AccountsReportsScreen())
            : const AccountsReportsScreen();
      default:
        return _PlaceholderModule(title: _modules[_selectedIndex].title);
    }
  }

  int _mobileIndexFromShellIndex(int shellIndex) {
    switch (shellIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 3;
      case 5:
        return 4;
      default:
        return 0;
    }
  }

  int _shellIndexFromMobileIndex(int mobileIndex) {
    switch (mobileIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 3;
      case 4:
        return 5;
      default:
        return 0;
    }
  }
}

class _ShellModule {
  const _ShellModule(this.title, this.icon);

  final String title;
  final IconData icon;
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final farmLabel = ((user?.farmType ?? '').isNotEmpty)
        ? (user?.farmType ?? 'Your Farm')
        : 'Your Farm';
    return Container(
      width: double.infinity,
      color: AppTheme.drawerHeaderBg,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.agriculture,
            color: AppTheme.sidebarActiveText,
            size: 30,
          ),
          const SizedBox(height: 12),
          const Text(
            'Farm Management',
            style: TextStyle(
              color: AppTheme.sidebarActiveText,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            farmLabel,
            style: AppTheme.navLabel(AppTheme.sidebarText),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'No email',
            style: AppTheme.navLabel(AppTheme.sidebarText),
          ),
        ],
      ),
    );
  }
}

class _ShellDrawerTile extends StatelessWidget {
  const _ShellDrawerTile({
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final _ShellModule module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        minLeadingWidth: 24,
        leading: Icon(
          module.icon,
          color: selected ? AppTheme.sidebarActiveText : AppTheme.sidebarText,
        ),
        title: Text(
          module.title,
          style: AppTheme.navLabel(
            selected ? AppTheme.sidebarActiveText : AppTheme.sidebarText,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.expanded,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // During sidebar width animation, guard against transient narrow widths.
        final showExpanded = expanded && constraints.maxWidth >= 130;
        return InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: selected ? AppTheme.sidebarActive : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(
                  color: selected
                      ? (showExpanded
                          ? AppTheme.terra400
                          : AppTheme.terra400.withAlpha(153))
                      : Colors.transparent,
                  width: showExpanded ? 3 : 1.5,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: showExpanded ? 18 : 8,
              vertical: 16,
            ),
            child: Row(
              mainAxisAlignment: showExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: showExpanded ? 24 : 20,
                  color: selected
                      ? AppTheme.sidebarActiveText
                      : AppTheme.sidebarText,
                ),
                if (showExpanded) const SizedBox(width: 12),
                if (showExpanded)
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.navLabel(
                        selected
                            ? AppTheme.sidebarActiveText
                            : AppTheme.sidebarText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActiveIcon extends StatelessWidget {
  const _ActiveIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.sidebarActive,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppTheme.sidebarActiveText),
    );
  }
}

class _PlaceholderModule extends StatelessWidget {
  const _PlaceholderModule({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.pagePadding(context),
        child: Container(
          padding: AppTheme.cardPadding,
          decoration: AppTheme.cardDecor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_outlined,
                size: 56,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                '$title module is coming next.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
