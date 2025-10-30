import 'dart:convert';

import 'package:api_lens/src/models/api_log.dart';
import 'package:api_lens/src/services/api_logger_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ApiLogsScreen extends StatefulWidget {
  const ApiLogsScreen({super.key});

  @override
  State<ApiLogsScreen> createState() => _ApiLogsScreenState();
}

class _ApiLogsScreenState extends State<ApiLogsScreen>
    with SingleTickerProviderStateMixin {
  final _logger = ApiLoggerService();
  List<ApiLog> _logs = [];
  List<ApiLog> _filteredLogs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterMethod = 'ALL';
  String _filterStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }


  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await _logger.getAllLogs();
    setState(() {
      _logs = logs;
      _filterLogs();
      _isLoading = false;
    });
  }

  void _filterLogs() {
    _filteredLogs = _logs.where((log) {
      final methodMatch = _filterMethod == 'ALL' || log.method == _filterMethod;
      final statusMatch = _filterStatus == 'ALL' ||
          (_filterStatus == 'SUCCESS' &&
              log.statusCode >= 200 &&
              log.statusCode < 300) ||
          (_filterStatus == 'ERROR' && log.statusCode >= 400);
      final searchMatch = _searchQuery.isEmpty ||
          log.url.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.method.toLowerCase().contains(_searchQuery.toLowerCase());
      return methodMatch && statusMatch && searchMatch;
    }).toList();
  }

  void _showSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Confirm'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'API Logs',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1A1A1A)),
            onPressed: () {
              _loadLogs();
            },
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1A1A1A)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'clear') {
                final confirm = await _showConfirmDialog('Clear all logs?');
                if (confirm) {
                  await _logger.clearAllLogs();
                  _loadLogs();
                  _showSnackBar('All logs cleared', Icons.delete_outline);
                }
              } else if (value == 'export') {
                final json = await _logger.exportLogsAsJson();
                await Clipboard.setData(ClipboardData(text: json));
                _showSnackBar('Logs exported to clipboard', Icons.copy_all);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Export All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Clear All', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LogsTabView(
        isLoading: _isLoading,
        filteredLogs: _filteredLogs,
        searchQuery: _searchQuery,
        filterMethod: _filterMethod,
        filterStatus: _filterStatus,
        onSearchChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterLogs();
          });
        },
        onMethodFilterChanged: (value) {
          setState(() {
            _filterMethod = value;
            _filterLogs();
          });
        },
        onStatusFilterChanged: (value) {
          setState(() {
            _filterStatus = value;
            _filterLogs();
          });
        },
      ),
    );
  }
}

// ========================================
// LOGS TAB VIEW
// ========================================

class LogsTabView extends StatelessWidget {
  final bool isLoading;
  final List<ApiLog> filteredLogs;
  final String searchQuery;
  final String filterMethod;
  final String filterStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onMethodFilterChanged;
  final ValueChanged<String> onStatusFilterChanged;

  const LogsTabView({
    super.key,
    required this.isLoading,
    required this.filteredLogs,
    required this.searchQuery,
    required this.filterMethod,
    required this.filterStatus,
    required this.onSearchChanged,
    required this.onMethodFilterChanged,
    required this.onStatusFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filters
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by URL or method...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              // Filters
              Row(
                children: [
                  Expanded(
                    child: FilterChipWidget(
                      label: 'Method',
                      currentValue: filterMethod,
                      options: const [
                        'ALL',
                        'GET',
                        'POST',
                        'PUT',
                        'DELETE',
                        'PATCH'
                      ],
                      onChanged: onMethodFilterChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilterChipWidget(
                      label: 'Status',
                      currentValue: filterStatus,
                      options: const ['ALL', 'SUCCESS', 'ERROR'],
                      onChanged: onStatusFilterChanged,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Results Count
        if (!isLoading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  '${filteredLogs.length} ${filteredLogs.length == 1 ? 'log' : 'logs'}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        // Logs List
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredLogs.isEmpty
                  ? const EmptyStateWidget()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        return LogCard(log: filteredLogs[index]);
                      },
                    ),
        ),
      ],
    );
  }
}

// ========================================
// FILTER CHIP WIDGET
// ========================================

class FilterChipWidget extends StatelessWidget {
  final String label;
  final String currentValue;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.currentValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label: $currentValue',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, size: 20),
          ],
        ),
      ),
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
    );
  }
}

// ========================================
// LOG CARD
// ========================================

class LogCard extends StatelessWidget {
  final ApiLog log;

  const LogCard({super.key, required this.log});

