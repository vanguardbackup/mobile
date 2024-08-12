import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'user_provider.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final UserProvider userProvider;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.userProvider,
  }) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  void didUpdateWidget(BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      print('Selected index changed: ${oldWidget.selectedIndex} -> ${widget.selectedIndex}');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building BottomNavBar with selectedIndex: ${widget.selectedIndex}');
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          items: _buildNavItems(context),
          currentIndex: widget.selectedIndex,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: isLightMode ? Colors.black54 : Colors.white70,
          backgroundColor: theme.scaffoldBackgroundColor,
          onTap: widget.onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;

    return [
      _buildNavItem(
        icon: HeroIcons.archiveBox,
        label: 'Backup Tasks',
        index: 0,
        theme: theme,
        isLightMode: isLightMode,
      ),
      _buildNavItem(
        icon: HeroIcons.documentText,
        label: 'Logs',
        index: 1,
        theme: theme,
        isLightMode: isLightMode,
      ),
      BottomNavigationBarItem(
        icon: _buildProfileIcon(context),
        label: widget.userProvider.user?.personalInfo.firstName ?? 'Profile',
      ),
    ];
  }

  BottomNavigationBarItem _buildNavItem({
    required HeroIcons icon,
    required String label,
    required int index,
    required ThemeData theme,
    required bool isLightMode,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(widget.selectedIndex == index ? 12 : 8),
        decoration: BoxDecoration(
          color: widget.selectedIndex == index
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: HeroIcon(
          icon,
          color: widget.selectedIndex == index
              ? theme.colorScheme.primary
              : isLightMode ? Colors.black54 : Colors.white70,
          size: 24,
        ),
      ),
      label: label,
    );
  }

  Widget _buildProfileIcon(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.userProvider.user;
    final isSelected = widget.selectedIndex == 2;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: user?.personalInfo.avatarUrl != null
          ? CircleAvatar(
        radius: 14,
        backgroundImage: NetworkImage(user!.personalInfo.avatarUrl!),
      )
          : CircleAvatar(
        radius: 14,
        backgroundColor: isSelected
            ? theme.colorScheme.primary
            : theme.brightness == Brightness.light
            ? Colors.grey[300]
            : Colors.grey[700],
        child: Text(
          user?.personalInfo.name.substring(0, 1).toUpperCase() ?? '',
          style: TextStyle(
            color: isSelected
                ? theme.scaffoldBackgroundColor
                : theme.colorScheme.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}