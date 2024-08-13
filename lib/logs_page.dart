import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';
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
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreLogs();
    }
  }

  Future<void> _loadLogs() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final logProvider =
          Provider.of<BackupTaskLogProvider>(context, listen: false);
      await logProvider.fetchLogs(perPage: 20, search: _searchQuery);
    } catch (e) {
      _showSnackBar(e.toString(), isSuccess: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final logProvider =
          Provider.of<BackupTaskLogProvider>(context, listen: false);
      await logProvider.loadMoreLogs(perPage: 20);
    } catch (e) {
      _showSnackBar(e.toString(), isSuccess: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshLogs() async {
    setState(() => _isLoading = true);

    try {
      final logProvider =
          Provider.of<BackupTaskLogProvider>(context, listen: false);
      await logProvider.forceRefresh(perPage: 20);
      _showSnackBar('Logs refreshed successfully', isSuccess: true);
    } on RateLimitException catch (e) {
      _showSnackBar(e.toString(), isSuccess: false);
    } catch (e) {
      _showSnackBar('Failed to refresh logs', isSuccess: false);
    } finally {
      setState(() => _isLoading = false);
    }
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

  void _debounce(VoidCallback callback,
      {Duration duration = const Duration(milliseconds: 500)}) {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(duration, callback);
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Backup Task Logs',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const HeroIcon(HeroIcons.arrowPath),
                        onPressed: _refreshLogs,
                        tooltip: 'Refresh logs',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSearchBar(context),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildLogsList(context),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
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
        hintStyle:
            TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: theme.colorScheme.primary),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
            : null,
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

  Widget _buildLogsList(BuildContext context) {
    return Consumer<BackupTaskLogProvider>(
      builder: (context, logProvider, child) {
        if (logProvider.logs.isEmpty && !_isLoading) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount:
              logProvider.logs.length + (logProvider.hasMoreLogs ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == logProvider.logs.length) {
              return _buildLoadingIndicator();
            }
            return _buildLogItem(context, logProvider.logs[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: HeroIcon(
              HeroIcons.documentText,
              size: 48,
              color: theme.colorScheme.primary,
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

  Widget _buildLogItem(BuildContext context, BackupTaskLogEntry log) {
    final theme = Theme.of(context);
    return FutureBuilder<BackupTask?>(
      future: Provider.of<BackupTaskProvider>(context, listen: false)
          .getBackupTask(log.backupTaskId),
      builder: (context, snapshot) {
        final backupTask = snapshot.data;
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: HeroIcon(
                log.status == 'successful'
                    ? HeroIcons.checkCircle
                    : HeroIcons.xCircle,
                color: log.status == 'successful' ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            title: Text(
              backupTask?.label ?? 'Backup Task #${log.backupTaskId}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onBackground),
            ),
            subtitle: Text(
              'Status: ${log.status}\nFinished at: ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(log.finishedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: HeroIcon(HeroIcons.trash, size: 20),
                  onPressed: () => _showDeleteLogDialog(context, log),
                  tooltip: 'Delete log',
                ),
                IconButton(
                  icon: HeroIcon(HeroIcons.informationCircle, size: 20),
                  onPressed: () => _showLogDetails(context, log, backupTask),
                  tooltip: 'View details',
                ),
              ],
            ),
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

  void _showDeleteLogDialog(BuildContext context, BackupTaskLogEntry log) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Log'),
          content: Text('Are you sure you want to delete this log?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Provider.of<BackupTaskLogProvider>(context, listen: false)
                    .deleteLog(log.id)
                    .then((_) {
                  Navigator.of(context).pop();
                  _showSnackBar('Log deleted successfully', isSuccess: true);
                }).catchError((error) {
                  _showSnackBar('Failed to delete log: $error',
                      isSuccess: false);
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogDetailItem(BuildContext context, String label, String value,
      {required HeroIcons icon}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroIcon(icon,
              color: theme.colorScheme.onBackground.withOpacity(0.7), size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                      color: theme.colorScheme.onBackground, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogDetails(
      BuildContext context, BackupTaskLogEntry log, BackupTask? backupTask) {
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
                  _buildLogDetailItem(context, 'Status', log.status,
                      icon: HeroIcons.informationCircle),
                  _buildLogDetailItem(
                      context, 'Backup Task ID', log.backupTaskId.toString(),
                      icon: HeroIcons.hashtag),
                  _buildLogDetailItem(
                      context,
                      'Finished At',
                      DateFormat('MMM d, yyyy \'at\' h:mm a')
                          .format(log.finishedAt),
                      icon: HeroIcons.clock),
                  _buildLogDetailItem(
                      context,
                      'Created At',
                      DateFormat('MMM d, yyyy \'at\' h:mm a')
                          .format(log.createdAt),
                      icon: HeroIcons.calendar),
                  if (backupTask != null) ...[
                    _buildLogDetailItem(
                        context, 'Source Type', backupTask.source.type,
                        icon: HeroIcons.folder),
                    _buildLogDetailItem(
                        context, 'Source Path', backupTask.source.path,
                        icon: HeroIcons.folderOpen),
                    _buildLogDetailItem(
                        context, 'Storage Path', backupTask.storage.path,
                        icon: HeroIcons.archiveBox),
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
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline),
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
}