  Color _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return const Color(0xFF10B981);
    if (statusCode >= 300 && statusCode < 400) return const Color(0xFFF59E0B);
    if (statusCode >= 400 && statusCode < 500) return const Color(0xFFEF4444);
    if (statusCode >= 500) return const Color(0xFF8B5CF6);
    return const Color(0xFF64748B);
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF2563EB);
      case 'POST':
        return const Color(0xFF10B981);
      case 'PUT':
        return const Color(0xFFF59E0B);
      case 'DELETE':
        return const Color(0xFFEF4444);
      case 'PATCH':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDuration(int milliseconds) {
    if (milliseconds < 1000) return '${milliseconds}ms';
    return '${(milliseconds / 1000).toStringAsFixed(2)}s';
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  Widget _buildColoredUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return Text(
        url,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: '${uri.scheme}://',
            style: const TextStyle(
              color: Color(0xFF8B5CF6),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          TextSpan(
            text: uri.host,
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          if (uri.path.isNotEmpty)
            TextSpan(
              text: uri.path,
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          if (uri.query.isNotEmpty)
            TextSpan(
              text: '?${uri.query}',
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(log.statusCode);
    final methodColor = _getMethodColor(log.method);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => LogDetailsSheet(log: log),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Method Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: methodColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        log.method,
                        style: TextStyle(
                          color: methodColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${log.statusCode}',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Duration
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(log.duration),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // URL with syntax highlighting
                _buildColoredUrl(log.url),
                const SizedBox(height: 8),
                // Timestamp
                Text(
                  _formatTimestamp(log.timestamp),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================
// DISTRIBUTION CARD
// ========================================

class DistributionCard extends StatelessWidget {
  final Map<dynamic, dynamic> distribution;
  final Color Function(String) getColor;

  const DistributionCard({
    super.key,
    required this.distribution,
    required this.getColor,
  });

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    final total =
        distribution.values.fold<int>(0, (sum, count) => sum + (count as int));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: distribution.entries.map((entry) {
          final key = entry.key.toString();
          final count = entry.value as int;
          final percentage = ((count / total) * 100).toStringAsFixed(1);
          final color = getColor(key);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          key,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$count ($percentage%)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: count / total,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ========================================
// EMPTY STATE WIDGET
// ========================================

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No logs found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'API requests will appear here',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// LOG DETAILS SHEET
// ========================================

class LogDetailsSheet extends StatelessWidget {
  final ApiLog log;

  const LogDetailsSheet({super.key, required this.log});

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF2563EB);
      case 'POST':
        return const Color(0xFF10B981);
      case 'PUT':
        return const Color(0xFFF59E0B);
      case 'DELETE':
        return const Color(0xFFEF4444);
      case 'PATCH':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return const Color(0xFF10B981);
    if (statusCode >= 300 && statusCode < 400) return const Color(0xFFF59E0B);
    if (statusCode >= 400 && statusCode < 500) return const Color(0xFFEF4444);
    if (statusCode >= 500) return const Color(0xFF8B5CF6);
    return const Color(0xFF64748B);
  }

  String _formatDuration(int milliseconds) {
    if (milliseconds < 1000) return '${milliseconds}ms';
    return '${(milliseconds / 1000).toStringAsFixed(2)}s';
  }

  String _formatFullTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  const Text(
                    'Request Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  DetailSection(
                    title: 'Request Information',
                    children: [
                      DetailInfoRow(
                        label: 'Method',
                        value: log.method,
                        color: _getMethodColor(log.method),
                      ),
                      DetailInfoRow(
                        label: 'Status Code',
                        value: '${log.statusCode}',
                        color: _getStatusColor(log.statusCode),
                      ),
                      DetailInfoRow(
                        label: 'Duration',
                        value: _formatDuration(log.duration),
                        color: const Color(0xFF7C3AED),
                      ),
                      DetailInfoRow(
                        label: 'Timestamp',
                        value: _formatFullTimestamp(log.timestamp),
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  UrlSection(url: log.url),
                  const SizedBox(height: 16),
                  DetailSection(
                    title: 'Request Headers',
                    children: [
                      JsonRow(label: 'Headers', jsonString: log.requestHeaders),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DetailSection(
                    title: 'Request Body',
                    children: [
                      JsonRow(label: 'Body', jsonString: log.requestBody),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DetailSection(
                    title: 'Response Headers',
                    children: [
                      JsonRow(
                          label: 'Headers', jsonString: log.responseHeaders),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DetailSection(
                    title: 'Response Body',
                    children: [
                      JsonRow(label: 'Body', jsonString: log.responseBody),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// DETAIL SECTION
// ========================================

class DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const DetailSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ...children,
        ],
      ),
    );
  }
}

// ========================================
// DETAIL INFO ROW
// ========================================

class DetailInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const DetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// URL SECTION
// ========================================

class UrlSection extends StatelessWidget {
  final String url;

  const UrlSection({super.key, required this.url});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildColoredUrl(Uri uri) {
    return SelectableText.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${uri.scheme}://',
            style: const TextStyle(
              color: Color(0xFFBB86FC),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
          TextSpan(
            text: uri.host,
            style: const TextStyle(
              color: Color(0xFF64B5F6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          if (uri.path.isNotEmpty)
            TextSpan(
              text: uri.path,
              style: const TextStyle(
                color: Color(0xFF81C784),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          if (uri.query.isNotEmpty)
            TextSpan(
              text: '?${uri.query}',
              style: const TextStyle(
                color: Color(0xFFFFB74D),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQueryParamsTable(Map<String, String> queryParams) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(2),
        },
        border: const TableBorder.symmetric(
          inside: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        children: [
          const TableRow(
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Key',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Value',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          ...queryParams.entries.map((entry) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return DetailSection(
        title: 'URL',
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Text(url),
          ),
        ],
      );
    }

    final queryParams = uri.queryParameters;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'URL',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_all_rounded, size: 20),
                  onPressed: () => _copyToClipboard(context, url, 'URL'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildColoredUrl(uri),
                ),
                if (queryParams.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Query Parameters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQueryParamsTable(queryParams),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// JSON ROW
// ========================================

class JsonRow extends StatelessWidget {
  final String label;
  final String jsonString;

  const JsonRow({
    super.key,
    required this.label,
    required this.jsonString,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayValue = jsonString;
    dynamic parsedJson;
    try {
      parsedJson = jsonDecode(jsonString);
      displayValue = const JsonEncoder.withIndent('  ').convert(parsedJson);
    } catch (e) {
      // Keep original if not valid JSON
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_all_rounded, size: 20),
                onPressed: () => _copyToClipboard(context, displayValue, label),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 400),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: parsedJson != null
                  ? JsonSyntaxHighlighter(json: parsedJson, indent: 0)
                  : SelectableText(
                      displayValue.isEmpty ? '(empty)' : displayValue,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94E2D5),
                        fontFamily: 'monospace',
                        height: 1.6,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// JSON SYNTAX HIGHLIGHTER
// ========================================

class JsonSyntaxHighlighter extends StatelessWidget {
  final dynamic json;
  final int indent;

  const JsonSyntaxHighlighter({
    super.key,
    required this.json,
    required this.indent,
  });

  List<InlineSpan> _buildJsonSpans(dynamic value, int level) {
    final List<InlineSpan> spans = [];
    final indentStr = '  ' * level;

    if (value is Map) {
      spans.add(const TextSpan(
        text: '{\n',
        style: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 13,
          fontFamily: 'monospace',
        ),
      ));

      final entries = value.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final isLast = i == entries.length - 1;

        spans.add(TextSpan(
          text: '  $indentStr',
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ));

        spans.add(TextSpan(
          text: '"${entry.key}"',
          style: const TextStyle(
            color: Color(0xFF8DD6FF),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ));

        spans.add(const TextSpan(
          text: ': ',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ));

        spans.addAll(_buildValueSpans(entry.value, level + 1));

        if (!isLast) {
          spans.add(const TextSpan(
            text: ',',
            style: TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ));
        }

        spans.add(const TextSpan(
          text: '\n',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ));
      }

      spans.add(TextSpan(
        text: '$indentStr}',
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 13,
          fontFamily: 'monospace',
        ),
      ));
    } else if (value is List) {
      spans.add(const TextSpan(
        text: '[\n',
        style: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 13,
          fontFamily: 'monospace',
        ),
      ));

      for (var i = 0; i < value.length; i++) {
        final isLast = i == value.length - 1;

        spans.add(TextSpan(
          text: '  $indentStr',
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ));

        spans.addAll(_buildValueSpans(value[i], level + 1));

        if (!isLast) {
          spans.add(const TextSpan(
            text: ',',
            style: TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ));
        }

        spans.add(const TextSpan(
          text: '\n',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ));
      }

      spans.add(TextSpan(
        text: '$indentStr]',
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 13,
          fontFamily: 'monospace',
        ),
      ));
    }

    return spans;
  }

  List<InlineSpan> _buildValueSpans(dynamic value, int level) {
    if (value is String) {
      return [
        TextSpan(
          text: '"$value"',
          style: const TextStyle(
            color: Color(0xFF98C379),
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
      ];
    } else if (value is num) {
      return [
        TextSpan(
          text: value.toString(),
          style: const TextStyle(
            color: Color(0xFFD19A66),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ];
    } else if (value is bool) {
      return [
        TextSpan(
          text: value.toString(),
          style: const TextStyle(
            color: Color(0xFFC678DD),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ];
    } else if (value == null) {
      return [
        const TextSpan(
          text: 'null',
          style: TextStyle(
            color: Color(0xFF56B6C2),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ];
    } else if (value is Map || value is List) {
      return _buildJsonSpans(value, level);
    }

    return [
      TextSpan(
        text: value.toString(),
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 13,
          fontFamily: 'monospace',
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        children: _buildJsonSpans(json, indent),
      ),
    );
  }
}
