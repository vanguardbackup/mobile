import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'backup_task_provider.dart';
import 'backup_task_model.dart';

class BackupTasksPage extends StatefulWidget {
  @override
  _BackupTasksPageState createState() => _BackupTasksPageState();
}

class _BackupTasksPageState extends State<BackupTasksPage> {
  Timer? _pollTimer;
  String _searchQuery = '';
  String? _selectedType;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BackupTaskProvider>(context, listen: false).fetchBackupTasks();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: 5), (_) {
      Provider.of<BackupTaskProvider>(context, listen: false).fetchBackupTasks();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
  }

  void _clearSearchAndFilter() {
    setState(() {
      _searchQuery = '';
      _selectedType = null;
      _searchController.clear();
    });
  }

  List<BackupTask> _filterTasks(List<BackupTask> tasks) {
    return tasks.where((task) {
      bool matchesSearch = task.label.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesType = _selectedType == null || task.source.type.toLowerCase() == _selectedType!.toLowerCase();
      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Backup Tasks',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildSearchAndFilter(context),
              SizedBox(height: 16),
              Expanded(
                child: _buildTaskList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Search by label...',
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    hint: Text('Filter by type', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                    icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                    isExpanded: true,
                    dropdownColor: theme.colorScheme.surface,
                    items: [null, 'database', 'files'].map((String? value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value?.capitalize() ?? 'All',
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedType = newValue;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: _clearSearchAndFilter,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskList(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<BackupTaskProvider>(
      builder: (context, backupTaskProvider, child) {
        if (backupTaskProvider.error != null) {
          return _buildErrorWidget(backupTaskProvider);
        }

        if (backupTaskProvider.backupTasks == null) {
          return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
        }

        final filteredTasks = _filterTasks(backupTaskProvider.backupTasks!);

        if (filteredTasks.isEmpty) {
          return _buildEmptyWidget();
        }

        bool hasRunningTask = filteredTasks.any((task) => task.status.toLowerCase() == 'running');
        if (hasRunningTask) {
          _startPolling();
        } else {
          _stopPolling();
        }

        return RefreshIndicator(
          onRefresh: () => backupTaskProvider.fetchBackupTasks(),
          color: theme.colorScheme.primary,
          backgroundColor: theme.cardColor,
          child: ListView.builder(
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              return BackupTaskListItem(task: task);
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(BackupTaskProvider provider) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: HeroIcon(
              HeroIcons.exclamationCircle,
              color: theme.colorScheme.error,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Error: ${provider.error}',
            style: TextStyle(color: theme.colorScheme.error, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => provider.fetchBackupTasks(),
            icon: HeroIcon(HeroIcons.arrowPath, color: theme.colorScheme.onPrimary, size: 18),
            label: Text('Retry', style: TextStyle(color: theme.colorScheme.onPrimary)),
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
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
              HeroIcons.folderOpen,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No backup tasks found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a new backup task to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class BackupTaskListItem extends StatelessWidget {
  final BackupTask task;

  BackupTaskListItem({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildTaskTypeIcon(context),
        title: Text(
          task.label,
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onBackground),
        ),
        subtitle: Text(
          '${_capitalizeFirstLetter(task.source.type)} - ${_formatSchedule(task.schedule)}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.7)),
        ),
        trailing: _buildStatusIcon(context, task.status),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BackupTaskDetailPage(task: task),
            ),
          );
          Provider.of<BackupTaskProvider>(context, listen: false).fetchBackupTasks();
        },
      ),
    );
  }

  Widget _buildTaskTypeIcon(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: HeroIcon(
        task.source.type.toLowerCase() == 'database' ? HeroIcons.circleStack : HeroIcons.folder,
        color: theme.colorScheme.primary,
        size: 24,
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context, String status) {
    final theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'ready':
        return HeroIcon(HeroIcons.check, color: Colors.green, size: 24);
      case 'running':
        return RotatingIcon(
          child: HeroIcon(HeroIcons.arrowPath, color: theme.colorScheme.primary, size: 24),
        );
      default:
        return HeroIcon(HeroIcons.questionMarkCircle, color: Colors.grey, size: 24);
    }
  }

  String _formatSchedule(ScheduleInfo schedule) {
    if (schedule.customCron != null) {
      return 'Custom: ${schedule.customCron}';
    } else {
      return '${_capitalizeFirstLetter(schedule.frequency)} at ${schedule.scheduledLocalTime}';
    }
  }

  String _capitalizeFirstLetter(String text) {
    return text.isEmpty ? '' : text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

class BackupTaskDetailPage extends StatefulWidget {
  final BackupTask task;

  BackupTaskDetailPage({required this.task});

  @override
  _BackupTaskDetailPageState createState() => _BackupTaskDetailPageState();
}

class _BackupTaskDetailPageState extends State<BackupTaskDetailPage> with SingleTickerProviderStateMixin {
  late Timer _pollTimer;
  late BackupTask _currentTask;
  late AnimationController _animationController;
  late Animation<double> _animation;
  BackupTaskLog? _latestLog;
  bool _isLoading = false;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _isRunning = _currentTask.status.toLowerCase() == 'running';
    _startPolling();
    _fetchLatestLog();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _pollTimer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _pollTaskStatus();
    });
  }

  Future<void> _pollTaskStatus() async {
    final backupTaskProvider = Provider.of<BackupTaskProvider>(context, listen: false);
    final updatedTask = await backupTaskProvider.getBackupTask(_currentTask.id);
    if (updatedTask != null && mounted) {
      setState(() {
        _currentTask = updatedTask;
        _isRunning = _currentTask.status.toLowerCase() == 'running';
      });
      if (!_isRunning && _latestLog == null) {
        _fetchLatestLog();
      }
    }
  }

  Future<void> _fetchLatestLog() async {
    setState(() {
      _isLoading = true;
    });
    final backupTaskProvider = Provider.of<BackupTaskProvider>(context, listen: false);
    final latestLog = await backupTaskProvider.getLatestBackupTaskLog(_currentTask.id);
    if (mounted) {
      setState(() {
        _latestLog = latestLog;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
        onWillPop: () async {
      await _animationController.reverse();
      return true;
    },
    child: Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,
    appBar: AppBar(
    title: Text('Task Details', style: TextStyle(color: theme.colorScheme.onBackground)),
    backgroundColor: theme.scaffoldBackgroundColor,
    elevation: 0,
    leading: IconButton(
    icon: HeroIcon(HeroIcons.arrowLeft, color: theme.colorScheme.onBackground),
    onPressed: () async {
    await _animationController.reverse();
    Navigator.of(context).pop();
    },
    ),
    ),
    body: FadeTransition(
    opacity: _animation,
    child: RefreshIndicator(
    onRefresh: _fetchLatestLog,
    color: theme.colorScheme.primary,
    backgroundColor: theme.cardColor,
    child: SingleChildScrollView(
    physics: AlwaysScrollableScrollPhysics(),
    padding: EdgeInsets.all(16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    _currentTask.label,
    style: TextStyle(color: theme.colorScheme.onBackground, fontSize: 24, fontWeight: FontWeight.bold),
    ),
    SizedBox(height: 8),
    Text(
    _currentTask.description,
    style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7), fontSize: 16),
    ),
    SizedBox(height: 24),
      _buildDetailItem(context, HeroIcons.clock, 'Schedule', _formatSchedule(_currentTask.schedule)),
      _buildDetailItem(context, HeroIcons.folderOpen, 'Source', _formatSource(_currentTask.source)),
      _buildDetailItem(context, HeroIcons.server, 'Storage', _formatStorage(_currentTask.storage)),
      _buildDetailItem(
        context,
        HeroIcons.clock,
        'Last Run',
        _currentTask.timestamps.lastRunLocalTime ?? 'Never',
      ),
      _buildDetailItem(
        context,
        HeroIcons.chartBar,
        'Status',
        _capitalizeFirstLetter(_currentTask.status),
        trailing: _isRunning ? _buildRotatingIcon(context) : null,
      ),
      const SizedBox(height: 32),
      _buildLatestLogSection(context),
      const SizedBox(height: 80), // Add extra space at the bottom for the floating button
    ],
    ),
    ),
    ),
    ),
      floatingActionButton: _buildRunBackupButton(context),
    ),
    );
  }

  Widget _buildRunBackupButton(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton.extended(
      onPressed: _isRunning ? null : () => _showRunBackupConfirmation(context),
      backgroundColor: _isRunning ? Colors.grey : theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      icon: _isRunning
          ? _buildRotatingIcon(context)
          : HeroIcon(HeroIcons.play, color: theme.colorScheme.onPrimary, size: 20),
      label: Text(
        _isRunning ? 'Running...' : 'Run Task',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLatestLogSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Backup Log',
          style: TextStyle(color: theme.colorScheme.onBackground, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        if (_isLoading)
          Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
        else if (_latestLog == null)
          Text('No log available', style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7)))
        else
          GestureDetector(
            onTap: () => _showLogModal(context),
            child: Card(
              color: theme.cardColor,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status: ${_capitalizeFirstLetter(_latestLog!.status)}',
                            style: TextStyle(color: _getStatusColor(_latestLog!.status), fontWeight: FontWeight.bold)),
                        Text(_formatDate(_latestLog!.finishedAt), style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7))),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Output:', style: TextStyle(color: theme.colorScheme.onBackground, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(_latestLog!.output, style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7))),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Tap to view full log',
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showLogModal(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: theme.dialogBackgroundColor,
          child: Container(
            padding: EdgeInsets.all(16),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Backup Log',
                      style: TextStyle(color: theme.colorScheme.onBackground, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: HeroIcon(HeroIcons.xMark, color: theme.colorScheme.onBackground),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status: ${_capitalizeFirstLetter(_latestLog!.status)}',
                        style: TextStyle(color: _getStatusColor(_latestLog!.status), fontWeight: FontWeight.bold)),
                    Text(_formatDate(_latestLog!.finishedAt), style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7))),
                  ],
                ),
                SizedBox(height: 16),
                Text('Output:', style: TextStyle(color: theme.colorScheme.onBackground, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(_latestLog!.output, style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7))),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(BuildContext context, HeroIcons icon, String label, String value, {Widget? trailing}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroIcon(icon, color: theme.colorScheme.onBackground.withOpacity(0.7), size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(color: theme.colorScheme.onBackground, fontSize: 16),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildRotatingIcon(BuildContext context) {
    final theme = Theme.of(context);
    return RotatingIcon(
      child: HeroIcon(HeroIcons.arrowPath, color: theme.colorScheme.primary, size: 24),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'successful':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.yellow;
    }
  }

  String _formatSchedule(ScheduleInfo schedule) {
    if (schedule.customCron != null) {
      return 'Custom: ${schedule.customCron}';
    } else {
      return '${_capitalizeFirstLetter(schedule.frequency)} at ${schedule.scheduledLocalTime}';
    }
  }

  String _formatSource(SourceInfo source) {
    String result = '${_capitalizeFirstLetter(source.type)}: ${source.path}';
    if (source.type.toLowerCase() == 'database') {
      result += '\nDatabase: ${source.databaseName}';
      if (source.excludedTables != null && source.excludedTables!.isNotEmpty) {
        result += '\nExcluded Tables: ${source.excludedTables}';
      }
    }
    return result;
  }

  String _formatStorage(StorageInfo storage) {
    String result = 'Max ${storage.maxBackups} backups at ${storage.path}';
    if (storage.appendedFilename != null) {
      result += '\nAppended Filename: ${storage.appendedFilename}';
    }
    return result;
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(date);
  }

  String _capitalizeFirstLetter(String text) {
    return text.isEmpty ? '' : text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  void _showRunBackupConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Text('Run Backup Task', style: TextStyle(color: theme.colorScheme.onBackground)),
          content: Text('Are you sure you want to run this backup task now?', style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7))),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Run', style: TextStyle(color: theme.colorScheme.primary)),
              onPressed: () {
                Navigator.of(context).pop();
                _runBackupTask(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _runBackupTask(BuildContext context) async {
    final backupTaskProvider = Provider.of<BackupTaskProvider>(context, listen: false);

    setState(() {
      _currentTask = _currentTask.copyWith(status: 'running');
      _isRunning = true;
    });

    try {
      final response = await backupTaskProvider.runBackupTask(_currentTask.id);

      if (response.statusCode == 202) {
        _showSnackBar(context, response.message, SnackBarType.success);
        _pollTaskStatus(); // Immediately poll for status update
      } else {
        _showSnackBar(context, response.message, SnackBarType.error);
      }
    } catch (e) {
      _showSnackBar(context, 'An unexpected error occurred', SnackBarType.error);
    } finally {
      // Continue polling until the task is no longer running
      _pollUntilCompleted();
    }
  }

  void _pollUntilCompleted() {
    Timer.periodic(Duration(seconds: 5), (timer) async {
      await _pollTaskStatus();
      if (!_isRunning) {
        timer.cancel();
        _fetchLatestLog(); // Fetch the latest log after the task completes
      }
    });
  }

  void _showSnackBar(BuildContext context, String message, SnackBarType type) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              type == SnackBarType.success ? Icons.check_circle : Icons.error,
              color: theme.colorScheme.onPrimary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(message, style: TextStyle(color: theme.colorScheme.onPrimary)),
            ),
          ],
        ),
        backgroundColor: type == SnackBarType.success ? Colors.green : theme.colorScheme.error,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          textColor: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

enum SnackBarType { success, error }

class RotatingIcon extends StatefulWidget {
  final Widget child;

  RotatingIcon({required this.child});

  @override
  _RotatingIconState createState() => _RotatingIconState();
}

class _RotatingIconState extends State<RotatingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: widget.child,
    );
  }
}

extension BackupTaskExtension on BackupTask {
  BackupTask copyWith({
    int? id,
    int? userId,
    int? remoteServerId,
    int? backupDestinationId,
    String? label,
    String? description,
    SourceInfo? source,
    ScheduleInfo? schedule,
    StorageInfo? storage,
    int? notificationStreamsCount,
    String? status,
    bool? hasIsolatedCredentials,
    Timestamps? timestamps,
  }) {
    return BackupTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      remoteServerId: remoteServerId ?? this.remoteServerId,
      backupDestinationId: backupDestinationId ?? this.backupDestinationId,
      label: label ?? this.label,
      description: description ?? this.description,
      source: source ?? this.source,
      schedule: schedule ?? this.schedule,
      storage: storage ?? this.storage,
      notificationStreamsCount: notificationStreamsCount ?? this.notificationStreamsCount,
      status: status ?? this.status,
      hasIsolatedCredentials: hasIsolatedCredentials ?? this.hasIsolatedCredentials,
      timestamps: timestamps ?? this.timestamps,
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}