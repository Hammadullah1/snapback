import 'package:dio/dio.dart';

import '../config/env_config.dart';

class OpenAIRateLimit implements Exception {
  final String message;
  OpenAIRateLimit(this.message);
  @override
  String toString() => 'OpenAIRateLimit: $message';
}

class OpenAINetworkError implements Exception {
  final String message;
  OpenAINetworkError(this.message);
  @override
  String toString() => 'OpenAINetworkError: $message';
}

class OpenAIInvalidKey implements Exception {
  final String message;
  OpenAIInvalidKey(this.message);
  @override
  String toString() => 'OpenAIInvalidKey: $message';
}

class OpenAIClient {
  static final OpenAIClient _instance = OpenAIClient._internal();
  factory OpenAIClient() => _instance;

  late final Dio dio;

  OpenAIClient._internal() {
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Authorization': 'Bearer ${EnvConfig.openAiKey}',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onError: (e, handler) async {
        final status = e.response?.statusCode;
        // Retry once on 5xx
        if (status != null && status >= 500 && status < 600 && e.requestOptions.extra['retried'] != true) {
          e.requestOptions.extra['retried'] = true;
          try {
            final clone = await dio.fetch(e.requestOptions);
            return handler.resolve(clone);
          } catch (_) {
            // fall through to error mapping
          }
        }
        handler.next(e);
      },
    ));
  }

  Exception mapError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        return OpenAIInvalidKey('OpenAI auth failed ($status)');
      }
      if (status == 429) {
        return OpenAIRateLimit('OpenAI rate limit hit');
      }
      return OpenAINetworkError(e.message ?? 'Network error');
    }
    return OpenAINetworkError(e.toString());
  }
}
