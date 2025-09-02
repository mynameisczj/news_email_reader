import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:crypto/crypto.dart';

enum TranslationProvider {
  tencent('腾讯翻译'),
  libre('LibreTranslate'),
  suapi('SuApi'),
  custom('自定义');

  const TranslationProvider(this.displayName);
  final String displayName;
}

class TranslationService {
  // 当未配置腾讯云密钥时，使用LibreTranslate公共实例
  String _libreBaseUrl = 'https://libretranslate.de';
  String? _libreApiKey;

  // 当前使用的翻译服务提供商
  TranslationProvider _provider = TranslationProvider.suapi;
  String? _customApiUrl;

  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio();
    
    // 配置超时时间
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 15);
    
    // 配置SSL和证书验证
    if (!kIsWeb) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();

        // 配置SSL上下文
        client.badCertificateCallback = (cert, host, port) {
          // 对于LibreTranslate等服务，允许连接
          return host.contains('libretranslate') ||
              host.contains('translate') ||
              host.contains('argosopentech') ||
              host.contains('suapi.net') || // 允许SuApi
              host == 'libretranslate.de' ||
              host == 'libretranslate.com';
        };

        // 设置连接超时
        client.connectionTimeout = const Duration(seconds: 15);
        client.idleTimeout = const Duration(seconds: 15);

        return client;
      };
    }
    
    // 添加重试拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout) {
            // 超时重试一次
            try {
              final response = await _dio.request(
                error.requestOptions.path,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
                options: Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                ),
              );
              handler.resolve(response);
              return;
            } catch (e) {
              // 重试失败，继续抛出原错误
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  
  // 腾讯云翻译API配置
  static const String _baseUrl = 'https://tmt.tencentcloudapi.com';
  static const String _service = 'tmt';
  static const String _version = '2018-03-21';
  static const String _action = 'TextTranslate';
  static const String _region = 'ap-beijing';
  
  String? _secretId;
  String? _secretKey;

  /// 初始化翻译服务
  void initialize({required String secretId, required String secretKey}) {
    _secretId = secretId;
    _secretKey = secretKey;
  }

  /// 设置翻译服务提供商
  void setTranslationProvider(TranslationProvider provider, {String? customApiUrl}) {
    _provider = provider;
    _customApiUrl = customApiUrl;
    // TODO: 将设置持久化
  }

  /// 翻译文本
  Future<String> translateText({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    switch (_provider) {
      case TranslationProvider.tencent:
        if (isConfigured()) {
          return await _translateTextTencent(
            text: text,
            targetLanguage: targetLanguage,
            sourceLanguage: sourceLanguage,
          );
        }
        debugPrint('腾讯翻译未配置，回退到SuApi');
        return await _translateTextSuApi(
          text: text,
          targetLanguage: targetLanguage,
          sourceLanguage: sourceLanguage,
        );
      case TranslationProvider.libre:
        return await _translateTextLibre(
          text: text,
          targetLanguage: targetLanguage,
          sourceLanguage: sourceLanguage,
        );
      case TranslationProvider.suapi:
        return await _translateTextSuApi(
          text: text,
          targetLanguage: targetLanguage,
          sourceLanguage: sourceLanguage,
        );
      case TranslationProvider.custom:
        if (_customApiUrl != null && _customApiUrl!.isNotEmpty) {
          return await _translateTextSuApi(
            text: text,
            targetLanguage: targetLanguage,
            sourceLanguage: sourceLanguage,
            baseUrl: _customApiUrl,
          );
        }
        debugPrint('自定义翻译API未配置，回退到SuApi');
        return await _translateTextSuApi(
          text: text,
          targetLanguage: targetLanguage,
          sourceLanguage: sourceLanguage,
        );
    }
  }

  Future<String> _translateTextTencent({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final headers = _generateHeaders(text, targetLanguage, sourceLanguage, timestamp);
      final response = await _dio.post(
        _baseUrl,
        data: {
          'Action': _action,
          'Version': _version,
          'Region': _region,
          'SourceText': text,
          'Source': sourceLanguage,
          'Target': targetLanguage,
          'ProjectId': 0,
        },
        options: Options(
          headers: headers,
          contentType: 'application/json',
        ),
      );

      if (response.statusCode == 200) {
        final result = response.data;
        if (result['Response']['Error'] != null) {
          throw Exception('翻译失败: ${result['Response']['Error']['Message']}');
        }
        return result['Response']['TargetText'] ?? text;
      } else {
        throw Exception('翻译请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('翻译服务错误: $e');
    }
  }

  /// 批量翻译
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    if (texts.isEmpty) {
      return [];
    }

    // SuApi 和 自定义Api 支持批量翻译
    if (_provider == TranslationProvider.suapi ||
        (_provider == TranslationProvider.custom &&
            _customApiUrl != null &&
            _customApiUrl!.isNotEmpty)) {
      return await _translateBatchSuApi(
        texts: texts,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
        baseUrl: _provider == TranslationProvider.custom ? _customApiUrl : null,
      );
    }

    // 其他翻译服务，循环调用单次翻译
    final results = <String>[];
    for (final text in texts) {
      try {
        final translated = await translateText(
          text: text,
          targetLanguage: targetLanguage,
          sourceLanguage: sourceLanguage,
        );
        results.add(translated);
      } catch (e) {
        debugPrint('批量翻译中，单条翻译失败: $e');
        results.add(text); // 如果翻译失败，返回原文
      }
    }
    return results;
  }

  /// 翻译邮件内容
  Future<Map<String, String>> translateEmail({
    required String subject,
    required String content,
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    try {
      if (subject.trim().isEmpty && content.trim().isEmpty) {
        return {'subject': subject, 'content': content};
      }
      final textsToTranslate = [subject, content];
      final translated = await translateBatch(
        texts: textsToTranslate,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
      );
      return {'subject': translated[0], 'content': translated[1]};
    } catch (e) {
      throw Exception('邮件翻译失败: $e');
    }
  }

  // ========== SuApi Translation =========
  Future<String> _translateTextSuApi({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
    String? baseUrl,
  }) async {
    final results = await _translateBatchSuApi(
      texts: [text],
      targetLanguage: targetLanguage,
      sourceLanguage: sourceLanguage,
      baseUrl: baseUrl,
    );
    return results.isNotEmpty ? results.first : text;
  }

  Future<List<String>> _translateBatchSuApi({
    required List<String> texts,
    required String targetLanguage,
    String sourceLanguage = 'auto',
    String? baseUrl,
  }) async {
    final apiUrl = baseUrl ?? 'https://suapi.net/api/text/translate';
    debugPrint('使用SuApi翻译: $apiUrl');

    try {
      final response = await _dio.get(
        apiUrl,
        queryParameters: {
          'to': targetLanguage,
          'text[]': texts,
        },
        options: Options(
          contentType: 'application/json',
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final result = response.data;
        if (result is Map && result['code'] == 200 && result['data'] is List) {
          final dataList = result['data'] as List;
          final translatedTexts = <String>[];

          for (int i = 0; i < dataList.length; i++) {
            final item = dataList[i];
            if (item['translations'] is List &&
                (item['translations'] as List).isNotEmpty) {
              translatedTexts.add(item['translations'][0]['text'] ?? texts[i]);
            } else {
              translatedTexts.add(texts[i]);
            }
          }

          if (translatedTexts.length == texts.length) {
            return translatedTexts;
          }
        }
        if (result is Map && result['msg'] != null) {
          throw Exception('翻译失败: ${result['msg']}');
        }
      }
      throw Exception('翻译请求失败: ${response.statusCode}, ${response.data}');
    } catch (e) {
      debugPrint('SuApi翻译服务错误: $e');
      return texts;
    }
  }

  /// 检测语言
  Future<String> detectLanguage(String text) async {
    // 未配置腾讯云时，使用LibreTranslate检测
    if (!isConfigured()) {
      return await _detectLanguageLibre(text);
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final headers = _generateDetectionHeaders(text, timestamp);
      final response = await _dio.post(
        _baseUrl,
        data: {
          'Action': 'LanguageDetect',
          'Version': _version,
          'Region': _region,
          'Text': text,
        },
        options: Options(
          headers: headers,
          contentType: 'application/json',
        ),
      );

      if (response.statusCode == 200) {
        final result = response.data;
        if (result['Response']['Error'] != null) {
          throw Exception('语言检测失败: ${result['Response']['Error']['Message']}');
        }
        return result['Response']['Lang'] ?? 'auto';
      } else {
        throw Exception('语言检测请求失败: ${response.statusCode}');
      }
    } catch (e) {
      return 'auto';
    }
  }

  /// 获取支持的语言列表
  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'zh', 'name': '中文'},
      {'code': 'en', 'name': 'English'},
      {'code': 'ja', 'name': '日本語'},
      {'code': 'ko', 'name': '한국어'},
      {'code': 'es', 'name': 'Español'},
      {'code': 'fr', 'name': 'Français'},
      {'code': 'de', 'name': 'Deutsch'},
      {'code': 'it', 'name': 'Italiano'},
      {'code': 'ru', 'name': 'Русский'},
      {'code': 'pt', 'name': 'Português'},
      {'code': 'ar', 'name': 'العربية'},
      {'code': 'th', 'name': 'ไทย'},
      {'code': 'vi', 'name': 'Tiếng Việt'},
      {'code': 'ms', 'name': 'Bahasa Melayu'},
      {'code': 'hi', 'name': 'हिन्दी'},
    ];
  }

  /// 生成翻译请求头
  Map<String, String> _generateHeaders(
    String text,
    String targetLanguage,
    String sourceLanguage,
    int timestamp,
  ) {
    final payload = jsonEncode({
      'Action': _action,
      'Version': _version,
      'Region': _region,
      'SourceText': text,
      'Source': sourceLanguage,
      'Target': targetLanguage,
      'ProjectId': 0,
    });

    return _generateCommonHeaders(payload, timestamp, _action);
  }

  /// 生成语言检测请求头
  Map<String, String> _generateDetectionHeaders(String text, int timestamp) {
    final payload = jsonEncode({
      'Action': 'LanguageDetect',
      'Version': _version,
      'Region': _region,
      'Text': text,
    });

    return _generateCommonHeaders(payload, timestamp, 'LanguageDetect');
  }

  /// 生成通用请求头
  Map<String, String> _generateCommonHeaders(
      String payload, int timestamp, String action) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toUtc();
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    // 生成签名
    final canonicalRequest = _buildCanonicalRequest(payload);
    final stringToSign = _buildStringToSign(canonicalRequest, timestamp, dateString);
    final signature = _calculateSignature(stringToSign, dateString);
    
    final authorization = 'TC3-HMAC-SHA256 '
        'Credential=$_secretId/$dateString/$_service/tc3_request, '
        'SignedHeaders=content-type;host, '
        'Signature=$signature';

    return {
      'Authorization': authorization,
      'Content-Type': 'application/json',
      'Host': 'tmt.tencentcloudapi.com',
      'X-TC-Action': action,
      'X-TC-Timestamp': timestamp.toString(),
      'X-TC-Version': _version,
      'X-TC-Region': _region,
    };
  }

  /// 构建规范请求
  String _buildCanonicalRequest(String payload) {
    final hashedPayload = sha256.convert(utf8.encode(payload)).toString();
    
    return 'POST\n'
        '/\n'
        '\n'
        'content-type:application/json\n'
        'host:tmt.tencentcloudapi.com\n'
        '\n'
        'content-type;host\n'
        '$hashedPayload';
  }

  /// 构建签名字符串
  String _buildStringToSign(String canonicalRequest, int timestamp, String dateString) {
    final hashedCanonicalRequest = sha256.convert(utf8.encode(canonicalRequest)).toString();
    final credentialScope = '$dateString/$_service/tc3_request';
    
    return 'TC3-HMAC-SHA256\n'
        '$timestamp\n'
        '$credentialScope\n'
        '$hashedCanonicalRequest';
  }

  /// 计算签名
  String _calculateSignature(String stringToSign, String dateString) {
    final kDate = _hmacSha256(utf8.encode('TC3$_secretKey'), utf8.encode(dateString));
    final kService = _hmacSha256(kDate, utf8.encode(_service));
    final kSigning = _hmacSha256(kService, utf8.encode('tc3_request'));
    final signature = _hmacSha256(kSigning, utf8.encode(stringToSign));
    
    return signature.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// HMAC-SHA256计算
  List<int> _hmacSha256(List<int> key, List<int> data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(data).bytes;
  }

  /// 获取常用翻译语言对
  List<Map<String, String>> getCommonLanguagePairs() {
    return [
      {'source': 'auto', 'target': 'zh', 'name': '自动检测 → 中文'},
      {'source': 'en', 'target': 'zh', 'name': 'English → 中文'},
      {'source': 'zh', 'target': 'en', 'name': '中文 → English'},
      {'source': 'ja', 'target': 'zh', 'name': '日本語 → 中文'},
      {'source': 'ko', 'target': 'zh', 'name': '한국어 → 中文'},
      {'source': 'auto', 'target': 'en', 'name': '自动检测 → English'},
    ];
  }

  /// 检查API配置是否有效
  bool isConfigured() {
    return _secretId != null && _secretKey != null &&
           _secretId!.isNotEmpty && _secretKey!.isNotEmpty;
  }

  // ========== LibreTranslate Fallback ==========
  Future<String> _translateTextLibre({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    // 使用更稳定的翻译服务实例
    final fallbackUrls = [
      'https://translate.argosopentech.com',  // 更稳定的服务
      'https://libretranslate.de',
      'https://libretranslate.com',
    ];
    
    Exception? lastException;
    
    for (final baseUrl in fallbackUrls) {
      try {
        debugPrint('尝试翻译服务: $baseUrl');
        
        final response = await _dio.post(
          '$baseUrl/translate',
          data: {
            'q': text.length > 1000 ? text.substring(0, 1000) : text, // 限制文本长度
            'source': sourceLanguage == 'auto' ? 'en' : sourceLanguage, // 避免auto检测问题
            'target': targetLanguage,
            'format': 'text',
            if (_libreApiKey != null && _libreApiKey!.isNotEmpty) 'api_key': _libreApiKey,
          },
          options: Options(
            contentType: 'application/json',
            validateStatus: (status) => status != null && status < 500,
            headers: {
              'User-Agent': 'NewsEmailReader/0.6.1',
            },
          ),
        );
        
        if (response.statusCode == 200) {
          final data = response.data;
          final translated = data['translatedText'] ?? '';
          debugPrint('翻译成功: ${translated.length} 字符');
          return translated.isNotEmpty ? translated : text;
        } else if (response.statusCode == 429) {
          debugPrint('服务 $baseUrl 速率限制，尝试下一个');
          await Future.delayed(const Duration(seconds: 1)); // 短暂延迟
          continue;
        } else {
          throw DioException.badResponse(
            statusCode: response.statusCode ?? 500,
            requestOptions: response.requestOptions,
            response: response,
          );
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception('翻译服务错误: $e');
        debugPrint('LibreTranslate服务 $baseUrl 失败: $e');
        
        // 如果是网络连接问题，尝试下一个服务
        if (e is DioException) {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.message?.contains('HandshakeException') == true ||
              e.message?.contains('Connection terminated') == true) {
            debugPrint('网络连接问题，尝试下一个服务');
            continue;
          }
        }
        
        // 其他错误也尝试下一个服务
        continue;
      }
    }
    
    // 所有服务都失败了
    throw lastException ?? Exception('所有翻译服务都不可用，请检查网络连接');
  }

  Future<String> _detectLanguageLibre(String text) async {
    final fallbackUrls = [
      'https://translate.argosopentech.com',
      'https://libretranslate.de',
      'https://libretranslate.com',
    ];

    for (final baseUrl in fallbackUrls) {
      try {
        final response = await _dio.post(
          '$baseUrl/detect',
          data: {
            'q': text.length > 500 ? text.substring(0, 500) : text
          }, // 限制长度
          options: Options(contentType: 'application/json'),
        );
        if (response.statusCode == 200) {
          final res = response.data;
          if (res is List && res.isNotEmpty) {
            final first = res.first;
            final lang = first['language'] as String?;
            if (lang != null && lang.isNotEmpty) {
              return lang;
            }
          }
        }
      } catch (e) {
        debugPrint('LibreTranslate language detect $baseUrl 失败: $e');
        continue; // 尝试下一个
      }
    }
    return 'auto'; // 所有服务失败后返回 'auto'
  }

  /// 清除API配置
  void clearConfiguration() {
    _secretId = null;
    _secretKey = null;
  }
}