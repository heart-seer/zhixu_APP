import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../shared/main_bottom_nav.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _searchController = TextEditingController();
  String _filter = 'AI 待提取';
  String _source = '全部来源';
  bool _searching = false;
  final _messages = <_MessageItem>[
    _MessageItem(source: '企业微信', sender: '研发项目组 · 王老师', time: '10:32', title: 'Q3 阶段总结周报请于今天下班前提交', preview: '请各位补充本周交付内容和下周风险，周五前完成汇总。', pending: true, color: const Color(0xFF16A06A)),
    _MessageItem(source: '学习通', sender: '数据结构课程 · 教学通知', time: '09:18', title: '实验报告提交截止时间提醒', preview: '第三次实验报告请在本周日 23:59 前提交至课程平台。', pending: true, color: const Color(0xFF2563EB)),
    _MessageItem(source: '钉钉', sender: '研究生课题组', time: '昨天', title: '周三组会文献分享安排', preview: '本周轮到你分享论文，请准备 15 分钟汇报。', pending: false, color: const Color(0xFF3B82F6)),
    _MessageItem(source: '企业微信', sender: '导师 · 李教授', time: '昨天', title: '下周实验计划确认', preview: '请先跑完基线模型，再整理对比实验结果。', pending: false, color: const Color(0xFF16A06A)),
  ];

  List<_MessageItem> get _visibleMessages => _messages.where((message) {
    final tabMatch = _filter == '全部消息' || (_filter == 'AI 待提取' ? message.pending : !message.pending);
    final sourceMatch = _source == '全部来源' || message.source == _source;
    final query = _searchController.text.trim().toLowerCase();
    final queryMatch = query.isEmpty || '${message.title} ${message.preview} ${message.sender}'.toLowerCase().contains(query);
    return tabMatch && sourceMatch && queryMatch;
  }).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _visibleMessages;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(backgroundColor: const Color(0xFFF8F9FF), title: const Row(children: [Text('智序', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(width: 8), Text('消息中心', style: TextStyle(fontWeight: FontWeight.w600))]), actions: [IconButton(onPressed: () => setState(() => _searching = !_searching), icon: const Icon(Icons.search)), IconButton(onPressed: _showSourceFilter, icon: const Icon(Icons.tune_rounded))]),
      body: Column(children: [
        if (_searching) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: TextField(controller: _searchController, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: '搜索消息内容或联系人', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.close)), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)))),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: ['全部消息', 'AI 待提取', '已同步']
                .map(
                  (tab) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(tab),
                      selected: _filter == tab,
                      onSelected: (_) => setState(() => _filter = tab),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF1EAFE), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFDCCBFA))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.auto_awesome, color: Color(0xFF712AE2)), const SizedBox(width: 10), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('AI 正在帮你识别重要事项', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 4), Text('从 5 个已连接平台发现 2 条待处理消息', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))])), TextButton(onPressed: _extractAll, child: const Text('批量提取'))]))),
        Expanded(child: messages.isEmpty ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.mark_email_read_outlined, size: 44, color: AppColors.textSecondary), SizedBox(height: 10), Text('没有符合条件的消息', style: TextStyle(color: AppColors.textSecondary))])) : ListView.separated(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), itemCount: messages.length, separatorBuilder: (_, _) => const SizedBox(height: 10), itemBuilder: (context, index) => _messageCard(messages[index]))),
      ]),
      bottomNavigationBar: const MainBottomNav(selectedIndex: 3),
    );
  }

  Widget _messageCard(_MessageItem item) => InkWell(
        onTap: () => _showMessage(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: .5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
                Text(item.source, style: TextStyle(fontSize: 12, color: item.color, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.sender, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ),
                Text(item.time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 10),
              Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(item.preview, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, height: 1.45, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Row(children: [
                if (item.pending)
                  const _StatusTag(label: 'AI 待提取', color: Color(0xFF712AE2))
                else
                  const _StatusTag(label: '已同步', color: Color(0xFF059669)),
                const Spacer(),
                if (item.pending)
                  TextButton.icon(
                    onPressed: () => _extract(item),
                    icon: const Icon(Icons.add_task, size: 17),
                    label: const Text('转为任务'),
                  )
                else
                  TextButton(onPressed: () => _message('已标记为已读'), child: const Text('标记已读')),
              ]),
            ],
          ),
        ),
      );

  void _showSourceFilter() => showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('消息来源', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final source in ['全部来源', '企业微信', '学习通', '钉钉'])
              RadioListTile<String>(value: source, groupValue: _source, title: Text(source), onChanged: (value) { setState(() => _source = value!); setSheetState(() {}); }),
          ]),
        ),
      ),
    ),
  );
  void _showMessage(_MessageItem item) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.source, style: TextStyle(color: item.color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(item.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(item.preview, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 18),
                if (item.pending)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _extract(item);
                      },
                      icon: const Icon(Icons.add_task),
                      label: const Text('AI 识别并创建任务'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
  void _extract(_MessageItem item) { setState(() => item.pending = false); _message('已从消息中提取任务'); }
  void _extractAll() { setState(() { for (final item in _messages) { item.pending = false; } }); _message('已批量提取待处理事项'); }
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _MessageItem {
  _MessageItem({required this.source, required this.sender, required this.time, required this.title, required this.preview, required this.pending, required this.color});
  final String source;
  final String sender;
  final String time;
  final String title;
  final String preview;
  bool pending;
  final Color color;
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)));
}
