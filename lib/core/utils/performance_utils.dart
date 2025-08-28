import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class PerformanceUtils {
  static final PerformanceUtils _instance = PerformanceUtils._internal();
  factory PerformanceUtils() => _instance;
  PerformanceUtils._internal();

  final Map<String, DateTime> _timers = {};
  final List<PerformanceMetric> _metrics = [];

  /// 开始性能计时
  void startTimer(String name) {
    _timers[name] = DateTime.now();
    if (kDebugMode) {
      developer.log('Performance Timer Started: $name');
    }
  }

  /// 结束性能计时并记录
  void endTimer(String name) {
    final startTime = _timers[name];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _metrics.add(PerformanceMetric(
        name: name,
        duration: duration,
        timestamp: DateTime.now(),
      ));
      
      if (kDebugMode) {
        developer.log('Performance Timer Ended: $name - ${duration.inMilliseconds}ms');
      }
      
      _timers.remove(name);
    }
  }

  /// 测量函数执行时间
  static Future<T> measureAsync<T>(
    String name,
    Future<T> Function() function,
  ) async {
    final instance = PerformanceUtils();
    instance.startTimer(name);
    try {
      final result = await function();
      instance.endTimer(name);
      return result;
    } catch (e) {
      instance.endTimer(name);
      rethrow;
    }
  }

  /// 测量同步函数执行时间
  static T measureSync<T>(
    String name,
    T Function() function,
  ) {
    final instance = PerformanceUtils();
    instance.startTimer(name);
    try {
      final result = function();
      instance.endTimer(name);
      return result;
    } catch (e) {
      instance.endTimer(name);
      rethrow;
    }
  }

  /// 获取性能指标
  List<PerformanceMetric> getMetrics() {
    return List.unmodifiable(_metrics);
  }

  /// 获取指定名称的性能指标
  List<PerformanceMetric> getMetricsByName(String name) {
    return _metrics.where((metric) => metric.name == name).toList();
  }

  /// 获取平均执行时间
  Duration getAverageTime(String name) {
    final metrics = getMetricsByName(name);
    if (metrics.isEmpty) return Duration.zero;
    
    final totalMs = metrics.fold<int>(
      0,
      (sum, metric) => sum + metric.duration.inMilliseconds,
    );
    
    return Duration(milliseconds: totalMs ~/ metrics.length);
  }

  /// 清除性能指标
  void clearMetrics() {
    _metrics.clear();
  }

  /// 导出性能报告
  Map<String, dynamic> generateReport() {
    final report = <String, dynamic>{};
    final groupedMetrics = <String, List<PerformanceMetric>>{};
    
    // 按名称分组
    for (final metric in _metrics) {
      groupedMetrics.putIfAbsent(metric.name, () => []).add(metric);
    }
    
    // 生成统计信息
    for (final entry in groupedMetrics.entries) {
      final name = entry.key;
      final metrics = entry.value;
      
      final durations = metrics.map((m) => m.duration.inMilliseconds).toList();
      durations.sort();
      
      report[name] = {
        'count': metrics.length,
        'average': durations.fold(0, (a, b) => a + b) / durations.length,
        'min': durations.first,
        'max': durations.last,
        'median': durations[durations.length ~/ 2],
        'p95': durations[(durations.length * 0.95).floor()],
      };
    }
    
    return report;
  }

  /// 内存使用情况监控
  static Future<MemoryInfo> getMemoryInfo() async {
    try {
      final info = await SystemChannels.platform.invokeMethod<Map>('getMemoryInfo');
      return MemoryInfo.fromMap(info ?? {});
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to get memory info: $e');
      }
      return MemoryInfo.empty();
    }
  }

  /// 帧率监控
  static void startFrameRateMonitoring() {
    if (kDebugMode) {
      WidgetsBinding.instance.addTimingsCallback((timings) {
        for (final timing in timings) {
          final frameTime = timing.totalSpan.inMilliseconds;
          if (frameTime > 16) { // 超过16ms表示掉帧
            developer.log('Frame drop detected: ${frameTime}ms');
          }
        }
      });
    }
  }

  /// 网络请求性能监控
  static Future<T> monitorNetworkRequest<T>(
    String url,
    Future<T> Function() request,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await request();
      stopwatch.stop();
      
      if (kDebugMode) {
        developer.log('Network Request: $url - ${stopwatch.elapsedMilliseconds}ms');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      if (kDebugMode) {
        developer.log('Network Request Failed: $url - ${stopwatch.elapsedMilliseconds}ms - $e');
      }
      
      rethrow;
    }
  }

  /// 数据库操作性能监控
  static Future<T> monitorDatabaseOperation<T>(
    String operation,
    Future<T> Function() dbOperation,
  ) async {
    return measureAsync('db_$operation', dbOperation);
  }

  /// UI渲染性能监控
  static void monitorWidgetBuild(String widgetName, VoidCallback buildFunction) {
    measureSync('widget_build_$widgetName', buildFunction);
  }

  /// 批量操作性能优化
  static Future<List<T>> batchProcess<T, R>(
    List<R> items,
    Future<T> Function(R) processor, {
    int batchSize = 10,
    Duration delay = const Duration(milliseconds: 1),
  }) async {
    final results = <T>[];
    
    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        batch.map(processor),
      );
      results.addAll(batchResults);
      
      // 给UI线程一些时间
      if (i + batchSize < items.length) {
        await Future.delayed(delay);
      }
    }
    
    return results;
  }

  /// 防抖函数
  static Timer? _debounceTimer;
  static void debounce(Duration duration, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  /// 节流函数
  static DateTime? _lastThrottleTime;
  static void throttle(Duration duration, VoidCallback callback) {
    final now = DateTime.now();
    if (_lastThrottleTime == null || 
        now.difference(_lastThrottleTime!) >= duration) {
      _lastThrottleTime = now;
      callback();
    }
  }
}

