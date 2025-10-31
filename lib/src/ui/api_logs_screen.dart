import 'package:api_lens/src/models/api_log.dart';
import 'package:api_lens/src/services/api_logger_service.dart';
import 'package:api_lens/src/ui/widgets/logs_tab_widget.dart';
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
            color: Colors.white,
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
