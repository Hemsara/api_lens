import 'package:api_lens/src/models/api_log.dart';
import 'package:flutter/material.dart';

import 'empty_state/empty_state.dart';
import 'filter_chip_widget.dart';
import 'log_card.dart';

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
