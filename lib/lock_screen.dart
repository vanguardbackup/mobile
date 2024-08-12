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
  int _incorrectAttempts = 0;
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
      duration: const Duration(milliseconds: 500),
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
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (lockProvider.isLockEnabled && lockProvider.isAppLocked) {
          return _buildLockScreen(context);
        }
        return widget.child;
      },
    );
  }

  Widget _buildLockScreen(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<UserProvider>(context).user;
    final lockProvider = Provider.of<LockProvider>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              SizedBox(height: 40),
              Align(
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
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildAvatarWidget(user, theme),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Welcome back, ${user?.personalInfo.firstName ?? 'User'}!',
                        style: theme.textTheme.headlineSmall,
                      ),
                      SizedBox(height: 32),
                      Text(
                        'Your Vanguard app is locked for security.',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Please authenticate to continue.',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              _buildUnlockButton(context, lockProvider),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWidget(user, theme) {
    return CircleAvatar(
      key: ValueKey(user?.personalInfo.avatarUrl),
      radius: 50,
      backgroundImage: user?.personalInfo.avatarUrl != null
          ? NetworkImage(user!.personalInfo.avatarUrl!)
          : null,
      child: user?.personalInfo.avatarUrl == null
          ? Text(
        user?.personalInfo.firstName.substring(0, 1).toUpperCase() ?? '',
        style: TextStyle(fontSize: 32, color: theme.colorScheme.onSecondary),
      )
          : null,
    );
  }

  Widget _buildUnlockButton(BuildContext context, LockProvider lockProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () async {
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
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeroIcon(
              lockProvider.useBiometrics ? HeroIcons.fingerPrint : HeroIcons.key,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            SizedBox(width: 8),
            const Text(
              'Unlock Vanguard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinEntryDialog(BuildContext context, LockProvider lockProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController pinController = TextEditingController();
        final FocusNode focusNode = FocusNode();

        // Automatically focus the text field when the dialog opens
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(focusNode);
        });

        return AlertDialog(
          title: const Text('Enter PIN'),
          content: TextField(
            controller: pinController,
            focusNode: focusNode,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            autofocus: true,
            onChanged: (value) {
              if (value.length == 4) {
                _verifyPin(context, lockProvider, value);
              }
            },
            decoration: const InputDecoration(
              hintText: 'Enter your 4-digit PIN',
              prefixIcon: HeroIcon(HeroIcons.key),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Unlock'),
              onPressed: () => _verifyPin(context, lockProvider, pinController.text),
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifyPin(BuildContext context, LockProvider lockProvider, String enteredPin) async {
    if (await lockProvider.checkPin(enteredPin)) {
      _incorrectAttempts = 0;
      Navigator.of(context).pop();
      await _animateUnlock();
      lockProvider.unlockApp();
    } else {
      _incorrectAttempts++;
      if (_incorrectAttempts >= 3) {
        // Implement a cooldown period or additional security measure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Too many incorrect attempts. Please try again later.')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Incorrect PIN. Please try again.')),
        );
      }
    }
  }

  Future<void> _animateUnlock() async {
    await _lockIconController.forward();
    await Future.delayed(Duration(milliseconds: 500));
    _lockIconController.reset();
  }
}