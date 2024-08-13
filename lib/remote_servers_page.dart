import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'remote_server_provider.dart';
import 'remote_server_model.dart';

class RemoteServersPage extends StatefulWidget {
  @override
  _RemoteServersPageState createState() => _RemoteServersPageState();
}

class _RemoteServersPageState extends State<RemoteServersPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RemoteServerProvider>(context, listen: false).fetchServers();
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

  List<RemoteServer> _filterServers(List<RemoteServer> servers) {
    return servers.where((server) {
      return server.label.toLowerCase().contains(_searchQuery.toLowerCase());
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
                'Remote Servers',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildSearch(context),
              SizedBox(height: 16),
              Expanded(
                child: _buildServerList(context),
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
        hintStyle:
            TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
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

  Widget _buildServerList(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<RemoteServerProvider>(
      builder: (context, remoteServerProvider, child) {
        if (remoteServerProvider.servers.isEmpty) {
          return _buildEmptyWidget();
        }

        final filteredServers = _filterServers(remoteServerProvider.servers);

        return RefreshIndicator(
          onRefresh: () => remoteServerProvider.fetchServers(),
          color: theme.colorScheme.primary,
          backgroundColor: theme.cardColor,
          child: ListView.builder(
            itemCount: filteredServers.length,
            itemBuilder: (context, index) {
              final server = filteredServers[index];
              return RemoteServerListItem(server: server);
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
              HeroIcons.server,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No remote servers found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add a new remote server to get started',
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

class RemoteServerListItem extends StatelessWidget {
  final RemoteServer server;

  RemoteServerListItem({required this.server});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildServerIcon(context),
        title: Text(
          server.label,
          style: theme.textTheme.titleMedium
              ?.copyWith(color: theme.colorScheme.onBackground),
        ),
        subtitle: Text(
          server.connection.ipAddress,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7)),
        ),
        trailing: _buildStatusIcon(context, server.status.connectivity),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RemoteServerDetailPage(server: server),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServerIcon(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: HeroIcon(
        HeroIcons.server,
        color: theme.colorScheme.primary,
        size: 24,
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context, String connectivity) {
    final theme = Theme.of(context);
    switch (connectivity.toLowerCase()) {
      case 'connected':
        return HeroIcon(HeroIcons.check, color: Colors.green, size: 24);
      case 'disconnected':
        return HeroIcon(HeroIcons.xMark, color: Colors.red, size: 24);
      default:
        return HeroIcon(HeroIcons.questionMarkCircle,
            color: Colors.grey, size: 24);
    }
  }
}

class RemoteServerDetailPage extends StatelessWidget {
  final RemoteServer server;

  RemoteServerDetailPage({required this.server});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Server Details',
            style: TextStyle(color: theme.colorScheme.onBackground)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: HeroIcon(HeroIcons.arrowLeft,
              color: theme.colorScheme.onBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              server.label,
              style: TextStyle(
                  color: theme.colorScheme.onBackground,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            _buildDetailItem(context, HeroIcons.server, 'IP Address',
                server.connection.ipAddress),
            _buildDetailItem(context, HeroIcons.user, 'Username',
                server.connection.username),
            _buildDetailItem(context, HeroIcons.lockClosed, 'Database Password',
                server.connection.isDatabasePasswordSet ? 'Set' : 'Not Set'),
            _buildDetailItem(context, HeroIcons.signalSlash, 'Port',
                server.connection.port.toString()),
            _buildDetailItem(context, HeroIcons.signal, 'Connectivity',
                _capitalizeFirstLetter(server.status.connectivity)),
            _buildDetailItem(context, HeroIcons.clock, 'Last Connected',
                _formatDate(server.status.lastConnectedAt)),
            _buildDetailItem(context, HeroIcons.calendar, 'Created At',
                _formatDate(server.createdAt)),
            _buildDetailItem(context, HeroIcons.pencil, 'Updated At',
                _formatDate(server.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      BuildContext context, HeroIcons icon, String label, String value) {
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(date);
  }

  String _capitalizeFirstLetter(String text) {
    return text.isEmpty
        ? ''
        : text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
