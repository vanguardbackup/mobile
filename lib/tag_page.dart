import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'tag_provider.dart';
import 'tag_model.dart';

class TagsPage extends StatefulWidget {
  @override
  _TagsPageState createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TagProvider>(context, listen: false).fetchTags();
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

  List<Tag> _filterTags(List<Tag> tags) {
    return tags.where((tag) {
      return tag.label.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tags',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildSearch(context),
              SizedBox(height: 16),
              Expanded(
                child: _buildTagList(context),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTagDialog(context),
        child: Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
        tooltip: 'Add new tag',
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

  Widget _buildTagList(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<TagProvider>(
      builder: (context, tagProvider, child) {
        if (tagProvider.tags.isEmpty) {
          return _buildEmptyWidget();
        }

        final filteredTags = _filterTags(tagProvider.tags);

        return ListView.builder(
          itemCount: filteredTags.length,
          itemBuilder: (context, index) {
            final tag = filteredTags[index];
            return TagListItem(
              tag: tag,
              onEdit: () => _showEditTagDialog(context, tag),
              onDelete: () => _showDeleteTagDialog(context, tag),
            );
          },
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
              HeroIcons.tag,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No tags found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add a new tag to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog(BuildContext context) {
    final labelController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Tag'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Add'),
              onPressed: () {
                if (labelController.text.isNotEmpty) {
                  Provider.of<TagProvider>(context, listen: false).createTag(
                    labelController.text,
                    description: descriptionController.text,
                  ).then((_) {
                    Navigator.of(context).pop();
                    _showSnackBar('Tag created successfully', isSuccess: true);
                  }).catchError((error) {
                    _showSnackBar('Failed to create tag: $error', isSuccess: false);
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditTagDialog(BuildContext context, Tag tag) {
    final labelController = TextEditingController(text: tag.label);
    final descriptionController = TextEditingController(text: tag.description);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Tag'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Update'),
              onPressed: () {
                if (labelController.text.isNotEmpty) {
                  Provider.of<TagProvider>(context, listen: false).updateTag(
                    tag.id,
                    label: labelController.text,
                    description: descriptionController.text,
                  ).then((_) {
                    Navigator.of(context).pop();
                    _showSnackBar('Tag updated successfully', isSuccess: true);
                  }).catchError((error) {
                    _showSnackBar('Failed to update tag: $error', isSuccess: false);
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteTagDialog(BuildContext context, Tag tag) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Tag'),
          content: Text('Are you sure you want to delete this tag?'),
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
                Provider.of<TagProvider>(context, listen: false).deleteTag(tag.id).then((_) {
                  Navigator.of(context).pop();
                  _showSnackBar('Tag deleted successfully', isSuccess: true);
                }).catchError((error) {
                  _showSnackBar('Failed to delete tag: $error', isSuccess: false);
                });
              },
            ),
          ],
        );
      },
    );
  }
}

class TagListItem extends StatelessWidget {
  final Tag tag;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  TagListItem({required this.tag, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: _buildTagIcon(context),
        title: Text(
          tag.label,
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onBackground),
        ),
        subtitle: tag.description != null && tag.description!.isNotEmpty
            ? Text(
          tag.description!,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.7)),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: HeroIcon(HeroIcons.pencil, size: 20),
              onPressed: onEdit,
              tooltip: 'Edit tag',
            ),
            IconButton(
              icon: HeroIcon(HeroIcons.trash, size: 20),
              onPressed: onDelete,
              tooltip: 'Delete tag',
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TagDetailPage(tag: tag),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTagIcon(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: HeroIcon(
        HeroIcons.tag,
        color: theme.colorScheme.primary,
        size: 24,
      ),
    );
  }
}

class TagDetailPage extends StatelessWidget {
  final Tag tag;

  TagDetailPage({required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Tag Details', style: TextStyle(color: theme.colorScheme.onBackground)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: HeroIcon(HeroIcons.arrowLeft, color: theme.colorScheme.onBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tag.label,
              style: TextStyle(color: theme.colorScheme.onBackground, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildDetailItem(context, HeroIcons.tag, 'Label', tag.label),
            if (tag.description != null && tag.description!.isNotEmpty)
              _buildDetailItem(context, HeroIcons.documentText, 'Description', tag.description!),
            _buildDetailItem(context, HeroIcons.calendar, 'Created At', _formatDate(tag.createdAt)),
            _buildDetailItem(context, HeroIcons.pencil, 'Updated At', _formatDate(tag.updatedAt)),
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
    const SizedBox(width: 16),
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
    ],
    ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(date);
  }
}