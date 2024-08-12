import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'notification_stream_provider.dart';
import 'notification_stream_model.dart';

class NotificationStreamsPage extends StatefulWidget {
  @override
  _NotificationStreamsPageState createState() => _NotificationStreamsPageState();
}

class _NotificationStreamsPageState extends State<NotificationStreamsPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationStreamProvider>(context, listen: false).fetchStreams();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  List<NotificationStream> _filterStreams(List<NotificationStream> streams) {
    return streams.where((stream) {
      return stream.label.toLowerCase().contains(_searchQuery.toLowerCase());
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
                'Notification Streams',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildSearch(context),
              SizedBox(height: 16),
              Expanded(
                child: _buildStreamList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: _searchController,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Search by label...',
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
          icon: Icon(Icons.clear, color: theme.colorScheme.primary),
          onPressed: _clearSearch,
        )
            : null,
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
    );
  }

  Widget _buildStreamList(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<NotificationStreamProvider>(
      builder: (context, notificationStreamProvider, child) {
        if (notificationStreamProvider.streams.isEmpty) {
          return _buildEmptyWidget();
        }

        final filteredStreams = _filterStreams(notificationStreamProvider.streams);

        return RefreshIndicator(
          onRefresh: () => notificationStreamProvider.fetchStreams(),
          color: theme.colorScheme.primary,
          backgroundColor: theme.cardColor,
          child: ListView.builder(
            itemCount: filteredStreams.length,
            itemBuilder: (context, index) {
              final stream = filteredStreams[index];
              return NotificationStreamListItem(stream: stream);
            },
          ),
        );
      },
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
              HeroIcons.bellAlert,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No notification streams found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add a new notification stream to get started',
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

class NotificationStreamListItem extends StatelessWidget {
  final NotificationStream stream;

  NotificationStreamListItem({required this.stream});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildStreamIcon(context),
        title: Text(
          stream.label,
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onBackground),
        ),
        subtitle: Text(
          stream.typeHuman,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.7)),
        ),
        trailing: _buildNotificationStatus(context),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationStreamDetailPage(stream: stream),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreamIcon(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: HeroIcon(
        _getIconForType(stream.type),
        color: theme.colorScheme.primary,
        size: 24,
      ),
    );
  }

  Widget _buildNotificationStatus(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HeroIcon(
          stream.notifications.onSuccess ? HeroIcons.check : HeroIcons.xMark,
          color: stream.notifications.onSuccess ? Colors.green : Colors.red,
          size: 16,
        ),
        SizedBox(height: 4),
        HeroIcon(
          stream.notifications.onFailure ? HeroIcons.check : HeroIcons.xMark,
          color: stream.notifications.onFailure ? Colors.green : Colors.red,
          size: 16,
        ),
      ],
    );
  }

  HeroIcons _getIconForType(String type) {
    switch (type) {
      case 'email':
        return HeroIcons.envelope;
      case 'slack':
        return HeroIcons.chatBubbleLeftRight;
      case 'discord':
        return HeroIcons.chatBubbleOvalLeft;
      case 'teams':
        return HeroIcons.userGroup;
      case 'pushover':
        return HeroIcons.devicePhoneMobile;
      default:
        return HeroIcons.bell;
    }
  }
}

class NotificationStreamDetailPage extends StatelessWidget {
  final NotificationStream stream;

  NotificationStreamDetailPage({required this.stream});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Stream Details', style: TextStyle(color: theme.colorScheme.onBackground)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: HeroIcon(HeroIcons.arrowLeft, color: theme.colorScheme.onBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stream.label,
              style: TextStyle(color: theme.colorScheme.onBackground, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            _buildDetailItem(context, HeroIcons.bell, 'Type', stream.typeHuman),
            _buildDetailItem(context, HeroIcons.checkCircle, 'Notify on Success', stream.notifications.onSuccess ? 'Yes' : 'No'),
            _buildDetailItem(context, HeroIcons.xCircle, 'Notify on Failure', stream.notifications.onFailure ? 'Yes' : 'No'),
            _buildDetailItem(context, HeroIcons.calendar, 'Created At', _formatDate(stream.createdAt)),
            _buildDetailItem(context, HeroIcons.pencil, 'Updated At', _formatDate(stream.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, HeroIcons icon, String label, String value) {
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
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(color: theme.colorScheme.onBackground, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(date);
  }
}