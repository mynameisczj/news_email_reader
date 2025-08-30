import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/email_account.dart';
import '../../../../core/repositories/account_repository.dart';
import '../../../../core/constants/app_constants.dart';

class AccountManagementSection extends ConsumerStatefulWidget {
  const AccountManagementSection({super.key});

  @override
  ConsumerState<AccountManagementSection> createState() => _AccountManagementSectionState();
}

class _AccountManagementSectionState extends ConsumerState<AccountManagementSection> {
  final AccountRepository _accountRepository = AccountRepository();
  List<EmailAccount> _accounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final accounts = await _accountRepository.getAllAccounts();
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载账户失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAccountList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAccountList() {
    if (_accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无邮件账户',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右下角按钮添加邮件账户',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        return _buildAccountCard(account);
      },
    );
  }

  Widget _buildAccountCard(EmailAccount account) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: account.isActive ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
          child: Text(
            account.email[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          account.displayName ?? account.email,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(account.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    account.protocol,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: account.isActive 
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    account.isActive ? '活跃' : '停用',
                    style: TextStyle(
                      fontSize: 10,
                      color: account.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAccountAction(value, account),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: const [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('编辑'),
                ],
              ),
            ),
            PopupMenuItem(
              value: account.isActive ? 'disable' : 'enable',
              child: Row(
                children: [
                  Icon(account.isActive ? Icons.pause : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(account.isActive ? '停用' : '启用'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'test',
              child: Row(
                children: const [
                  Icon(Icons.wifi_tethering),
                  SizedBox(width: 8),
                  Text('测试连接'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAccountAction(String action, EmailAccount account) {
    switch (action) {
      case 'edit':
        _showEditAccountDialog(account);
        break;
      case 'enable':
      case 'disable':
        _toggleAccountStatus(account);
        break;
      case 'test':
        _testAccountConnection(account);
        break;
      case 'delete':
        _showDeleteAccountDialog(account);
        break;
    }
  }

  void _showAddAccountDialog() {
    _showAccountDialog();
  }

  void _showEditAccountDialog(EmailAccount account) {
    _showAccountDialog(account: account);
  }

  void _showAccountDialog({EmailAccount? account}) {
    final isEditing = account != null;
    final emailController = TextEditingController(text: account?.email ?? '');
    final passwordController = TextEditingController(text: account?.password ?? '');
    final displayNameController = TextEditingController(text: account?.displayName ?? '');
    final hostController = TextEditingController(text: account?.serverHost ?? '');
    final portController = TextEditingController(text: account?.serverPort.toString() ?? '993');
    
    String selectedProtocol = account?.protocol ?? 'IMAP';
    bool useSsl = account?.useSsl ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? '编辑账户' : '添加账户'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: '邮箱地址',
                    hintText: 'example@gmail.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    // 自动填充服务器配置
                    _autoFillServerConfig(value, hostController, portController, setDialogState);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: '密码/授权码',
                    hintText: '邮箱密码或应用专用密码',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: '显示名称（可选）',
                    hintText: '我的邮箱',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedProtocol,
                  decoration: const InputDecoration(
                    labelText: '协议类型',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'IMAP', child: Text('IMAP')),
                    DropdownMenuItem(value: 'POP3', child: Text('POP3')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProtocol = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hostController,
                  decoration: const InputDecoration(
                    labelText: '服务器地址',
                    hintText: 'imap.gmail.com',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: portController,
                  decoration: const InputDecoration(
                    labelText: '端口',
                    hintText: '993',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('使用SSL/TLS'),
                  value: useSsl,
                  onChanged: (value) {
                    setDialogState(() {
                      useSsl = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => _saveAccount(
                context,
                account,
                emailController.text,
                passwordController.text,
                displayNameController.text,
                selectedProtocol,
                hostController.text,
                int.tryParse(portController.text) ?? 993,
                useSsl,
              ),
              child: Text(isEditing ? '保存' : '添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _autoFillServerConfig(String email, TextEditingController hostController, 
      TextEditingController portController, StateSetter setDialogState) {
    final domain = email.split('@').last.toLowerCase();
    final config = AppConstants.emailProviders[domain];
    
    if (config != null) {
      final imapConfig = config['imap'];
      if (imapConfig != null) {
        setDialogState(() {
          hostController.text = imapConfig['host'];
          portController.text = imapConfig['port'].toString();
        });
      }
    }
  }

  Future<void> _saveAccount(
    BuildContext context,
    EmailAccount? existingAccount,
    String email,
    String password,
    String displayName,
    String protocol,
    String host,
    int port,
    bool useSsl,
  ) async {
    if (email.isEmpty || password.isEmpty || host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写必填字段')),
      );
      return;
    }

    Navigator.pop(context);

    try {
      final now = DateTime.now();
      final account = EmailAccount(
        id: existingAccount?.id,
        email: email,
        password: password,
        protocol: protocol,
        serverHost: host,
        serverPort: port,
        useSsl: useSsl,
        displayName: displayName.isEmpty ? null : displayName,
        createdAt: existingAccount?.createdAt ?? now,
        updatedAt: now,
      );

      if (existingAccount != null) {
        await _accountRepository.updateAccount(account);
      } else {
        await _accountRepository.addAccount(account);
      }

      await _loadAccounts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('账户${existingAccount != null ? '更新' : '添加'}成功')),
        );
      }
    } on DuplicateAccountException catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('账户重复'),
            content: Text(e.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('我知道了'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _toggleAccountStatus(EmailAccount account) async {
    try {
      if (account.isActive) {
        await _accountRepository.deactivateAccount(account.id!);
      } else {
        await _accountRepository.activateAccount(account.id!);
      }
      await _loadAccounts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('账户已${account.isActive ? '停用' : '启用'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _testAccountConnection(EmailAccount account) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('测试连接中...'),
          ],
        ),
      ),
    );

    try {
      final success = await _accountRepository.testAccountConnection(account);
      Navigator.pop(context); // 关闭加载对话框
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '连接成功' : '连接失败'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // 关闭加载对话框
      
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

  void _showDeleteAccountDialog(EmailAccount account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除账户'),
        content: Text('确定要删除账户 "${account.email}" 吗？\n\n这将同时删除该账户的所有邮件数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await _accountRepository.deleteAccount(account.id!);
                await _loadAccounts();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('账户已删除')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e')),
                  );
                }
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}