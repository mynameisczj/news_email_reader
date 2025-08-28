import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final Dio _dio = Dio();
  
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

  /// 翻译文本
  Future<String> translateText({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    if (_secretId == null || _secretKey == null) {
      throw Exception('翻译服务未初始化，请先配置API密钥');
    }

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
        // 如果翻译失败，返回原文
        results.add(text);
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
      final translatedSubject = await translateText(
        text: subject,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
      );
      
      final translatedContent = await translateText(
        text: content,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
      );
      
      return {
        'subject': translatedSubject,
        'content': translatedContent,
      };
    } catch (e) {
      throw Exception('邮件翻译失败: $e');
    }
  }

  /// 检测语言
  Future<String> detectLanguage(String text) async {
    if (_secretId == null || _secretKey == null) {
      throw Exception('翻译服务未初始化，请先配置API密钥');
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
      // 如果检测失败，返回auto
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

    return _generateCommonHeaders(payload, timestamp);
  }

  /// 生成语言检测请求头
  Map<String, String> _generateDetectionHeaders(String text, int timestamp) {
    final payload = jsonEncode({
      'Action': 'LanguageDetect',
      'Version': _version,
      'Region': _region,
      'Text': text,
    });

    return _generateCommonHeaders(payload, timestamp);
  }

  /// 生成通用请求头
  Map<String, String> _generateCommonHeaders(String payload, int timestamp) {
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
      'X-TC-Action': _action,
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

  /// 清除API配置
  void clearConfiguration() {
    _secretId = null;
    _secretKey = null;
  }
}