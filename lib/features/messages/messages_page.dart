import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_presentation.dart';
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
      source: '学习通',
      sender: '高数课代表通知',
      time: '10分钟前',
      title: '第五章课后习题',
      preview: '各位同学，第五章课后习题请于 本周五晚22:00前 提交到系统，逾期无法补交！',
      highlight: '本周五晚22:00前',
      detail: '截止时间: 周五22:00  ·  优先级: P1紧急',
      category: '分类: 学业作业',
      footer: '提取置信度98%',
      pending: true,
      color: const Color(0xFFD71920),
    ),
    _MessageItem(
      source: '企业微信',
      sender: '李总监 (产品规划组)',
      time: '35分钟前',
      title: 'Q4智能硬件需求文档初稿',
      preview: '@全员 请在 今天下午16:00前 将Q4智能硬件需求文档初稿同步给测试组。',
      highlight: '今天下午16:00前',
      detail: '截止时间: 今日16:00  ·  指派人: 李总监',
      category: '涉及交付物: Q4需求文档初稿',
      footer: '来源群聊：硬件战略协同中心',
      pending: true,
      color: const Color(0xFFA87500),
    ),
    _MessageItem(
      source: '腾讯会议',
      sender: '系统通知',
      time: '',
      title: '产品迭代对齐会',
      preview: '您已成功预约并受邀参会：“10月24日19:30 产品迭代对齐会”，会议号: 839-204-112。',
      highlight: '10月24日19:30 产品迭代对齐会',
      detail: '日历项: 10月24日19:30–20:30 (会议前15分钟提醒)',
      status: '已排入日历并设提醒',
      secondaryAction: '查看日程',
      kind: _MessageKind.calendar,
      pending: false,
      color: const Color(0xFF0754D6),
    ),
    _MessageItem(
      source: '钉钉',
      sender: '架构研发项目组',
      time: '2小时前',
      title: 'Q4-Service-Mesh-Refactor.pdf',
      preview: '关于下周二技术架构评审会的议程与参考材料已共享至云盘《Q4-Service-Mesh-Refactor.pdf》，请参会导师及核心开发人员提前查阅。',
      footer: '含1个云盘附件',
      secondaryAction: '查看文件',
      kind: _MessageKind.attachment,
      pending: false,
      color: const Color(0xFFCBD0DF),
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
        '${message.title} ${message.preview} ${message.sender} ${message.source} ${message.detail ?? ''}'
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
      backgroundColor: const Color(0xFFF5F8FC),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF8753E8), Color(0xFF5B6CE8)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x30765BD6),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextButton.icon(
          onPressed: _showImportPanel,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: const Text(
            '对话导入',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      appBar: AppBar(
        toolbarHeight: 62,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF5F8FC),
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
            onPressed: _showRadarStatus,
            tooltip: '当前雷达状态',
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF7B2FF7)),
          ),
          const SizedBox(width: 12),
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
                const Spacer(),
                _messageCountBadge(),
                IconButton(
                  onPressed: () => setState(() {
                    _searching = !_searching;
                    if (!_searching) _searchController.clear();
                  }),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 36,
                  ),
                  padding: const EdgeInsets.all(4),
                  icon: const Icon(Icons.search, size: 20),
                  tooltip: '搜索消息',
                ),
                IconButton(
                  onPressed: _showSourceFilter,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 36,
                  ),
                  padding: const EdgeInsets.all(4),
                  icon: const Icon(Icons.tune_rounded, size: 19),
                  tooltip: '筛选来源',
                ),
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
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
                          pendingCount == 0 ? '已全部同步' : '本地示例',
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
                          const TextSpan(text: '已为您整理来自 '),
                          const TextSpan(
                            text: '5 个平台',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const TextSpan(text: ' 的 '),
                          TextSpan(
                            text: '$pendingCount 条',
                            style: const TextStyle(
                              color: Color(0xFF7B2FF7),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(text: ' 待确认消息，当前仅为本地示例，未接入实时抓取或AI解析。'),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.65,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 84),
                    itemCount: messages.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => index == messages.length
                        ? _privacyNotice()
                        : _messageCard(messages[index]),
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
        backgroundColor: label == '已同步'
            ? Colors.white
            : const Color(0xFFE5EEFF),
        selectedColor: label == 'AI 待提取'
            ? const Color(0xFF7624E8)
            : label == '已同步'
            ? Colors.white
            : const Color(0xFFD3E4FF),
        shape: const StadiumBorder(),
        side: label == '已同步'
            ? const BorderSide(color: Color(0xFFE3E8F2))
            : BorderSide.none,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: selected && label == 'AI 待提取'
              ? Colors.white
              : AppColors.textPrimary,
        ),
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label == 'AI 待提取') ...[
                Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: selected ? Colors.white : const Color(0xFF7624E8),
                ),
                const SizedBox(width: 3),
              ],
              Text(label),
              if (count != null) ...[
                const SizedBox(width: 4),
                if (label == 'AI 待提取')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Color(0xFF7624E8),
                        fontSize: 10,
                      ),
                    ),
                  )
                else
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
        '$connectedPlatforms 平台已联通',
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
    borderRadius: BorderRadius.circular(14),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090B2C5F),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: item.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 13, 13, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _sourcePill(item),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            item.sender,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (item.status != null)
                          _StatusTag(
                            label: item.status!,
                            color: const Color(0xFF059669),
                          )
                        else
                          Text(
                            item.time,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _highlightPreview(item),
                    if (item.detail != null) ...[
                      const SizedBox(height: 10),
                      _infoBlock(item),
                    ],
                    if (item.kind != _MessageKind.calendar) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: Color(0xFFF1F3F8)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (item.source == '学习通' ||
                              item.kind == _MessageKind.attachment) ...[
                            Icon(
                              item.kind == _MessageKind.attachment
                                  ? Icons.attach_file
                                  : Icons.insights,
                              size: 13,
                              color: item.kind == _MessageKind.attachment
                                  ? AppColors.textSecondary
                                  : const Color(0xFF7624E8),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              item.footer ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (item.pending)
                            FilledButton.icon(
                              onPressed: () => _extract(item),
                              icon: const Icon(Icons.auto_awesome, size: 13),
                              label: Text(
                                item.source == '本地导入'
                                    ? '确认同步'
                                    : item.source == '企业微信'
                                    ? 'AI 提取任务'
                                    : 'AI 转为任务',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF7624E8),
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            )
                          else if (item.kind == _MessageKind.calendar)
                            _StatusTag(
                              label: item.read ? '已读 · 已同步' : '已同步',
                              color: const Color(0xFF059669),
                            )
                          else if (item.secondaryAction != null)
                            TextButton(
                              onPressed: () => _showAttachment(item),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF4D84C4),
                                backgroundColor: const Color(0xFFEAF4FF),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: Text(item.secondaryAction!),
                            )
                          else
                            _StatusTag(
                              label: '已同步',
                              color: const Color(0xFF059669),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _sourcePill(_MessageItem item) {
    final color = switch (item.source) {
      '学习通' => const Color(0xFFC77500),
      '企业微信' => const Color(0xFF1D66E8),
      '腾讯会议' => const Color(0xFF0098BD),
      '钉钉' => const Color(0xFF008BCD),
      _ => const Color(0xFF7624E8),
    };
    final icon = switch (item.source) {
      '学习通' => Icons.school_outlined,
      '企业微信' => Icons.apartment_rounded,
      '腾讯会议' => Icons.videocam_outlined,
      '钉钉' => Icons.bolt,
      _ => Icons.chat_bubble_outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .06),
        border: Border.all(color: color.withValues(alpha: .12)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            item.source,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightPreview(_MessageItem item) {
    const style = TextStyle(
      fontSize: 14,
      height: 1.6,
      color: AppColors.textPrimary,
    );
    final highlight = item.highlight;
    if (highlight == null || !item.preview.contains(highlight)) {
      return Text(item.preview, style: style);
    }
    final parts = item.preview.split(highlight);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: parts.first),
          TextSpan(
            text: highlight,
            style: TextStyle(
              color: item.kind == _MessageKind.calendar
                  ? AppColors.textPrimary
                  : item.color,
              fontWeight: FontWeight.w800,
              backgroundColor: item.kind == _MessageKind.calendar
                  ? null
                  : item.color.withValues(alpha: .12),
            ),
          ),
          TextSpan(text: parts.sublist(1).join(highlight)),
        ],
      ),
      style: style,
    );
  }

  Widget _infoBlock(_MessageItem item) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F6FC),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          item.kind == _MessageKind.attachment
              ? Icons.attach_file_rounded
              : Icons.event_note_outlined,
          size: 14,
          color: const Color(0xFF7790AC),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            [item.detail, item.category].whereType<String>().join('\n'),
            style: const TextStyle(
              fontSize: 10,
              height: 1.45,
              color: Color(0xFF536A83),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (item.kind == _MessageKind.calendar) ...[
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => context.go(RouteNames.calendar),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF557ED3),
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 10),
            ),
            child: const Text('查看日程'),
          ),
        ],
      ],
    ),
  );

  Future<void> _showSourceFilter() async {
    var draft = _source;
    final result = await showAppDialog<String>(
      context: context,
      title: '消息来源',
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final source in ['全部来源', '企业微信', '学习通', '腾讯会议', '钉钉', '本地导入'])
              ListTile(
                title: Text(source),
                trailing: draft == source
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => update(() => draft = source),
              ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('取消'),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, draft),
                    child: const Text('应用'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _source = result);
  }

  Widget _privacyNotice() => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.lock_outline, size: 13, color: Color(0xFF6F7A8B)),
        SizedBox(width: 5),
        Text(
          '端侧加密隐私保护中，消息实时本地识别解析',
          style: TextStyle(fontSize: 10, color: Color(0xFF6F7A8B)),
        ),
      ],
    ),
  );

  void _showRadarStatus() => showAppDialog<void>(
    context: context,
    title: '智能排程雷达',
    builder: (_) => Text(
      '待确认 ${_messages.where((item) => item.pending).length} 条 · 已同步 ${_messages.where((item) => !item.pending).length} 条\n\n当前为本地示例状态。消息内容仅在端侧展示，尚未接入实时抓取、AI解析或云端同步。',
      style: const TextStyle(height: 1.6),
    ),
  );

  void _showAttachment(_MessageItem item) => showAppDialog<void>(
    context: context,
    title: '本地附件信息',
    builder: (_) => Text(
      '${item.title}\n\n当前没有接入真实附件服务，未生成下载链接或伪造下载操作。',
      style: const TextStyle(height: 1.6),
    ),
  );

  Future<void> _showImportPanel() async {
    final text = await pushAppPage<String>(
      context: context,
      title: '对话导入',
      builder: (_) => const _ImportEditor(),
    );
    if (!mounted || text == null) return;
    setState(() {
      _filter = '全部消息';
      _source = '全部来源';
      _searchController.clear();
      _messages.insert(
        0,
        _MessageItem(
          source: '本地导入',
          sender: '对话文本',
          time: '刚刚',
          title: '待确认对话',
          preview: text,
          footer: '本地导入 · 未进行AI解析',
          pending: true,
          color: const Color(0xFF7624E8),
        ),
      );
    });
  }

  void _showMessage(_MessageItem item) {
    setState(() => item.read = true);
    pushAppPage<void>(
      context: context,
      title: '消息详情',
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sourcePill(item),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(item.preview, style: const TextStyle(height: 1.5)),
              if (item.detail != null) ...[
                const SizedBox(height: 14),
                _infoBlock(item),
              ],
              const SizedBox(height: 18),
              if (item.pending)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _extract(item);
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('确认并标记已同步（本地）'),
                  ),
                )
              else
                _StatusTag(
                  label: item.status ?? '已同步 · 已读',
                  color: const Color(0xFF059669),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _extract(_MessageItem item) {
    if (!item.pending) return;
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

class _ImportEditor extends StatefulWidget {
  const _ImportEditor();
  @override
  State<_ImportEditor> createState() => _ImportEditorState();
}

class _ImportEditorState extends State<_ImportEditor> {
  final _controller = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('输入对话文本后加入本地待确认消息列表，不进行真实 AI 解析。'),
      const SizedBox(height: 16),
      TextField(
        controller: _controller,
        minLines: 4,
        maxLines: 7,
        decoration: InputDecoration(
          labelText: '对话内容',
          hintText: '粘贴或输入对话内容',
          errorText: _error,
        ),
        onChanged: (_) => setState(() => _error = null),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () {
          final text = _controller.text.trim();
          if (text.isEmpty) {
            setState(() => _error = '请输入非空对话内容');
            return;
          }
          Navigator.pop(context, text);
        },
        child: const Text('加入待确认消息'),
      ),
    ],
  );
}

enum _MessageKind { task, calendar, attachment }

class _MessageItem {
  _MessageItem({
    required this.source,
    required this.sender,
    required this.time,
    required this.title,
    required this.preview,
    required this.pending,
    required this.color,
    this.kind = _MessageKind.task,
    this.highlight,
    this.detail,
    this.category,
    this.footer,
    this.status,
    this.secondaryAction,
  });
  final _MessageKind kind;
  final String? highlight;
  final String? detail;
  final String? category;
  final String? footer;
  final String? status;
  final String? secondaryAction;
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
