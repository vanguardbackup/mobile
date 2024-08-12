import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'backup_task_log_provider.dart';
import 'backup_task_provider.dart';
import 'backup_task_model.dart';
import 'backup_task_log_model.dart';

class BackupTaskLogsPage extends StatefulWidget {
  @override
  _BackupTaskLogsPageState createState() => _BackupTaskLogsPageState();
}

class _BackupTaskLogsPageState extends State<BackupTaskLogsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadLogs();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreLogs();
    }
  }

  Future<void> _loadLogs() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final logProvider = Provider.of<BackupTaskLogProvider>(context, listen: false);
    await logProvider.fetchLogs(perPage: 20, search: _searchQuery);

    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreLogs() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final logProvider = Provider.of<BackupTaskLogProvider>(context, listen: false);
    await logProvider.loadMoreLogs(perPage: 20);

    setState(() => _isLoading = false);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _debounce(() {
      Provider.of<BackupTaskLogProvider>(context, listen: false).clearLogs();
      _loadLogs();
    });
  }

  void _debounce(VoidCallback callback, {Duration duration = const Duration(milliseconds: 500)}) {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(duration, callback);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Backup Task Logs',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildSearchBar(context),
              SizedBox(height: 16),
              Expanded(
                child: _buildLogsList(context, isDarkMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: _searchController,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Search logs...',
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
      ),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildLogsList(BuildContext context, bool isDarkMode) {
    return Consumer<BackupTaskLogProvider>(
      builder: (context, logProvider, child) {
        if (logProvider.logs.isEmpty && !_isLoading) {
          return _buildEmptyState(context, isDarkMode);
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: logProvider.logs.length + (logProvider.hasMoreLogs ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == logProvider.logs.length) {
              return _buildLoadingIndicator();
            }
            return _buildLogItem(context, logProvider.logs[index], isDarkMode);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? theme.colorScheme.primaryContainer : Colors.black.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: HeroIcon(
              HeroIcons.documentText,
              size: 48,
              color: isDarkMode ? theme.colorScheme.onPrimaryContainer : Colors.black,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No logs available',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Logs will appear here once they are generated',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, BackupTaskLogEntry log, bool isDarkMode) {
    final theme = Theme.of(context);
    return FutureBuilder<BackupTask?>(
      future: Provider.of<BackupTaskProvider>(context, listen: false).getBackupTask(log.backupTaskId),
      builder: (context, snapshot) {
        final backupTask = snapshot.data;
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: HeroIcon(
              log.status == 'successful' ? HeroIcons.checkCircle : HeroIcons.xCircle,
              color: log.status == 'successful' ? Colors.green : Colors.red,
            ),
            title: Text(
              backupTask?.label ?? 'Backup Task #${log.backupTaskId}',
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: ${log.status}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Finished at: ${log.finishedAt.toString()}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            trailing: HeroIcon(HeroIcons.chevronRight),
            onTap: () => _showLogDetails(context, log, backupTask),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  void _showLogDetails(BuildContext context, BackupTaskLogEntry log, BackupTask? backupTask) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) {
          return SingleChildScrollView(
            controller: controller,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    backupTask?.label ?? 'Backup Task Log #${log.id}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  _buildLogDetailItem('Status', log.status),
                  _buildLogDetailItem('Backup Task ID', log.backupTaskId.toString()),
                  _buildLogDetailItem('Finished At', log.finishedAt.toString()),
                  _buildLogDetailItem('Created At', log.createdAt.toString()),
                  if (backupTask != null) ...[
                    _buildLogDetailItem('Source Type', backupTask.source.type),
                    _buildLogDetailItem('Source Path', backupTask.source.path),
                    _buildLogDetailItem('Storage Path', backupTask.storage.path),
                  ],
                  SizedBox(height: 16),
                  Text(
                    'Output',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: Text(log.output),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}