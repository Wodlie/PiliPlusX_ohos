import 'package:PiliPlus/pages/setting/models/block_filter_settings.dart';
import 'package:flutter/material.dart';

class BlockFilterSetting extends StatefulWidget {
  const BlockFilterSetting({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<BlockFilterSetting> createState() => _BlockFilterSettingState();
}

class _BlockFilterSettingState extends State<BlockFilterSetting> {
  final settings = blockFilterSettings;

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: showAppBar ? AppBar(title: const Text('屏蔽与过滤')) : null,
      body: ListView(
        padding: EdgeInsets.only(
          left: showAppBar ? padding.left : 0,
          right: showAppBar ? padding.right : 0,
          bottom: padding.bottom + 100,
        ),
        children: settings.map((item) => item.widget).toList(),
      ),
    );
  }
}
