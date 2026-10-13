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
  String _filter = '全部消息';
  String _source = '全部来源';
  bool _searching = false;
  final _messages = <_MessageItem>[
    _MessageItem(
      source: '企业微信',
      sender: '研发项目组 · 王老师',
      time: '10:32',
      title: 'Q3 阶段总结周报请于今天下班前提交',
      preview: '请各位补充本周交付内容和下周风险，周五前完成汇总。',
      pending: true,
      color: const Color(0xFF16A06A),
    ),
    _MessageItem(
      source: '学习通',
      sender: '数据结构课程 · 教学通知',
      time: '09:18',
      title: '实验报告提交截止时间提醒',
      preview: '第三次实验报告请在本周日 23:59 前提交至课程平台。',
      pending: true,
      color: const Color(0xFF2563EB),
    ),
    _MessageItem(
      source: '钉钉',
      sender: '研究生课题组',
      time: '昨天',
      title: '周三组会文献分享安排',
      preview: '本周轮到你分享论文，请准备 15 分钟汇报。',
      pending: false,
      color: const Color(0xFF3B82F6),
    ),
    _MessageItem(
      source: '企业微信',
      sender: '导师 · 李教授',
      time: '昨天',
      title: '下周实验计划确认',
      preview: '请先跑完基线模型，再整理对比实验结果。',
      pending: false,
      color: const Color(0xFF16A06A),
    ),
  ];

  List<_MessageItem> get _visibleMessages => _messages.where((message) {
    final tabMatch =
        _filter == '全部消息' ||
        (_filter == 'AI 待提取' ? message.pending : !message.pending);
    final sourceMatch = _source == '全部来源' || message.source == _source;
    final query = _searchController.text.trim().toLowerCase();
    final queryMatch =
        query.isEmpty ||
        '${message.title} ${message.preview} ${message.sender}'
            .toLowerCase()
            .contains(query);
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
    final pendingCount = _messages.where((item) => item.pending).length;
    final syncedCount = _messages.length - pendingCount;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        toolbarHeight: 62,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF8F9FF),
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFE5EEFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 9),
            const Text(
              '智序',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _searchController.clear();
            }),
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
          ),
          IconButton(
            onPressed: _showSourceFilter,
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '搜索消息内容或联系人',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 3),
            child: Row(
              children: [
                const Text(
                  '消息中心',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                _messageCountBadge(),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _filterChip('全部消息'),
                _filterChip('AI 待提取', count: pendingCount),
                _filterChip('已同步', count: syncedCount),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    onPressed: _showSourceFilter,
                    avatar: const Icon(Icons.tune_rounded, size: 14),
                    label: const Text('来源'),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFAFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4D8FF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D712AE2),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B2FF7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Text(
                        '智能排程雷达',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6425D0),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0E8FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          pendingCount == 0 ? '已全部提取' : '自动分析中',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF712AE2),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: '已为您自动从 '),
                          const TextSpan(
                            text: '5 个平台',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const TextSpan(text: ' 抓取 '),
                          TextSpan(
                            text: '$pendingCount 条',
                            style: const TextStyle(
                              color: Color(0xFF7B2FF7),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(text: ' 包含明确截止时间与行动指令的消息。'),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.65,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFE8DFFF)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 104,
                        height: 26,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              child: _sourceIcon('学', const Color(0xFFFF7043)),
                            ),
                            Positioned(
                              left: 19,
                              child: _sourceIcon('企', const Color(0xFF2589FF)),
                            ),
                            Positioned(
                              left: 38,
                              child: _sourceIcon('腾', const Color(0xFF22A6D5)),
                            ),
                            Positioned(
                              left: 57,
                              child: _sourceIcon('钉', const Color(0xFF1677FF)),
                            ),
                            Positioned(
                              left: 76,
                              child: _sourceIcon('飞', const Color(0xFF18A0FB)),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: pendingCount == 0 ? null : _extractAll,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF712AE2),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        iconAlignment: IconAlignment.end,
                        label: Text(
                          pendingCount == 0 ? '暂无待提取消息' : '一键快速确认转待办',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mark_email_read_outlined,
                          size: 44,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 10),
                        Text(
                          '没有符合条件的消息',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _messageCard(messages[index]),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(selectedIndex: 3),
    );
  }

  Widget _sourceIcon(String label, Color color) => Container(
    width: 26,
    height: 26,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFE9E7F0)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w800),
    ),
  );

  Widget _filterChip(String label, {int? count}) {
    final selected = _filter == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _filter = label),
        showCheckmark: false,
        backgroundColor: const Color(0xFFE5EEFF),
        selectedColor: AppColors.primary,
        side: BorderSide.none,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected && label == 'AI 待提取') ...[
                const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                const SizedBox(width: 3),
              ],
              Text(label),
              if (count != null) ...[
                const SizedBox(width: 4),
                Text('($count)'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageCountBadge() {
    const connectedPlatforms = 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$connectedPlatforms 个平台已联通',
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _messageCard(_MessageItem item) => InkWell(
    onTap: () => _showMessage(item),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B2C5F),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                item.source,
                style: TextStyle(
                  fontSize: 12,
                  color: item.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.sender,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                item.time,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            item.preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
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
                TextButton(
                  onPressed: item.read
                      ? null
                      : () => setState(() => item.read = true),
                  child: Text(item.read ? '已读' : '标记已读'),
                ),
            ],
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '消息来源',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final source in ['全部来源', '企业微信', '学习通', '钉钉'])
                RadioListTile<String>(
                  value: source,
                  groupValue: _source,
                  title: Text(source),
                  onChanged: (value) {
                    setState(() => _source = value!);
                    setSheetState(() {});
                  },
                ),
            ],
          ),
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
            Text(
              item.source,
              style: TextStyle(color: item.color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
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
  void _extract(_MessageItem item) {
    setState(() => item.pending = false);
  }

  void _extractAll() {
    setState(() {
      for (final item in _messages) {
        item.pending = false;
      }
    });
  }
}

class _MessageItem {
  _MessageItem({
    required this.source,
    required this.sender,
    required this.time,
    required this.title,
    required this.preview,
    required this.pending,
    required this.color,
  });
  final String source;
  final String sender;
  final String time;
  final String title;
  final String preview;
  bool pending;
  bool read = false;
  final Color color;
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
    ),
  );
}
