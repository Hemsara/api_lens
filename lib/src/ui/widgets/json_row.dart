import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
