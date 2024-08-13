import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'navigation_item.dart'; // Add this import

class MoreMenu extends StatelessWidget {
  final Function(NavigationItem) onItemTapped;

  const MoreMenu({super.key, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(context, 'Remote Servers', HeroIcons.server,
              NavigationItem.remoteServers),
          _buildMenuItem(context, 'Backup Destinations', HeroIcons.cloudArrowUp,
              NavigationItem.backupDestinations),
          _buildMenuItem(context, 'Notification Streams', HeroIcons.bellAlert,
              NavigationItem.notificationStreams),
          _buildMenuItem(context, 'Tags', HeroIcons.tag, NavigationItem.tags),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, String label, HeroIcons icon, NavigationItem item) {
    return ListTile(
      leading: HeroIcon(icon, style: HeroIconStyle.outline),
      title: Text(label),
      onTap: () {
        Navigator.pop(context); // Close the bottom sheet
        onItemTapped(item);
      },
    );
  }
}
