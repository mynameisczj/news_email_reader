import 'package:dio/dio.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final Dio _dio = Dio();
  
  // API配置
  static const String _baseUrl = 'https://api.suanli.cn/v1';
  static const String _apiKey = 'sk-W0rpStc95T7JVYVwDYc29IyirjtpPPby6SozFMQr17m8KWeo';
  static const String _model = 'free:QwQ-32B';

  /// 生成邮件总结
  Future<String> generateSummary(String subject, String content) async {
    try {
      final prompt = _buildSummaryPrompt(subject, content);
      
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
        data: {
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        String summary = data['choices'][0]['message']['content'];
        
        // 去掉思考标签内的内容
        summary = _removeThinkingTags(summary);
        
        return summary.trim();
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      print('AI总结生成失败: $e');
      throw Exception('生成总结失败，请检查网络连接');
    }
  }

  /// 批量生成邮件总结
  Future<List<String>> generateBatchSummary(List<Map<String, String>> emails) async {
    final summaries = <String>[];
    
    for (final email in emails) {
      try {
        final summary = await generateSummary(
          email['subject'] ?? '',
          email['content'] ?? '',
        );
        summaries.add(summary);
      } catch (e) {
        summaries.add('总结生成失败');
      }
    }
    
    return summaries;
  }

  /// 生成今日邮件汇总
  Future<String> generateDailySummary(List<Map<String, String>> todayEmails) async {
    try {
      final prompt = _buildDailySummaryPrompt(todayEmails);
      
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
        data: {
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 800,
          'temperature': 0.7,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final summary = data['choices'][0]['message']['content'];
        return summary.trim();
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      print('每日汇总生成失败: $e');
      throw Exception('生成每日汇总失败，请检查网络连接');
    }
  }

  /// 翻译邮件内容
  Future<String> translateContent(String content, String targetLanguage) async {
    try {
      final prompt = _buildTranslationPrompt(content, targetLanguage);
      
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
        data: {
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 1000,
          'temperature': 0.3,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final translation = data['choices'][0]['message']['content'];
        return translation.trim();
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      print('翻译失败: $e');
      throw Exception('翻译失败，请检查网络连接');
    }
  }

  /// 构建总结提示词
  String _buildSummaryPrompt(String subject, String content) {
    return '''
请为以下邮件生成一个简洁的中文总结，重点突出关键信息和要点：

邮件主题：$subject

邮件内容：
$content

要求：
1. 总结长度控制在100-200字
2. 突出重要信息和关键点
3. 使用简洁明了的中文表达
4. 如果是新闻类邮件，重点提取新闻要点
5. 如果是技术类邮件，重点提取技术要点

请直接输出总结内容，不要包含其他说明文字。
''';
  }

  /// 构建每日汇总提示词
  String _buildDailySummaryPrompt(List<Map<String, String>> emails) {
    final emailList = emails.map((email) {
      return '标题：${email['subject']}\n内容摘要：${email['content']?.substring(0, 200) ?? ''}...';
    }).join('\n\n');

    return '''
请为今天收到的以下邮件生成一个综合汇总报告：

今日邮件列表：
$emailList

要求：
1. 按主题分类整理邮件内容
2. 突出重要新闻和信息
3. 提供简洁的总体概述
4. 标注需要关注的重点内容
5. 汇总长度控制在300-500字

请生成结构化的每日邮件汇总报告。
''';
  }

  /// 构建翻译提示词
  String _buildTranslationPrompt(String content, String targetLanguage) {
    final languageMap = {
      'zh': '中文',
      'en': '英文',
      'ja': '日文',
      'ko': '韩文',
      'fr': '法文',
      'de': '德文',
      'es': '西班牙文',
      'ru': '俄文',
    };

    final targetLangName = languageMap[targetLanguage] ?? '中文';

    return '''
请将以下内容翻译成$targetLangName，保持原文的格式和结构：

$content

要求：
1. 准确翻译内容含义
2. 保持原文的段落结构
3. 专业术语要准确翻译
4. 语言表达要自然流畅

请直接输出翻译结果，不要包含其他说明文字。
''';
  }

  /// 测试API连接
  Future<bool> testConnection() async {
    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
        data: {
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': '测试连接',
            }
          ],
          'max_tokens': 10,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('API连接测试失败: $e');
      return false;
    }
  }

  /// 去掉思考标签内的内容
  String _removeThinkingTags(String text) {
    // 移除 <thinking>...</thinking> 标签及其内容
    final thinkingRegex = RegExp(r'<thinking>.*?</thinking>', dotAll: true);
    text = text.replaceAll(thinkingRegex, '');
    
    // 移除 <think>...</think> 标签及其内容
    final thinkRegex = RegExp(r'<think>.*?</think>', dotAll: true);
    text = text.replaceAll(thinkRegex, '');
    
    // 清理多余的空白字符
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return text;
  }
}
