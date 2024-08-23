import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanguard/remote_servers_page.dart';
import 'package:vanguard/tag_page.dart';
import 'package:vanguard/tag_provider.dart';
import 'auth_manager.dart';
import 'backup_destinations_page.dart';
import 'backup_task_log_provider.dart';
import 'lock_provider.dart';
import 'lock_screen.dart';
import 'navigation_item.dart';
import 'notification_streams_page.dart';
import 'user_provider.dart';
import 'backup_task_provider.dart';
import 'remote_server_provider.dart';
import 'backup_destination_provider.dart';
import 'notification_stream_provider.dart';
import 'login_page.dart';
import 'backup_tasks_page.dart';
import 'logs_page.dart';
import 'profile_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'maintenance_banner.dart';
import 'bottom_nav_bar.dart';

enum ThemeMode { light, dark, auto }

class ThemeProvider with ChangeNotifier {
  static const String _themePreferenceKey = 'theme_preference';
  static const String _themeAutoKey = 'theme_auto';

  late bool _isDarkMode;
  late ThemeMode _themeMode;
  late SharedPreferences _prefs;

  ThemeProvider() {
    _loadPreferences();
  }

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _themeMode;

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _themeMode =
        ThemeMode.values[_prefs.getInt(_themeAutoKey) ?? ThemeMode.auto.index];
    _updateThemeMode();
  }

  void _updateThemeMode() {
    if (_themeMode == ThemeMode.auto) {
      var brightness = SchedulerBinding.instance.window.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
    } else {
      _isDarkMode = _themeMode == ThemeMode.dark;
    }
    _prefs.setBool(_themePreferenceKey, _isDarkMode);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setInt(_themeAutoKey, mode.index);
    _updateThemeMode();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.auto) {
      setThemeMode(_isDarkMode ? ThemeMode.light : ThemeMode.dark);
    } else {
      setThemeMode(
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
    }
  }

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.black,
    cardColor: Colors.grey[900],
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(
          fontSize: 20.0, fontWeight: FontWeight.w500, color: Colors.white),
      bodyMedium: TextStyle(
          fontSize: 14.0, fontFamily: 'Poppins', color: Colors.white70),
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
      displayLarge: TextStyle(
          fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black),
      titleLarge: TextStyle(
          fontSize: 20.0, fontWeight: FontWeight.w500, color: Colors.black),
      bodyMedium: TextStyle(
          fontSize: 14.0, fontFamily: 'Poppins', color: Colors.black87),
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
  final remoteServerProvider = RemoteServerProvider(authManager: authManager);
  final backupDestinationProvider =
      BackupDestinationProvider(authManager: authManager);
  final notificationStreamProvider =
      NotificationStreamProvider(authManager: authManager);
  final tagProvider = TagProvider(authManager: authManager);

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
        ChangeNotifierProvider.value(value: remoteServerProvider),
        ChangeNotifierProvider.value(value: backupDestinationProvider),
        ChangeNotifierProvider.value(value: notificationStreamProvider),
        ChangeNotifierProvider.value(value: tagProvider),
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
            authManager: authManager, // Added authManager here
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
            '/login': (context) => MaintenanceBanner(
                authManager: authManager,
                child: LoginPage(authManager: authManager)),
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
  NavigationItem _selectedItem = NavigationItem.backupTasks;

  late final Map<NavigationItem, Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = {
      NavigationItem.backupTasks: BackupTasksPage(),
      NavigationItem.taskLogs: BackupTaskLogsPage(),
      NavigationItem.profile: ProfilePage(authManager: widget.authManager),
      NavigationItem.remoteServers: RemoteServersPage(),
      NavigationItem.backupDestinations: BackupDestinationsPage(),
      NavigationItem.notificationStreams: NotificationStreamsPage(),
      NavigationItem.tags: TagsPage(),
    };
  }

  void _onItemTapped(NavigationItem item) {
    setState(() {
      _selectedItem = item;
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
                const Text(
                  'Vanguard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                PopupMenuButton<ThemeMode>(
                  icon: Icon(
                    themeProvider.themeMode == ThemeMode.auto
                        ? Icons.brightness_auto
                        : (themeProvider.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode),
                    color: Colors.white,
                  ),
                  onSelected: (ThemeMode result) {
                    themeProvider.setThemeMode(result);
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<ThemeMode>>[
                    const PopupMenuItem<ThemeMode>(
                      value: ThemeMode.light,
                      child: Text('Light Mode'),
                    ),
                    const PopupMenuItem<ThemeMode>(
                      value: ThemeMode.dark,
                      child: Text('Dark Mode'),
                    ),
                    const PopupMenuItem<ThemeMode>(
                      value: ThemeMode.auto,
                      child: Text('Auto Mode'),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: Colors.black,
            elevation: 0,
          ),
          body: _pages[_selectedItem] ?? const SizedBox.shrink(),
          bottomNavigationBar: BottomNavBar(
            selectedItem: _selectedItem,
            onItemTapped: _onItemTapped,
            userProvider: userProvider,
          ),
        );
      },
    );
  }
}
