import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:heroicons/heroicons.dart';
import 'auth_manager.dart';

class MaintenanceBanner extends StatefulWidget {
  final Widget child;
  final AuthManager authManager;

  const MaintenanceBanner({
    super.key,
    required this.child,
    required this.authManager,
  });

  @override
  _MaintenanceBannerState createState() => _MaintenanceBannerState();
}

class _MaintenanceBannerState extends State<MaintenanceBanner> {
  bool _isMaintenanceMode = false;
  bool _isVisible = true;
  Timer? _timer;
  DateTime _lastCheckTime = DateTime.now().subtract(const Duration(minutes: 5));

  @override
  void initState() {
    super.initState();
    _checkMaintenanceStatus();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _checkMaintenanceStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkMaintenanceStatus() async {
    if (!widget.authManager.isLoggedIn || DateTime.now().difference(_lastCheckTime).inMinutes < 5) {
      return; // Don't check if not logged in or if last check was less than 5 minutes ago
    }

    _lastCheckTime = DateTime.now();

    try {
      final headers = {
        ...widget.authManager.headers,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.get(
        Uri.parse('${widget.authManager.baseUrl}/api/user'),
        headers: headers,
      );

      if (response.statusCode == 503) {
        _setMaintenanceMode(true);
      } else if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('data')) {
          _setMaintenanceMode(false);
        } else {
          if (kDebugMode) {
            print('Invalid user data format');
          }
        }
      } else {
        if (kDebugMode) {
          print('Unexpected status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking maintenance status: $e');
      }
    }
  }

  void _setMaintenanceMode(bool value) {
    if (mounted) {
      setState(() {
        _isMaintenanceMode = value;
        _isVisible = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isMaintenanceMode && _isVisible)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade800, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const HeroIcon(
                            HeroIcons.wrenchScrewdriver,
                            style: HeroIconStyle.solid,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Maintenance in Progress',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const HeroIcon(HeroIcons.xMark, style: HeroIconStyle.solid, color: Colors.white),
                            onPressed: () => setState(() => _isVisible = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'re currently improving our services. Thank you for your patience!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}