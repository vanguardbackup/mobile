import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:vanguard/login_page.dart';
import 'package:vanguard/auth_manager.dart';
import 'package:vanguard/user_provider.dart';

// Generate mocks
@GenerateMocks([AuthManager, UserProvider])
import 'login_page_test.mocks.dart';

void main() {
  late MockAuthManager mockAuthManager;
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockAuthManager = MockAuthManager();
    mockUserProvider = MockUserProvider();
  });

  Widget createLoginPage() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>.value(value: mockUserProvider),
        ],
        child: LoginPage(authManager: mockAuthManager),
      ),
    );
  }

  testWidgets('LoginPage has email and password fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(createLoginPage());
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('LoginPage has a login button', (WidgetTester tester) async {
    await tester.pumpWidget(createLoginPage());
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('Tapping login button with empty fields shows validation errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(createLoginPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('Shows error dialog on login failure',
      (WidgetTester tester) async {
    when(mockUserProvider.login(any, any)).thenAnswer((_) async => false);

    await tester.pumpWidget(createLoginPage());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('Login Error'), findsOneWidget);
  });
}
