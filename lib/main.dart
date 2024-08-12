import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:heroicons/heroicons.dart';
import 'auth_manager.dart';
import 'backup_task_log_provider.dart';
import 'lock_provider.dart';
import 'lock_screen.dart';
import 'user_provider.dart';
import 'backup_task_provider.dart';
import 'login_page.dart';
import 'backup_tasks_page.dart';
import 'logs_page.dart';
import 'profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'maintenance_banner.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.black,
    cardColor: Colors.grey[900],
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Poppins', color: Colors.white70),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Colors.white70,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white10,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white30),
    ),
  );

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.grey[100],
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black),
      titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500, color: Colors.black),
      bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Poppins', color: Colors.black87),
    ),
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Colors.black87,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.black.withOpacity(0.1),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.black87),
      hintStyle: const TextStyle(color: Colors.black54),
    ),
  );
}

class DeviceInfoProvider with ChangeNotifier {
  String _deviceName = 'Unknown Device';
  String _deviceModel = 'Unknown Model';
  String _deviceVersion = 'Unknown Version';

  String get deviceName => _deviceName;
  String get deviceModel => _deviceModel;
  String get deviceVersion => _deviceVersion;

  Future<void> initializeDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceName = androidInfo.model;
        _deviceModel = androidInfo.model;
        _deviceVersion = androidInfo.version.release;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceName = iosInfo.name;
        _deviceModel = iosInfo.model;
        _deviceVersion = iosInfo.systemVersion;
      } else {
        final webInfo = await deviceInfo.webBrowserInfo;
        _deviceName = webInfo.browserName.toString();
        _deviceModel = webInfo.platform ?? 'Unknown';
        _deviceVersion = webInfo.appVersion ?? 'Unknown';
      }
    } catch (e) {
      print('Error getting device info: $e');
      _deviceName = 'Error Getting Device Info';
      _deviceModel = 'Error Getting Device Info';
      _deviceVersion = 'Error Getting Device Info';
    }

    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authManager = AuthManager();
  await authManager.initialize();
  final userProvider = UserProvider(authManager: authManager);
  final backupTaskProvider = BackupTaskProvider(authManager: authManager);
  final deviceInfoProvider = DeviceInfoProvider();
  final backupTaskLogProvider = BackupTaskLogProvider(authManager: authManager);
  final lockProvider = LockProvider();

  await deviceInfoProvider.initializeDeviceInfo();

  if (authManager.isLoggedIn) {
    await userProvider.fetchUser();
    await backupTaskProvider.fetchBackupTasks();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: backupTaskProvider),
        ChangeNotifierProvider.value(value: deviceInfoProvider),
        ChangeNotifierProvider.value(value: backupTaskLogProvider),
        ChangeNotifierProvider.value(value: lockProvider),
      ],
      child: MyApp(authManager: authManager),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthManager authManager;

  MyApp({required this.authManager});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Vanguard',
          color: Colors.black,
          theme: themeProvider.currentTheme,
          home: LockScreen(
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                if (authManager.isLoggedIn && userProvider.user != null) {
                  return MaintenanceBanner(
                    authManager: authManager,
                    child: MainNavigationWrapper(authManager: authManager),
                  );
                } else {
                  return LoginPage(authManager: authManager);
                }
              },
            ),
          ),
          routes: {
            '/login': (context) => MaintenanceBanner(authManager: authManager, child: LoginPage(authManager: authManager)),
          },
        );
      },
    );
  }
}



class MainNavigationWrapper extends StatefulWidget {
  final AuthManager authManager;

  const MainNavigationWrapper({super.key, required this.authManager});

  @override
  _MainNavigationWrapperState createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      BackupTasksPage(),
      BackupTaskLogsPage(),
      ProfilePage(authManager: widget.authManager),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {

        if (userProvider.user == null) {
          userProvider.fetchUser();
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vanguard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.white,
                  ),
                  onPressed: () => themeProvider.toggleTheme(),
                ),
              ],
            ),
            backgroundColor: Colors.black,
            elevation: 0,
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
            userProvider: userProvider,
          ),
        );
      },
    );
  }
}

class BottomNavBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;

    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: HeroIcon(
            HeroIcons.archiveBox,
            color: isLightMode ? Colors.black54 : Colors.white70,
          ),
          activeIcon: HeroIcon(
            HeroIcons.archiveBox,
            color: theme.colorScheme.primary,
          ),
          label: 'Backup Tasks',
        ),
        BottomNavigationBarItem(
          icon: HeroIcon(
            HeroIcons.documentText,
            color: isLightMode ? Colors.black54 : Colors.white70,
          ),
          activeIcon: HeroIcon(
            HeroIcons.documentText,
            color: theme.colorScheme.primary,
          ),
          label: 'Logs',
        ),
        BottomNavigationBarItem(
          icon: _buildProfileIcon(context),
          label: userProvider.user?.personalInfo.firstName ?? 'Profile',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: isLightMode ? Colors.black54 : Colors.white70,
      backgroundColor: theme.scaffoldBackgroundColor,
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    );
  }

  Widget _buildProfileIcon(BuildContext context) {
    final theme = Theme.of(context);
    final user = userProvider.user;
    final isSelected = selectedIndex == 2;

    return Container(
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