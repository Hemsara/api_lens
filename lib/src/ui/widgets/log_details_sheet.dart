import 'package:api_lens/src/models/api_log.dart';
import 'package:api_lens/src/ui/widgets/url_sectiom.widget.dart';
import 'package:flutter/material.dart';

import 'detail_section.dart';
import 'detailed_info_row.dart';
import 'json_row.dart';

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
