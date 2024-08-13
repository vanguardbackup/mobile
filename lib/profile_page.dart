import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:heroicons/heroicons.dart';
import 'package:vanguard/user_model.dart';
import 'user_provider.dart';
import 'auth_manager.dart';
import 'package:intl/intl.dart';
import 'lock_provider.dart';

class ProfilePage extends StatelessWidget {
  final AuthManager authManager;

  const ProfilePage({super.key, required this.authManager});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        if (user == null) {
          return Center(
            child: Text(
              'User profile not available',
              style: theme.textTheme.titleMedium,
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPersonalInfo(context, user),
              _buildAnimatedSection(context, 'Account Settings',
                  _buildAccountSettings(context, user)),
              _buildAnimatedSection(context, 'Backup Tasks',
                  _buildBackupTasksInfo(context, user)),
              _buildAnimatedSection(
                  context, 'Statistics', _buildRelatedEntities(context, user)),
              _buildAnimatedSection(
                  context, 'Account Details', _buildTimestamps(context, user)),
              _buildAnimatedSection(
                  context, 'App Settings', _buildAppSettings(context)),
              const SizedBox(height: 24),
              _buildLogoutButton(context, userProvider),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfo(BuildContext context, User user) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Hero(
              tag: 'profile-avatar',
              child: CircleAvatar(
                radius: 50,
                backgroundImage: user.personalInfo.avatarUrl != null
                    ? NetworkImage(user.personalInfo.avatarUrl!)
                    : null,
                backgroundColor: theme.colorScheme.secondary,
                child: user.personalInfo.avatarUrl == null
                    ? Text(
                        user.personalInfo.firstName.isNotEmpty
                            ? user.personalInfo.firstName
                                .substring(0, 1)
                                .toUpperCase()
                            : '',
                        style: TextStyle(
                            fontSize: 32, color: theme.colorScheme.onSecondary),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.personalInfo.name,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HeroIcon(HeroIcons.envelope,
                    size: 16, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text(
                  user.personalInfo.email,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSection(
      BuildContext context, String title, Widget content) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: _buildSection(context, title, content),
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context, User user) {
    return Column(
      children: [
        _buildSettingItem(context, HeroIcons.clock, 'Timezone',
            user.accountSettings.timezone),
        _buildSettingItem(context, HeroIcons.language, 'Language',
            user.accountSettings.language),
        _buildSettingItem(context, HeroIcons.userCircle, 'Elevated Permissions',
            user.accountSettings.isAdmin ? 'Yes' : 'No'),
        _buildSettingItem(context, HeroIcons.codeBracket, 'GitHub Login',
            user.accountSettings.githubLoginEnabled ? 'Enabled' : 'Disabled'),
        _buildSettingItem(context, HeroIcons.envelope, 'Weekly Summary',
            user.accountSettings.weeklySummaryEnabled ? 'Enabled' : 'Disabled'),
      ],
    );
  }

  Widget _buildBackupTasksInfo(BuildContext context, User user) {
    return Column(
      children: [
        _buildInfoItem(context, HeroIcons.documentDuplicate, 'Total Tasks',
            user.backupTasks.total.toString()),
        _buildInfoItem(context, HeroIcons.play, 'Active Tasks',
            user.backupTasks.active.toString()),
        _buildInfoItem(context, HeroIcons.documentText, 'Total Logs',
            user.backupTasks.logs.total.toString()),
        _buildInfoItem(context, HeroIcons.calendar, 'Logs Today',
            user.backupTasks.logs.today.toString()),
      ],
    );
  }

  Widget _buildRelatedEntities(BuildContext context, User user) {
    return Column(
      children: [
        _buildInfoItem(context, HeroIcons.server, 'Remote Servers',
            user.relatedEntities.remoteServers.toString()),
        _buildInfoItem(context, HeroIcons.cloudArrowUp, 'Backup Destinations',
            user.relatedEntities.backupDestinations.toString()),
        _buildInfoItem(context, HeroIcons.tag, 'Tags',
            user.relatedEntities.tags.toString()),
        _buildInfoItem(context, HeroIcons.bell, 'Notification Streams',
            user.relatedEntities.notificationStreams.toString()),
      ],
    );
  }

  Widget _buildTimestamps(BuildContext context, User user) {
    return _buildInfoItem(
      context,
      HeroIcons.calendar,
      'Account Created',
      DateFormat('MMMM d, y').format(user.timestamps.accountCreated),
    );
  }

  Widget _buildSettingItem(
      BuildContext context, HeroIcons icon, String title, String value,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            HeroIcon(icon, size: 20, color: theme.colorScheme.secondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: theme.textTheme.bodyMedium),
            ),
            Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
      BuildContext context, HeroIcons icon, String title, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          HeroIcon(icon, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: theme.textTheme.bodyMedium),
          ),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAppSettings(BuildContext context) {
    return Consumer<LockProvider>(
      builder: (context, lockProvider, _) {
        return Column(
          children: [
            _buildSettingItemWithSwitch(
              context,
              HeroIcons.lockClosed,
              'App Lock',
              lockProvider.isLockEnabled,
              (bool value) async {
                if (value) {
                  // Enabling app lock
                  await _showPinDialog(context, lockProvider, isNewPin: true);
                } else {
                  // Disabling app lock
                  await _confirmSecurityChange(context, lockProvider,
                      action: () => lockProvider.toggleLock(false),
                      message:
                          'Are you sure you want to disable the app lock?');
                }
              },
            ),
            if (lockProvider.isLockEnabled) ...[
              _buildSettingItemWithSwitch(
                context,
                HeroIcons.fingerPrint,
                'Use Biometrics',
                lockProvider.useBiometrics,
                (bool value) async {
                  await _confirmSecurityChange(context, lockProvider,
                      action: () => lockProvider.toggleBiometrics(value),
                      message: value
                          ? 'Are you sure you want to enable biometric authentication?'
                          : 'Are you sure you want to disable biometric authentication?');
                },
              ),
              _buildSettingItem(
                context,
                HeroIcons.key,
                'Change PIN',
                '',
                onTap: () =>
                    _showPinDialog(context, lockProvider, isNewPin: false),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _showPinDialog(BuildContext context, LockProvider lockProvider,
      {required bool isNewPin}) async {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isNewPin ? 'Set PIN' : 'Change PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit PIN',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: confirmPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Confirm 4-digit PIN',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Set'),
              onPressed: () {
                if (pinController.text.length == 4 &&
                    pinController.text == confirmPinController.text) {
                  if (isNewPin) {
                    lockProvider.toggleLock(true);
                  }
                  lockProvider.setPin(pinController.text);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('PINs do not match or are not 4 digits')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmSecurityChange(
      BuildContext context, LockProvider lockProvider,
      {required Function action, required String message}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Security Change'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: Text('Confirm'),
              onPressed: () async {
                if (await _authenticateForChange(context, lockProvider)) {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Authentication failed')),
                  );
                  Navigator.of(context).pop(false);
                }
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      action();
    }
  }

  Future<bool> _authenticateForChange(
      BuildContext context, LockProvider lockProvider) async {
    if (lockProvider.useBiometrics) {
      final result = await lockProvider.authenticateUser();
      if (result['success']) {
        return true; // Authentication successful
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        if (lockProvider.hasPIN) {
          return await _showPinEntryDialog(context, lockProvider);
        } else {
          return false; // Authentication failed and no PIN available
        }
      }
    } else {
      return await _showPinEntryDialog(context, lockProvider);
    }
  }

  Future<bool> _showPinEntryDialog(
      BuildContext context, LockProvider lockProvider) async {
    final pinController = TextEditingController();
    final authenticated = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter PIN'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter your 4-digit PIN',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: Text('Confirm'),
              onPressed: () async {
                final isPinCorrect =
                    await lockProvider.checkPin(pinController.text);
                Navigator.of(context).pop(isPinCorrect);
              },
            ),
          ],
        );
      },
    );
    return authenticated ?? false;
  }

  Widget _buildSettingItemWithSwitch(BuildContext context, HeroIcons icon,
      String title, bool value, Function(bool) onChanged) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          HeroIcon(icon, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: theme.textTheme.bodyMedium),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () => _showLogoutConfirmationDialog(context, userProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444), // Tailwind red-500
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeroIcon(HeroIcons.arrowLeftEndOnRectangle,
                size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(
      BuildContext context, UserProvider userProvider) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Confirm Logout', style: theme.textTheme.titleLarge),
          content: Text('Are you sure you want to log out?',
              style: theme.textTheme.bodyMedium),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel',
                  style: TextStyle(color: theme.colorScheme.secondary)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444), // Tailwind red-500
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                await userProvider.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}
