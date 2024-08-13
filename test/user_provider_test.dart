import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:vanguard/user_provider.dart';
import 'package:vanguard/auth_manager.dart';

@GenerateMocks([AuthManager, http.Client])
import 'user_provider_test.mocks.dart';

void main() {
  late UserProvider userProvider;
  late MockAuthManager mockAuthManager;
  late MockClient mockClient;

  setUp(() {
    mockAuthManager = MockAuthManager();
    mockClient = MockClient();
    userProvider =
        UserProvider(authManager: mockAuthManager, client: mockClient);
  });

  group('UserProvider', () {
    test('login success', () async {
      when(mockAuthManager.baseUrl).thenReturn('http://example.com');
      when(mockClient.post(Uri.parse('http://example.com/login'),
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer(
              (_) async => http.Response('{"token": "fake_token"}', 200));

      final result =
          await userProvider.login('test@example.com', 'password123');

      expect(result, true);
      verify(mockAuthManager.login('fake_token')).called(1);
    });

    test('login failure', () async {
      when(mockAuthManager.baseUrl).thenReturn('http://example.com');
      when(mockClient.post(Uri.parse('http://example.com/login'),
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async =>
              http.Response('{"error": "Invalid credentials"}', 401));

      final result =
          await userProvider.login('test@example.com', 'wrong_password');

      expect(result, false);
      verifyNever(mockAuthManager.login(any));
    });

    test('fetchUser success', () async {
      when(mockAuthManager.isLoggedIn).thenReturn(true);
      when(mockAuthManager.baseUrl).thenReturn('http://example.com');
      when(mockAuthManager.headers)
          .thenReturn({'Authorization': 'Bearer fake_token'});
      when(mockClient.get(Uri.parse('http://example.com/api/user'),
              headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('''
{
  "data": {
    "id": 1,
    "personal_info": {
      "name": "John Doe",
      "first_name": "John",
      "last_name": "Doe",
      "email": "john@example.com",
      "avatar_url": null
    },
    "account_settings": {
      "timezone": "UTC",
      "language": "en",
      "is_admin": false,
      "github_login_enabled": false,
      "weekly_summary_enabled": true
    },
    "backup_tasks": {
      "total": 5,
      "active": 3,
      "logs": {
        "total": 100,
        "today": 10
      }
    },
    "related_entities": {
      "remote_servers": 2,
      "backup_destinations": 3,
      "tags": 10,
      "notification_streams": 1
    },
    "timestamps": {
      "account_created": "2023-05-01T12:00:00Z"
    }
  }
}
''', 200));

      final result = await userProvider.fetchUser();

      expect(result, true);
      expect(userProvider.user, isNotNull);
      expect(userProvider.user!.id, 1);
      expect(userProvider.user!.personalInfo.name, 'John Doe');
      expect(userProvider.user!.accountSettings.timezone, 'UTC');
      expect(userProvider.user!.backupTasks.total, 5);
      expect(userProvider.user!.relatedEntities.remoteServers, 2);
      expect(userProvider.user!.timestamps.accountCreated,
          DateTime.parse('2023-05-01T12:00:00Z'));
    });

    test('fetchUser failure', () async {
      when(mockAuthManager.isLoggedIn).thenReturn(true);
      when(mockAuthManager.baseUrl).thenReturn('http://example.com');
      when(mockAuthManager.headers)
          .thenReturn({'Authorization': 'Bearer fake_token'});
      when(mockClient.get(Uri.parse('http://example.com/api/user'),
              headers: anyNamed('headers')))
          .thenAnswer(
              (_) async => http.Response('{"error": "Unauthorized"}', 401));

      final result = await userProvider.fetchUser();

      expect(result, false);
      expect(userProvider.user, isNull);
    });

    test('logout', () async {
      await userProvider.logout();

      verify(mockAuthManager.logout()).called(1);
      expect(userProvider.user, isNull);
    });
  });
}
