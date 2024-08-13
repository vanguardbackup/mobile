import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:vanguard/user_provider.dart';
import 'dart:io';
import 'auth_manager.dart';
import 'dart:async';
import 'package:heroicons/heroicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'main.dart';

class LoginPage extends StatefulWidget {
  final AuthManager authManager;

  const LoginPage({Key? key, required this.authManager}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _deviceName = 'vanguard-app-device';
  String _baseUrl = 'https://app.vanguardbackup.com';
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  bool _isLoading = false;
  bool _showAdvanced = false;
  bool _isSplashVisible = true;

  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
    _getDeviceName();

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeIn,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _slideAnimationController, curve: Curves.easeOutCubic),
    );

    // Stagger animations
    _fadeAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideAnimationController.forward();
    });

    // Hide splash screen after a delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isSplashVisible = false;
      });
    });
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseUrl =
          prefs.getString('api_base_url') ?? 'https://app.vanguardbackup.com';
    });
  }

  Future<void> _getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        setState(() {
          _deviceName = androidInfo.model;
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        setState(() {
          _deviceName = iosInfo.utsname.machine;
        });
      } else {
        setState(() {
          _deviceName = 'vanguard-app-device';
        });
      }
    } catch (e) {
      debugPrint('Failed to get device name: $e');
      setState(() {
        _deviceName = 'vanguard-app-device';
      });
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
        _errors = {};
      });

      try {
        final url = Uri.parse('$_baseUrl/api/sanctum/token');
        final requestBody = jsonEncode({
          'email': _email,
          'password': _password,
          'device_name': _deviceName,
        });

        final response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: requestBody,
            )
            .timeout(const Duration(seconds: 10));

        if (response.headers['content-type']?.contains('application/json') ==
            true) {
          final responseBody = jsonDecode(response.body);

          if (response.statusCode == 200) {
            final token = responseBody['token'];
            await widget.authManager.setBaseUrl(_baseUrl);
            await widget.authManager.login(token);

            final userProvider =
                Provider.of<UserProvider>(context, listen: false);
            await userProvider.fetchUser();

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) =>
                      MainNavigationWrapper(authManager: widget.authManager)),
            );
          } else if (response.statusCode == 422) {
            if (responseBody['errors'] != null) {
              setState(() {
                _errors = Map<String, String>.from(responseBody['errors']
                    .map((key, value) => MapEntry(key, value[0])));
              });
            } else if (responseBody['message'] != null) {
              _showErrorDialog(responseBody['message']);
            }
          } else {
            _showErrorDialog(
                'Unexpected server response: ${response.statusCode}\n${responseBody}');
          }
        } else {
          _showErrorDialog(
              'Unexpected response from server. Received non-JSON response. Status code: ${response.statusCode}');
        }
      } on SocketException catch (_) {
        _showErrorDialog(
            'Network error: Unable to connect to the server. Please check your internet connection and try again.');
      } on TimeoutException catch (_) {
        _showErrorDialog(
            'Connection timed out. Please check your internet connection and try again.');
      } on FormatException catch (_) {
        _showErrorDialog(
            'Unexpected response format from the server. Please check the API endpoint.');
      } catch (e) {
        _showErrorDialog('An unexpected error occurred: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Error',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          content: Text(message,
              style:
                  const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          backgroundColor: Colors.grey[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: <Widget>[
            TextButton(
              child: const Text('OK',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SizedBox(height: 40),
                          _buildPulsingLogo(),
                          const SizedBox(height: 20),
                          _buildMarketingContent(),
                          const SizedBox(height: 40),
                          _buildTextField(
                            labelText: 'Email',
                            errorText: _errors['email'],
                            prefixIcon: const HeroIcon(HeroIcons.envelope,
                                color: Colors.white70),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _email = value!;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            labelText: 'Password',
                            errorText: _errors['password'],
                            prefixIcon: const HeroIcon(HeroIcons.lockClosed,
                                color: Colors.white70),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _password = value!;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildAdvancedToggle(),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              children: [
                                const SizedBox(height: 16),
                                _buildTextField(
                                  initialValue: _baseUrl,
                                  labelText: 'API Base URL',
                                  hintText: 'https://app.vanguardbackup.com',
                                  errorText: _errors['baseUrl'],
                                  prefixIcon: const HeroIcon(HeroIcons.globeAlt,
                                      color: Colors.white70),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter the API base URL';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _baseUrl = value!;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  initialValue: _deviceName,
                                  labelText: 'Device Name',
                                  errorText: _errors['device_name'],
                                  prefixIcon: const HeroIcon(
                                      HeroIcons.devicePhoneMobile,
                                      color: Colors.white70),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a device name';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _deviceName = value!;
                                  },
                                ),
                              ],
                            ),
                            crossFadeState: _showAdvanced
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                          const SizedBox(height: 32),
                          _buildLoginButton(),
                          const SizedBox(height: 40),
                          _buildLinks(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isSplashVisible) _buildSplashScreen(),
        ],
      ),
    );
  }

  Widget _buildPulsingLogo() {
    return SvgPicture.asset(
      'assets/logo.svg',
      height: 48,
      color: Colors.white,
    )
        .animate(
          onPlay: (controller) => controller.forward(),
        )
        .scale(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
        )
        .then(delay: 200.ms)
        .scale(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
        )
        .then(delay: 200.ms)
        .scale(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          begin: const Offset(1.1, 1.1),
          end: const Offset(1.0, 1.0),
        );
  }

  Widget _buildMarketingContent() {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Text(
          'A community-driven open-source backup solution for servers and applications.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'MySQL, PostgreSQL, and file backups made simple.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
      ]
          .animate(interval: const Duration(milliseconds: 100))
          .fadeIn(duration: const Duration(milliseconds: 500)),
    );
  }

  Widget _buildTextField({
    String? initialValue,
    required String labelText,
    String? hintText,
    bool obscureText = false,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
    String? errorText,
    Widget? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: initialValue,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            labelStyle: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Poppins',
            ),
            hintStyle: const TextStyle(
              color: Colors.white30,
              fontFamily: 'Poppins',
            ),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
            ),
            prefixIcon: prefixIcon,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
          obscureText: obscureText,
          validator: validator,
          onSaved: onSaved,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red[400],
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
            ),
          ),
      ],
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildAdvancedToggle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: _showAdvanced ? Colors.white10 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _showAdvanced = !_showAdvanced;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Advanced Settings',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
            AnimatedRotation(
              turns: _showAdvanced ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: const HeroIcon(
                HeroIcons.chevronDown,
                color: Colors.white70,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildLoginButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isLoading
          ? _buildLoadingIndicator()
          : Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ).animate().scale(duration: const Duration(milliseconds: 200)),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 50,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildLinks() {
    return Column(
      children: [
        _buildLinkButton(
          icon: HeroIcons.globeAlt,
          text: 'Visit our website',
          url: 'https://vanguardbackup.com',
        ),
        const SizedBox(height: 16),
        _buildLinkButton(
          icon: HeroIcons.bookOpen,
          text: 'Read the documentation',
          url: 'https://docs.vanguardbackup.com',
        ),
        const SizedBox(height: 16),
        _buildLinkButton(
          icon: HeroIcons.codeBracketSquare,
          text: 'GitHub repository',
          url: 'https://github.com/vanguardbackup/vanguard',
        ),
      ]
          .animate(interval: const Duration(milliseconds: 100))
          .fadeIn(duration: const Duration(milliseconds: 300)),
    );
  }

  Widget _buildLinkButton(
      {required HeroIcons icon, required String text, required String url}) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeroIcon(
              icon,
              style: HeroIconStyle.outline,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: const Duration(milliseconds: 200));
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Could not open the link. Please try again later.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildSplashScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/logo.svg',
              height: 48,
              color: Colors.white,
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  duration: const Duration(seconds: 2),
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.1, 1.1),
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    ).animate().fadeOut(
        delay: const Duration(seconds: 1),
        duration: const Duration(milliseconds: 500));
  }
}
