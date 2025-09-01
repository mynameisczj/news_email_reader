import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/settings_service.dart';

class EmailSyncConfigSection extends ConsumerStatefulWidget {
  const EmailSyncConfigSection({super.key});

  @override
  ConsumerState<EmailSyncConfigSection> createState() => _EmailSyncConfigSectionState();
}

class _EmailSyncConfigSectionState extends ConsumerState<EmailSyncConfigSection> {
  final SettingsService _settingsService = SettingsService();
  
  bool _autoSyncEnabled = false;
  int _syncEmailCount = 0;
  int _syncTimeRangeDays = 0;
  int _syncIntervalMinutes = 0;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final autoSync = await _settingsService.getAutoSync();
    final emailCount = await _settingsService.getSyncQuantity();
    final timeRange = await _settingsService.getSyncTimeRange();
    final syncOnStartup = await _settingsService.getSyncOnStartup();
    
    setState(() {
      _autoSyncEnabled = autoSync;
      _syncEmailCount = emailCount;
      _syncTimeRangeDays = timeRange;
      _syncIntervalMinutes = syncOnStartup ? 0 : 60; // 简化处理
      _lastSyncTime = null; // 暂时不显示
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sync,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '邮件同步配置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 同步数量配置
            Text(
              '同步邮件数量',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildSyncCountOptions(),
            
            const SizedBox(height: 24),
            
            // 同步时间范围配置
            Text(
              '同步时间范围',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildSyncTimeRangeOptions(),
            
            const SizedBox(height: 24),
            
            // 自动同步设置
            SwitchListTile(
              title: const Text('启用自动同步'),
              subtitle: const Text('应用启动时自动同步邮件'),
              value: _autoSyncEnabled,
              onChanged: (value) async {
                await _settingsService.setAutoSync(value);
                setState(() {
                  _autoSyncEnabled = value;
                });
              },
            ),
            
            // 同步间隔设置
            if (_autoSyncEnabled) ...[
              const SizedBox(height: 16),
              Text(
                '自动同步间隔',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildSyncIntervalOptions(),
            ],
            
            const SizedBox(height: 24),
            
            // 同步状态显示
            _buildSyncStatus(),
          ],
        ),
      ),
    ));
  }

  Widget _buildSyncCountOptions() {
    final options = [
      {'value': 0, 'label': '全部邮件', 'description': '同步所有邮件'},
      {'value': 50, 'label': '最近50封', 'description': '同步最近50封邮件'},
      {'value': 100, 'label': '最近100封', 'description': '同步最近100封邮件'},
      {'value': 200, 'label': '最近200封', 'description': '同步最近200封邮件'},
      {'value': 500, 'label': '最近500封', 'description': '同步最近500封邮件'},
    ];

    return Column(
      children: options.map((option) {
        final value = option['value'] as int;
        final label = option['label'] as String;
        final description = option['description'] as String;
        
        return RadioListTile<int>(
          title: Text(label),
          subtitle: Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: value,
          groupValue: _syncEmailCount,
          onChanged: (value) async {
            if (value != null) {
              await _settingsService.setSyncQuantity(value);
              setState(() {
                _syncEmailCount = value;
              });
            }
          },
          dense: true,
        );
      }).toList(),
    );
  }

  Widget _buildSyncTimeRangeOptions() {
    final options = [
      {'value': 0, 'label': '全部时间', 'description': '同步所有时间的邮件'},
      {'value': 7, 'label': '最近一周', 'description': '同步最近7天的邮件'},
      {'value': 30, 'label': '最近一个月', 'description': '同步最近30天的邮件'},
      {'value': 90, 'label': '最近三个月', 'description': '同步最近90天的邮件'},
      {'value': 180, 'label': '最近半年', 'description': '同步最近180天的邮件'},
    ];

    return Column(
      children: options.map((option) {
        final value = option['value'] as int;
        final label = option['label'] as String;
        final description = option['description'] as String;
        
        return RadioListTile<int>(
          title: Text(label),
          subtitle: Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: value,
          groupValue: _syncTimeRangeDays,
          onChanged: (value) async {
            if (value != null) {
              await _settingsService.setSyncTimeRange(value);
              setState(() {
                _syncTimeRangeDays = value;
              });
            }
          },
          dense: true,
        );
      }).toList(),
    );
  }

  Widget _buildSyncIntervalOptions() {
    final options = [
      {'value': 0, 'label': '仅手动同步', 'description': '只在用户点击时同步'},
      {'value': 15, 'label': '15分钟', 'description': '每15分钟自动同步一次'},
      {'value': 30, 'label': '30分钟', 'description': '每30分钟自动同步一次'},
      {'value': 60, 'label': '1小时', 'description': '每小时自动同步一次'},
      {'value': 180, 'label': '3小时', 'description': '每3小时自动同步一次'},
      {'value': 360, 'label': '6小时', 'description': '每6小时自动同步一次'},
    ];

    return Column(
      children: options.map((option) {
        final value = option['value'] as int;
        final label = option['label'] as String;
        final description = option['description'] as String;
        
        return RadioListTile<int>(
          title: Text(label),
          subtitle: Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: value,
          groupValue: _syncIntervalMinutes,
          onChanged: (value) async {
            if (value != null) {
              await _settingsService.setSyncOnStartup(value == 0);
              setState(() {
                _syncIntervalMinutes = value;
              });
            }
          },
          dense: true,
        );
      }).toList(),
    );
  }

  Widget _buildSyncStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '当前同步配置',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getSyncConfigSummary(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_lastSyncTime != null) ...[
            const SizedBox(height: 4),
            Text(
              '上次同步: ${_formatDateTime(_lastSyncTime!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getSyncConfigSummary() {
    final countText = _syncEmailCount == 0 
        ? '全部邮件' 
        : '最近${_syncEmailCount}封邮件';
    
    final timeText = _syncTimeRangeDays == 0 
        ? '全部时间' 
        : '最近${_syncTimeRangeDays}天';
    
    final autoText = _autoSyncEnabled 
        ? (_syncIntervalMinutes == 0 
            ? '仅启动时自动同步' 
            : '每${_syncIntervalMinutes}分钟自动同步')
        : '仅手动同步';
    
    return '同步范围: $countText ($timeText)\n同步方式: $autoText';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}