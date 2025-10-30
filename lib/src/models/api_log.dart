class ApiLog {
  final int? id;
  final String url;
  final String method;
  final int statusCode;
  final int duration;
  final String timestamp;
  final String requestHeaders;
  final String requestBody;
  final String responseHeaders;
  final String responseBody;

  ApiLog({
    this.id,
    required this.url,
    required this.method,
    required this.statusCode,
    required this.duration,
    required this.timestamp,
    required this.requestHeaders,
    required this.requestBody,
    required this.responseHeaders,
    required this.responseBody,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'method': method,
      'statusCode': statusCode,
      'duration': duration,
      'timestamp': timestamp,
      'requestHeaders': requestHeaders,
      'requestBody': requestBody,
      'responseHeaders': responseHeaders,
      'responseBody': responseBody,
    };
  }

  factory ApiLog.fromMap(Map<String, dynamic> map) {
    return ApiLog(
      id: map['id'] as int?,
      url: map['url'] as String,
      method: map['method'] as String,
      statusCode: map['statusCode'] as int,
      duration: map['duration'] as int,
      timestamp: map['timestamp'] as String,
      requestHeaders: map['requestHeaders'] as String,
      requestBody: map['requestBody'] as String,
      responseHeaders: map['responseHeaders'] as String,
      responseBody: map['responseBody'] as String,
    );
  }

  ApiLog copyWith({
    int? id,
    String? url,
    String? method,
    int? statusCode,
    int? duration,
    String? timestamp,
    String? requestHeaders,
    String? requestBody,
    String? responseHeaders,
    String? responseBody,
  }) {
    return ApiLog(
      id: id ?? this.id,
      url: url ?? this.url,
      method: method ?? this.method,
      statusCode: statusCode ?? this.statusCode,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      requestHeaders: requestHeaders ?? this.requestHeaders,
      requestBody: requestBody ?? this.requestBody,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
    );
  }
}
