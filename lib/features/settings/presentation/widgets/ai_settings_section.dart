import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/constants/app_constants.dart';

class AISettingsSection extends ConsumerStatefulWidget {
  const AISettingsSection({super.key});

  @override
  ConsumerState<AISettingsSection> createState() => _AISettingsSectionState();
}

class _AISettingsSectionState extends ConsumerState<AISettingsSection> {
  final AIService _aiService = AIService();
  
  String _selectedProvider = 'suanli';
  String _apiKey = '';
  String _baseUrl = 'https://api.suanli.cn/v1';
  String _model = 'free:QwQ-32B';
  bool _isTestingConnection = false;
  bool _connectionStatus = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: 从本地存储加载设置
    setState(() {
      _apiKey = 'sk-W0rpStc95T7JVYVwDYc29IyirjtpPPby6SozFMQr17m8KWeo';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProviderSection(),
        const SizedBox(height: 24),
        _buildConfigurationSection(),
        const SizedBox(height: 24),
        _buildTestSection(),
        const SizedBox(height: 24),
        _buildUsageSection(),
      ],
    );
  }

  Widget _buildProviderSection() {
    return _buildSettingsGroup(
      title: 'AI服务提供商',
      children: [
        _buildProviderTile(
          'suanli',
          '算力云',
          '免费的AI服务，支持多种模型',
          Icons.cloud,
        ),
        _buildProviderTile(
          'openai',
          'OpenAI',
          '官方GPT服务，需要API密钥',
          Icons.psychology,
        ),
        _buildProviderTile(
          'custom',
          '自定义API',
          '使用自定义的AI服务接口',
          Icons.settings_applications,
        ),
      ],
    );
  }

  Widget _buildProviderTile(String value, String title, String subtitle, IconData icon) {
    final isSelected = _selectedProvider == value;
    
    return Card(
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            color: isSelected ? AppTheme.primaryColor : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Radio<String>(
          value: value,
          groupValue: _selectedProvider,
          onChanged: (value) {
            setState(() {
              _selectedProvider = value!;
              _updateProviderConfig();
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
        onTap: () {
          setState(() {
            _selectedProvider = value;
            _updateProviderConfig();
          });
        },
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return _buildSettingsGroup(
      title: 'API配置',
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'API密钥',
                  hintText: '输入您的API密钥',
                  prefixIcon: Icon(Icons.key),
                ),
                obscureText: true,
                onChanged: (value) {
                  _apiKey = value;
                },
                controller: TextEditingController(text: _apiKey),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: '基础URL',
                  hintText: 'https://api.example.com/v1',
                  prefixIcon: Icon(Icons.link),
                ),
                onChanged: (value) {
                  _baseUrl = value;
                },
                controller: TextEditingController(text: _baseUrl),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: '模型名称',
                  hintText: 'gpt-3.5-turbo',
                  prefixIcon: Icon(Icons.memory),
                ),
                onChanged: (value) {
                  _model = value;
                },
                controller: TextEditingController(text: _model),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestSection() {
    return _buildSettingsGroup(
      title: '连接测试',
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _connectionStatus ? Icons.check_circle : Icons.error,
                    color: _connectionStatus ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _connectionStatus ? 'API连接正常' : '未测试或连接失败',
                    style: TextStyle(
                      color: _connectionStatus ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isTestingConnection ? null : _testConnection,
                  icon: _isTestingConnection
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: Text(_isTestingConnection ? '测试中...' : '测试连接'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsageSection() {
    return _buildSettingsGroup(
      title: '使用设置',
      children: [
        SwitchListTile(
          title: const Text('自动生成总结'),
          subtitle: const Text('阅读邮件时自动生成AI总结'),
          value: true,
          onChanged: (value) {
            // TODO: 保存设置
          },
          activeColor: AppTheme.primaryColor,
        ),
        SwitchListTile(
          title: const Text('批量总结'),
          subtitle: const Text('支持一次性总结多封邮件'),
          value: true,
          onChanged: (value) {
            // TODO: 保存设置
          },
          activeColor: AppTheme.primaryColor,
        ),
        ListTile(
          title: const Text('总结长度'),
          subtitle: const Text('控制AI总结的详细程度'),
          trailing: DropdownButton<String>(
            value: '中等',
            items: const [
              DropdownMenuItem(value: '简短', child: Text('简短')),
              DropdownMenuItem(value: '中等', child: Text('中等')),
              DropdownMenuItem(value: '详细', child: Text('详细')),
            ],
            onChanged: (value) {
              // TODO: 保存设置
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  void _updateProviderConfig() {
    switch (_selectedProvider) {
      case 'suanli':
        _baseUrl = 'https://api.suanli.cn/v1';
        _model = 'free:QwQ-32B';
        _apiKey = 'sk-W0rpStc95T7JVYVwDYc29IyirjtpPPby6SozFMQr17m8KWeo';
        break;
      case 'openai':
        _baseUrl = 'https://api.openai.com/v1';
        _model = 'gpt-3.5-turbo';
        _apiKey = '';
        break;
      case 'custom':
        _baseUrl = '';
        _model = '';
        _apiKey = '';
        break;
    }
    setState(() {});
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
    });

    try {
      final success = await _aiService.testConnection();
      setState(() {
        _connectionStatus = success;
        _isTestingConnection = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'API连接成功' : 'API连接失败'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _connectionStatus = false;
        _isTestingConnection = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接测试失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}