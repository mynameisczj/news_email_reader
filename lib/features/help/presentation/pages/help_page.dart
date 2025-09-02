import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/help_content_zh.dart';
import '../data/help_content_en.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帮助指南'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          tabs: const [
            Tab(text: '中文'),
            Tab(text: 'English'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHelpContent(helpContentZh),
          _buildHelpContent(helpContentEn),
        ],
      ),
    );
  }

  Widget _buildHelpContent(List<Map<String, dynamic>> content) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: content.length,
      itemBuilder: (context, index) {
        final section = content[index];
        final bool isFaq = section['isFaq'] ?? false;

        if (isFaq) {
          return _buildFaqSection(context, section);
        } else {
          return _buildSection(context, section);
        }
      },
    );
  }

  Widget _buildSection(BuildContext context, Map<String, dynamic> section) {
    final title = section['title'] as String;
    final content = section['content'] as String;
    final points = section['points'] as List<String>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
            if (points != null && points.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...points.map((point) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppTheme.primaryColor)),
                        Expanded(child: Text(point, style: Theme.of(context).textTheme.bodyMedium)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection(BuildContext context, Map<String, dynamic> section) {
    final title = section['title'] as String;
    final faqs = section['faqs'] as List<Map<String, String>>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
        ),
        children: faqs.map((faq) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q: ${faq['question']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'A: ${faq['answer']}',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
                const Divider(height: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}