import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'user_provider.dart';
import 'more_menu.dart';
import 'navigation_item.dart';

class BottomNavBar extends StatelessWidget {
  final NavigationItem selectedItem;
  final Function(NavigationItem) onItemTapped;
  final UserProvider userProvider;

  const BottomNavBar({
    Key? key,
    required this.selectedItem,
    required this.onItemTapped,
    required this.userProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                    child: _buildNavItem(
                  context: context,
                  item: NavigationItem.backupTasks,
                  icon: HeroIcons.archiveBox,
                  label: 'Backup Tasks',
                )),
                Expanded(
                    child: _buildNavItem(
                  context: context,
                  item: NavigationItem.taskLogs,
                  icon: HeroIcons.documentText,
                  label: 'Task Logs',
                )),
                Expanded(child: _buildProfileItem(context)),
                Expanded(child: _buildMoreItem(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required NavigationItem item,
    required HeroIcons icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedItem == item;

    return GestureDetector(
      onTap: () => onItemTapped(item),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: HeroIcon(
              icon,
              style: isSelected ? HeroIconStyle.solid : HeroIconStyle.outline,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodyLarge?.color,
              size: 24,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodyLarge?.color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context) {
    final theme = Theme.of(context);
    final user = userProvider.user;
    final isSelected = selectedItem == NavigationItem.profile;

    return GestureDetector(
      onTap: () => onItemTapped(NavigationItem.profile),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isSelected ? theme.colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withOpacity(0.1),
              backgroundImage: user?.personalInfo.avatarUrl != null
                  ? NetworkImage(user!.personalInfo.avatarUrl!)
                  : null,
              child: user?.personalInfo.avatarUrl == null
                  ? Text(
                      user?.personalInfo.firstName
                              .substring(0, 1)
                              .toUpperCase() ??
                          '',
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Profile',
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodyLarge?.color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMoreItem(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => MoreMenu(onItemTapped: onItemTapped),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: HeroIcon(
              HeroIcons.ellipsisHorizontal,
              color: theme.textTheme.bodyLarge?.color,
              size: 24,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'More',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
