import 'package:PiliPlus/http/api_hosts.dart';
import 'package:PiliPlus/pages/setting/widgets/switch_item.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class ApiHostPage extends StatefulWidget {
  const ApiHostPage({super.key});

  @override
  State<ApiHostPage> createState() => _ApiHostPageState();
}

class _ApiHostPageState extends State<ApiHostPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('自定义 API 地址'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '开启后可自定义各 API 地址，留空则使用默认地址',
              style: TextStyle(
                color: theme.colorScheme.outline,
                fontSize: 14,
              ),
            ),
          ),
          const Divider(height: 1),
          SetSwitchItem(
            title: '启用自定义 API 地址',
            subtitle: Pref.enableCustomApiHost ? '已启用' : '已关闭',
            setKey: SettingBoxKey.enableCustomApiHost,
            defaultVal: false,
            onChanged: (_) => setState(() {}),
          ),
          if (Pref.enableCustomApiHost) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'API 地址列表',
                style: TextStyle(
                  color: theme.colorScheme.outline,
                  fontSize: 13,
                ),
              ),
            ),
            ...apiHostEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ApiHostTile(
                  entry: entry,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ApiHostTile extends StatefulWidget {
  final ApiHostEntry entry;
  final VoidCallback onChanged;

  const _ApiHostTile({
    required this.entry,
    required this.onChanged,
  });

  @override
  State<_ApiHostTile> createState() => _ApiHostTileState();
}

class _ApiHostTileState extends State<_ApiHostTile> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final currentValue =
        GStorage.setting.get(widget.entry.settingKey, defaultValue: '')
            as String;
    _controller = TextEditingController(text: currentValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          widget.entry.label,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '默认: ${widget.entry.defaultHost}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '留空则使用默认地址',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: theme.textTheme.bodySmall,
                onChanged: (value) {
                  GStorage.setting.put(widget.entry.settingKey, value);
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.restart_alt, size: 20),
              tooltip: '重置为默认',
              onPressed: () {
                _controller.clear();
                GStorage.setting.delete(widget.entry.settingKey);
                widget.onChanged();
                SmartDialog.showToast('已重置');
              },
            ),
          ],
        ),
        const Divider(height: 16),
      ],
    );
  }
}
