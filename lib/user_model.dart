class User {
  final int id;
  final PersonalInfo personalInfo;
  final AccountSettings accountSettings;
  final BackupTasks backupTasks;
  final RelatedEntities relatedEntities;
  final Timestamps timestamps;

  User({
    required this.id,
    required this.personalInfo,
    required this.accountSettings,
    required this.backupTasks,
    required this.relatedEntities,
    required this.timestamps,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return User(
      id: data['id'],
      personalInfo: PersonalInfo.fromJson(data['personal_info']),
      accountSettings: AccountSettings.fromJson(data['account_settings']),
      backupTasks: BackupTasks.fromJson(data['backup_tasks']),
      relatedEntities: RelatedEntities.fromJson(data['related_entities']),
      timestamps: Timestamps.fromJson(data['timestamps']),
    );
  }
}

class PersonalInfo {
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;

  PersonalInfo({
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      name: json['name'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
    );
  }
}

class AccountSettings {
  final String timezone;
  final String language;
  final bool isAdmin;
  final bool githubLoginEnabled;
  final bool weeklySummaryEnabled;

  AccountSettings({
    required this.timezone,
    required this.language,
    required this.isAdmin,
    required this.githubLoginEnabled,
    required this.weeklySummaryEnabled,
  });

  factory AccountSettings.fromJson(Map<String, dynamic> json) {
    return AccountSettings(
      timezone: json['timezone'],
      language: json['language'],
      isAdmin: json['is_admin'],
      githubLoginEnabled: json['github_login_enabled'],
      weeklySummaryEnabled: json['weekly_summary_enabled'],
    );
  }
}

class BackupTasks {
  final int total;
  final int active;
  final LogInfo logs;

  BackupTasks({
    required this.total,
    required this.active,
    required this.logs,
  });

  factory BackupTasks.fromJson(Map<String, dynamic> json) {
    return BackupTasks(
      total: json['total'],
      active: json['active'],
      logs: LogInfo.fromJson(json['logs']),
    );
  }
}

class LogInfo {
  final int total;
  final int today;

  LogInfo({
    required this.total,
    required this.today,
  });

  factory LogInfo.fromJson(Map<String, dynamic> json) {
    return LogInfo(
      total: json['total'],
      today: json['today'],
    );
  }
}

class RelatedEntities {
  final int remoteServers;
  final int backupDestinations;
  final int tags;
  final int notificationStreams;

  RelatedEntities({
    required this.remoteServers,
    required this.backupDestinations,
    required this.tags,
    required this.notificationStreams,
  });

  factory RelatedEntities.fromJson(Map<String, dynamic> json) {
    return RelatedEntities(
      remoteServers: json['remote_servers'],
      backupDestinations: json['backup_destinations'],
      tags: json['tags'],
      notificationStreams: json['notification_streams'],
    );
  }
}

class Timestamps {
  final DateTime accountCreated;

  Timestamps({
    required this.accountCreated,
  });

  factory Timestamps.fromJson(Map<String, dynamic> json) {
    return Timestamps(
      accountCreated: DateTime.parse(json['account_created']),
    );
  }
}