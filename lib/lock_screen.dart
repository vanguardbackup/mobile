import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:heroicons/heroicons.dart';
import 'lock_provider.dart';
import 'user_provider.dart';

class LockScreen extends StatefulWidget {
  final Widget child;

  const LockScreen({Key? key, required this.child}) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isChecking = true;
  late AnimationController _lockIconController;
  late Animation<double> _lockIconAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLockStatus();
    });

    _lockIconController = AnimationController(
      duration: const Duration(milliseconds: 300), // Increased animation speed
      vsync: this,
    );
    _lockIconAnimation = Tween<double>(begin: 0, end: 1).animate(_lockIconController);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockIconController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lockProvider = Provider.of<LockProvider>(context, listen: false);
    if (state == AppLifecycleState.paused) {
      lockProvider.updateLastActiveTime();
    } else if (state == AppLifecycleState.resumed) {
      _checkLockStatus();
    }
  }

  Future<void> _checkLockStatus() async {
    setState(() => _isChecking = true);
    final lockProvider = Provider.of<LockProvider>(context, listen: false);
    if (await lockProvider.shouldLockApp()) {
      lockProvider.lockApp();
    }
    setState(() => _isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LockProvider>(
      builder: (context, lockProvider, child) {
        if (_isChecking) {
          return _buildLoadingScreen();
        }
        if (lockProvider.isLockEnabled && lockProvider.isAppLocked) {
          return _buildLockScreen(context, lockProvider);
        }
        return widget.child;
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildLockScreen(BuildContext context, LockProvider lockProvider) {
    final theme = Theme.of(context);
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                SizedBox(height: 40),
                _buildLockIcon(theme),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAvatar(user, theme),
                      SizedBox(height: 24),
                      _buildWelcomeText(user, theme),
                      SizedBox(height: 32),
                      _buildInfoText(theme),
                    ],
                  ),
                ),
                _buildUnlockButton(context, lockProvider),
                SizedBox(height: 60), // Increased bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockIcon(ThemeData theme) {
    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedBuilder(
        animation: _lockIconAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _lockIconAnimation.value * 2 * 3.14159,
            child: HeroIcon(
              _lockIconAnimation.value < 0.5 ? HeroIcons.lockClosed : HeroIcons.lockOpen,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(user, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 3,
        ),
      ),
      child: CircleAvatar(
        radius: 60,
        backgroundImage: user?.personalInfo.avatarUrl != null
            ? NetworkImage(user!.personalInfo.avatarUrl!)
            : null,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        child: user?.personalInfo.avatarUrl == null
            ? Text(
          user?.personalInfo.firstName.substring(0, 1).toUpperCase() ?? 'U',
          style: TextStyle(fontSize: 48, color: theme.colorScheme.primary),
        )
            : null,
      ),
    );
  }

  Widget _buildWelcomeText(user, ThemeData theme) {
    return Text(
      'Welcome back, ${user?.personalInfo.firstName ?? 'User'}!',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInfoText(ThemeData theme) {
    return Text(
      'Your Vanguard app is locked for security.\nPlease authenticate to continue.',
      style: theme.textTheme.bodyLarge,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildUnlockButton(BuildContext context, LockProvider lockProvider) {
    return ElevatedButton(
      onPressed: () => _handleUnlock(context, lockProvider),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroIcon(
            lockProvider.useBiometrics ? HeroIcons.fingerPrint : HeroIcons.key,
            size: 24,
          ),
          SizedBox(width: 12),
          Text(
            'Unlock Vanguard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _handleUnlock(BuildContext context, LockProvider lockProvider) async {
    if (lockProvider.useBiometrics) {
      final result = await lockProvider.authenticateUser();
      if (result['success']) {
        await _animateUnlock();
        lockProvider.unlockApp();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        if (lockProvider.hasPIN) {
          _showPinEntryDialog(context, lockProvider);
        }
      }
    } else if (lockProvider.hasPIN) {
      _showPinEntryDialog(context, lockProvider);
    } else {
      await _animateUnlock();
      lockProvider.unlockApp();
    }
  }

  void _showPinEntryDialog(BuildContext context, LockProvider lockProvider) {
    String enteredPin = '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter PIN'),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            onChanged: (value) {
              enteredPin = value;
              if (value.length == 4) {
                Navigator.of(context).pop();
                _verifyPin(context, lockProvider, enteredPin);
              }
            },
            decoration: InputDecoration(
              hintText: 'Enter your 4-digit PIN',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifyPin(BuildContext context, LockProvider lockProvider, String enteredPin) async {
    if (await lockProvider.checkPin(enteredPin)) {
      await _animateUnlock();
      lockProvider.unlockApp();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN. Please try again.')),
      );
      _showPinEntryDialog(context, lockProvider);
    }
  }

  Future<void> _animateUnlock() async {
    await _lockIconController.forward();
    await Future.delayed(const Duration(milliseconds: 300)); // Reduced delay
    _lockIconController.reset();
  }
}