class PerformanceMetric {
  final String name;
  final Duration duration;
  final DateTime timestamp;

  PerformanceMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PerformanceMetric{name: $name, duration: ${duration.inMilliseconds}ms, timestamp: $timestamp}';
  }
}

class MemoryInfo {
  final int totalMemory;
  final int usedMemory;
  final int freeMemory;

  MemoryInfo({
    required this.totalMemory,
    required this.usedMemory,
    required this.freeMemory,
  });

  factory MemoryInfo.fromMap(Map<dynamic, dynamic> map) {
    return MemoryInfo(
      totalMemory: map['totalMemory'] ?? 0,
      usedMemory: map['usedMemory'] ?? 0,
      freeMemory: map['freeMemory'] ?? 0,
    );
  }

  factory MemoryInfo.empty() {
    return MemoryInfo(
      totalMemory: 0,
      usedMemory: 0,
      freeMemory: 0,
    );
  }

  double get usagePercentage {
    if (totalMemory == 0) return 0.0;
    return (usedMemory / totalMemory) * 100;
  }

  @override
  String toString() {
    return 'MemoryInfo{total: ${totalMemory}MB, used: ${usedMemory}MB, free: ${freeMemory}MB, usage: ${usagePercentage.toStringAsFixed(1)}%}';
  }
}

/// 性能监控装饰器
class PerformanceMonitor {
  static Widget wrapWidget(String name, Widget child) {
    return _PerformanceWrapper(name: name, child: child);
  }
}

class _PerformanceWrapper extends StatefulWidget {
  final String name;
  final Widget child;

  const _PerformanceWrapper({
    required this.name,
    required this.child,
  });

  @override
  State<_PerformanceWrapper> createState() => _PerformanceWrapperState();
}

class _PerformanceWrapperState extends State<_PerformanceWrapper> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    PerformanceUtils().startTimer('widget_init_${widget.name}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PerformanceUtils().endTimer('widget_init_${widget.name}');
    });
  }

  @override
  void dispose() {
    PerformanceUtils().startTimer('widget_dispose_${widget.name}');
    super.dispose();
    PerformanceUtils().endTimer('widget_dispose_${widget.name}');
  }
}