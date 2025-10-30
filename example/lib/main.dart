import 'package:api_lens/api_lens.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiLens.init(
    config: ApiLoggerConfig(
      enabled: true,
      showDebugButton: true,
      buttonPosition: FloatingButtonPosition.topLeft, // 🔝 Top right
      buttonSize: 10.0, // Bigger
      maxLogs: 500, // Keep more logs
      autoDeleteAfterDays: 30, // Delete after 30 days
      showConsoleLogs: true, // Print to console
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Widget app = ApiLensOverlay(
      child: MaterialApp(
        title: 'ApiLens Example',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const HomePage(),
      ),
    );

    return app;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiLensHttpClient _httpClient = ApiLensHttpClient();
  final Dio _dio = Dio()..interceptors.add(ApiLensDioInterceptor());

  bool _isLoading = false;
  String _lastResult = '';

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ApiLens Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'View API Logs',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ApiLogsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'Test API Requests',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Make test requests and view them in the API Logs viewer',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // HTTP Package Tests
            _buildSection('Using http package', [
              _buildRequestButton(
                'GET Users',
                Icons.download_rounded,
                Colors.blue,
                () => _makeHttpGetRequest(),
              ),
              _buildRequestButton(
                'POST User',
                Icons.add_circle_outline,
                Colors.green,
                () => _makeHttpPostRequest(),
              ),
              _buildRequestButton(
                'Failed Request',
                Icons.error_outline,
                Colors.red,
                () => _makeFailedRequest(),
              ),
            ]),

            const SizedBox(height: 24),

            // Dio Package Tests
            _buildSection('Using dio package', [
              _buildRequestButton(
                'GET Posts',
                Icons.article_outlined,
                Colors.purple,
                () => _makeDioGetRequest(),
              ),
              _buildRequestButton(
                'POST with Query Params',
                Icons.question_mark_rounded,
                Colors.orange,
                () => _makeDioRequestWithParams(),
              ),
              _buildRequestButton(
                'Large JSON Response',
                Icons.data_object_rounded,
                Colors.teal,
                () => _makeLargeJsonRequest(),
              ),
            ]),

            const SizedBox(height: 24),

            // Loading Indicator
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),

            // Last Result
            if (_lastResult.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Last Result:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _lastResult,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // View Logs Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApiLogsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.analytics),
              label: const Text('View API Logs'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildRequestButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Future<void> _makeHttpGetRequest() async {
    setState(() {
      _isLoading = true;
      _lastResult = '';
    });

    try {
      final response = await _httpClient.get(
        Uri.parse('https://jsonplaceholder.typicode.com/users'),
      );
      setState(() {
        _lastResult =
            'Success! Status: ${response.statusCode}\n'
            'Got ${response.body.length} characters';
      });
    } catch (e) {
      setState(() => _lastResult = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeHttpPostRequest() async {
    setState(() {
      _isLoading = true;
      _lastResult = '';
    });

    try {
      final response = await _httpClient.post(
        Uri.parse('https://jsonplaceholder.typicode.com/users'),
        headers: {'Content-Type': 'application/json'},
        body: '{"name": "John Doe", "email": "john@example.com"}',
      );
      setState(() {
        _lastResult =
            'Success! Status: ${response.statusCode}\n'
            'Response: ${response.body}';
      });
    } catch (e) {
      setState(() => _lastResult = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeFailedRequest() async {
    setState(() {
      _isLoading = true;
      _lastResult = '';
    });

    try {
      await _httpClient.get(
        Uri.parse('https://jsonplaceholder.typicode.com/nonexistent'),
      );
    } catch (e) {
      setState(() => _lastResult = 'Expected error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeDioGetRequest() async {
    setState(() {
      _isLoading = true;
      _lastResult = '';
    });

    try {
      final response = await _dio.get(
        'https://jsonplaceholder.typicode.com/posts',
      );
      setState(() {
        _lastResult =
            'Success! Status: ${response.statusCode}\n'
            'Got ${response.data.length} posts';
      });
    } catch (e) {
      setState(() => _lastResult = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeDioRequestWithParams() async {
    setState(() {
      _isLoading = true;
      _lastResult = '';
    });

    try {
      final response = await _dio.get(
        'https://jsonplaceholder.typicode.com/posts',
        queryParameters: {'userId': 1, 'page': 2, 'limit': 10, 'sort': 'desc'},
      );
      setState(() {
        _lastResult =
            'Success! Status: ${response.statusCode}\n'
            'Check the logs to see query parameters!';
      });
    } catch (e) {
      setState(() => _lastResult = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeLargeJsonRequest() async {
    setState(() {
      _isLoading = true;
      _lastResult = '';
    });

    try {
      final response = await _dio.get(
        'https://jsonplaceholder.typicode.com/comments',
      );
      setState(() {
        _lastResult =
            'Success! Status: ${response.statusCode}\n'
            'Got large JSON response with ${response.data.length} items\n'
            'Check syntax highlighting in logs!';
      });
    } catch (e) {
      setState(() => _lastResult = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
