import 'package:dio/dio.dart';
import 'package:festisquad/core/network/api_client.dart';
import 'package:festisquad/core/network/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RetryPolicy', () {
    test('reintenta errores transitorios con backoff y luego responde',
        () async {
      var attempts = 0;
      final delays = <Duration>[];
      const policy = RetryPolicy(
        maxRetries: 2,
        initialDelay: Duration(milliseconds: 100),
      );

      final result = await policy.execute(
        () async {
          attempts++;
          if (attempts < 3) throw StateError('sin red');
          return 'ok';
        },
        shouldRetry: (_) => true,
        delay: (duration) async => delays.add(duration),
      );

      expect(result, 'ok');
      expect(attempts, 3);
      expect(delays, const [
        Duration(milliseconds: 100),
        Duration(milliseconds: 200),
      ]);
    });

    test('no reintenta errores permanentes', () async {
      var attempts = 0;

      await expectLater(
        const RetryPolicy().execute<void>(
          () async {
            attempts++;
            throw ArgumentError('dato inválido');
          },
          shouldRetry: (_) => false,
          delay: (_) async {},
        ),
        throwsArgumentError,
      );
      expect(attempts, 1);
    });
  });

  group('transporte seguro', () {
    test('release rechaza API sin HTTPS', () {
      expect(
        () => validateApiBaseUrl(
          'http://api.festisquad.example/api/v1',
          isRelease: true,
        ),
        throwsStateError,
      );
    });

    test('desarrollo local permite HTTP y release acepta HTTPS', () {
      expect(
        validateApiBaseUrl('http://127.0.0.1:8000/api/v1', isRelease: false),
        startsWith('http://'),
      );
      expect(
        validateApiBaseUrl(
          'https://api.festisquad.example/api/v1',
          isRelease: true,
        ),
        startsWith('https://'),
      );
    });

    test('errores Dio conservan mensajes de red comprensibles', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/health'),
        type: DioExceptionType.connectionError,
      );

      expect(apiErrorMessage(error), contains('Revisa la red'));
    });
  });
}
