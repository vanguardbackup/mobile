import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'backup_destination_provider.dart';
import 'backup_destination_model.dart';

class BackupDestinationsPage extends StatefulWidget {
  @override
  _BackupDestinationsPageState createState() => _BackupDestinationsPageState();
}

class _BackupDestinationsPageState extends State<BackupDestinationsPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BackupDestinationProvider>(context, listen: false).fetchDestinations();
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

  List<BackupDestination> _filterDestinations(List<BackupDestination> destinations) {
    return destinations.where((destination) {
      return destination.label.toLowerCase().contains(_searchQuery.toLowerCase());
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
                'Backup Destinations',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildSearch(context),
              SizedBox(height: 16),
              Expanded(
                child: _buildDestinationList(context),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDestinationDialog(context),
        child: Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
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

  Widget _buildDestinationList(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<BackupDestinationProvider>(
      builder: (context, backupDestinationProvider, child) {
        if (backupDestinationProvider.destinations.isEmpty) {
          return _buildEmptyWidget();
        }

        final filteredDestinations = _filterDestinations(backupDestinationProvider.destinations);

        return RefreshIndicator(
          onRefresh: () => backupDestinationProvider.fetchDestinations(),
          color: theme.colorScheme.primary,
          backgroundColor: theme.cardColor,
          child: ListView.builder(
            itemCount: filteredDestinations.length,
            itemBuilder: (context, index) {
              final destination = filteredDestinations[index];
              return BackupDestinationListItem(
                destination: destination,
                onEdit: () => _showEditDestinationDialog(context, destination),
                onDelete: () => _showDeleteConfirmationDialog(context, destination),
              );
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
              HeroIcons.cloudArrowUp,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No backup destinations found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add a new backup destination to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddDestinationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackupDestinationDialog(
          onSave: (BackupDestination newDestination) {
            Provider.of<BackupDestinationProvider>(context, listen: false)
                .createDestination(newDestination.toJson());
          },
        );
      },
    );
  }

  void _showEditDestinationDialog(BuildContext context, BackupDestination destination) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackupDestinationDialog(
          destination: destination,
          onSave: (BackupDestination updatedDestination) {
            Provider.of<BackupDestinationProvider>(context, listen: false)
                .updateDestination(destination.id, updatedDestination.toJson());
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, BackupDestination destination) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Backup Destination'),
          content: Text('Are you sure you want to delete "${destination.label}"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Provider.of<BackupDestinationProvider>(context, listen: false)
                    .deleteDestination(destination.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class BackupDestinationListItem extends StatelessWidget {
  final BackupDestination destination;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  BackupDestinationListItem({
    required this.destination,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildDestinationIcon(context),
        title: Text(
          destination.label,
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onBackground),
        ),
        subtitle: Text(
          destination.typeHuman,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.7)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: HeroIcon(HeroIcons.pencil),
              onPressed: onEdit,
            ),
            IconButton(
              icon: HeroIcon(HeroIcons.trash),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationIcon(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: HeroIcon(
        _getIconForType(destination.type),
        color: theme.colorScheme.primary,
        size: 24,
      ),
    );
  }

  HeroIcons _getIconForType(String type) {
    switch (type) {
      case 's3':
        return HeroIcons.cloudArrowUp;
      case 'custom_s3':
        return HeroIcons.server;
      case 'local':
        return HeroIcons.folderOpen;
      default:
        return HeroIcons.questionMarkCircle;
    }
  }
}

class BackupDestinationDialog extends StatefulWidget {
  final BackupDestination? destination;
  final Function(BackupDestination) onSave;

  BackupDestinationDialog({this.destination, required this.onSave});

  @override
  _BackupDestinationDialogState createState() => _BackupDestinationDialogState();
}

class _BackupDestinationDialogState extends State<BackupDestinationDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _label;
  late String _type;
  late String? _s3BucketName;
  late bool _pathStyleEndpoint;
  late String? _s3Region;
  late String? _s3Endpoint;

  @override
  void initState() {
    super.initState();
    _label = widget.destination?.label ?? '';
    _type = widget.destination?.type ?? 's3';
    _s3BucketName = widget.destination?.s3BucketName;
    _pathStyleEndpoint = widget.destination?.pathStyleEndpoint ?? false;
    _s3Region = widget.destination?.s3Region;
    _s3Endpoint = widget.destination?.s3Endpoint;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.destination == null ? 'Add Backup Destination' : 'Edit Backup Destination'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                initialValue: _label,
                decoration: InputDecoration(labelText: 'Label'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a label';
                  }
                  return null;
                },
                onSaved: (value) => _label = value!,
              ),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(labelText: 'Type'),
                items: ['s3', 'custom_s3', 'local'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _type = newValue!;
                  });
                },
              ),
              if (_type != 'local') ...[
                TextFormField(
                  initialValue: _s3BucketName,
                  decoration: InputDecoration(labelText: 'S3 Bucket Name'),
                  validator: (value) {
                    if (_type != 'local' && (value == null || value.isEmpty)) {
                      return 'Please enter an S3 bucket name';
                    }
                    return null;
                  },
                  onSaved: (value) => _s3BucketName = value,
                ),
                CheckboxListTile(
                  title: Text('Path Style Endpoint'),
                  value: _pathStyleEndpoint,
                  onChanged: (bool? value) {
                    setState(() {
                      _pathStyleEndpoint = value!;
                    });
                  },
                ),
              ],
              if (_type == 's3')
                TextFormField(
                  initialValue: _s3Region,
                  decoration: InputDecoration(labelText: 'S3 Region'),
                  onSaved: (value) => _s3Region = value,
                ),
              if (_type == 'custom_s3')
                TextFormField(
                  initialValue: _s3Endpoint,
                  decoration: InputDecoration(labelText: 'S3 Endpoint'),
                  validator: (value) {
                    if (_type == 'custom_s3' && (value == null || value.isEmpty)) {
                      return 'Please enter an S3 endpoint';
                    }
                    return null;
                  },
                  onSaved: (value) => _s3Endpoint = value,
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Save'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final destination = BackupDestination(
                id: widget.destination?.id ?? 0,
                userId: widget.destination?.userId ?? 0,
                label: _label,
                type: _type,
                typeHuman: _type,  // This should be properly mapped in a real scenario
                s3BucketName: _s3BucketName,
                pathStyleEndpoint: _pathStyleEndpoint,
                s3Region: _s3Region,
                s3Endpoint: _s3Endpoint,
                createdAt: widget.destination?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );
              widget.onSave(destination);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}