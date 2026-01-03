import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';

/// 双人报告HTML渲染器
class DualReportHtmlRenderer {
  /// 构建双人报告HTML
  static Future<String> build({
    required Map<String, dynamic> reportData,
    required String myName,
    required String friendName,
  }) async {
    // 加载字体
    final fonts = await _loadFonts();

    // 构建HTML
    final buffer = StringBuffer();

    // HTML头部
    buffer.writeln('<!doctype html>');
    buffer.writeln('<html lang="zh-CN">');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="utf-8" />');
    buffer.writeln('<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />');
    buffer.writeln('<title>双人聊天报告</title>');
    buffer.writeln('<script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>');
    buffer.writeln('<style>');
    buffer.writeln(_buildCss(fonts['regular']!, fonts['bold']!));
    buffer.writeln('</style>');
    buffer.writeln('</head>');

    // 内容主体
    buffer.writeln('<body>');
    buffer.writeln('<main class="main-container" id="capture">');

    // 第一部分：封面（我的名字 & 好友名字）
    buffer.writeln(_buildSection('cover', _buildCoverBody(myName, friendName)));

    // 第二部分：第一次聊天
    final firstChat = reportData['firstChat'] as Map<String, dynamic>?;
    final thisYearFirstChat = reportData['thisYearFirstChat'] as Map<String, dynamic>?;
    buffer.writeln(_buildSection('first-chat', _buildFirstChatBody(firstChat, thisYearFirstChat, myName, friendName)));

    // 第三部分：常用语（词云）
    final wordCloudRaw = reportData['wordCloud'];
    final wordCloudData =
        wordCloudRaw is Map ? wordCloudRaw.cast<String, dynamic>() : null;
    buffer.writeln(_buildSection('word-cloud', _buildWordCloudBody(wordCloudData, myName, friendName, reportData['year'] as int?)));

    // 第四部分：年度统计
    final yearlyStats = reportData['yearlyStats'] as Map<String, dynamic>?;
    buffer.writeln(_buildSection('yearly-stats', _buildYearlyStatsBody(yearlyStats, myName, friendName, reportData['year'] as int?)));

    final totalMessages = _parseInt(
      reportData['totalMessages'] ??
          (yearlyStats != null ? yearlyStats['totalMessages'] : null),
    );
    final sentMessages = _parseInt(reportData['sentMessages']);
    final receivedMessages = _parseInt(reportData['receivedMessages']);
    final rhythmRaw = reportData['rhythmStats'];
    final rhythmStats =
        rhythmRaw is Map ? rhythmRaw.cast<String, dynamic>() : null;
    final monthlyCounts =
        (reportData['monthlyCounts'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        [];

    // 第五部分：对话占比
    buffer.writeln(
      _buildSection(
        'message-balance',
        _buildMessageBalanceBody(
          totalMessages,
          sentMessages,
          receivedMessages,
          myName,
          friendName,
          reportData['year'] as int?,
        ),
      ),
    );

    // 第六部分：聊天节奏
    buffer.writeln(
      _buildSection(
        'chat-rhythm',
        _buildRhythmBody(
          rhythmStats,
          monthlyCounts,
          myName,
          friendName,
          reportData['year'] as int?,
        ),
      ),
    );

    buffer.writeln(
      _buildSection('ending', _buildEndingBody(myName, friendName)),
    );

    buffer.writeln('</main>');

    // JavaScript
    buffer.writeln(_buildScript(friendName));

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  /// 加载字体文件
  static Future<Map<String, String>> _loadFonts() async {
    final regular = await rootBundle.load('assets/HarmonyOS_SansSC/HarmonyOS_SansSC_Regular.ttf');
    final bold = await rootBundle.load('assets/HarmonyOS_SansSC/HarmonyOS_SansSC_Bold.ttf');

    return {
      'regular': base64Encode(regular.buffer.asUint8List()),
      'bold': base64Encode(bold.buffer.asUint8List()),
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// 构建CSS样式
  static String _buildCss(String regularFont, String boldFont) {
    return '''
@font-face {
  font-family: "H";
  src: url("data:font/ttf;base64,$regularFont") format("truetype");
  font-weight: 400;
  font-style: normal;
}

@font-face {
  font-family: "H";
  src: url("data:font/ttf;base64,$boldFont") format("truetype");
  font-weight: 700;
  font-style: normal;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

:root {
  --primary: #07C160;
  --accent: #F2AA00;
  --text-main: #222222;
  --text-sub: #555555;
  --bg-color: #F9F8F6;
  --line-color: rgba(0,0,0,0.06);
}

html {
  min-height: 100%;
  scroll-behavior: smooth;
}

body {
  min-height: 100vh;
  width: 100%;
  font-family: "H", "PingFang SC", sans-serif;
  background: var(--bg-color);
  color: var(--text-main);
  overflow-x: hidden;
}

body::before {
  content: "";
  position: fixed;
  inset: 0;
  background:
    radial-gradient(circle at 90% 5%, rgba(242, 170, 0, 0.06), transparent 50%),
    radial-gradient(circle at 5% 90%, rgba(7, 193, 96, 0.08), transparent 50%);
  pointer-events: none;
  z-index: -1;
}

.main-container {
  width: 100%;
  background: var(--bg-color);
  scroll-snap-type: y mandatory;
}

section.page {
  min-height: 100vh;
  width: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 80px max(8%, 30px);
  position: relative;
  scroll-snap-align: start;
}

.content-wrapper {
  max-width: 1000px;
  width: 100%;
  margin: 0 auto;
  text-align: left;
  opacity: 1;
  transform: translateY(0);
}

section.page.visible .content-wrapper {
  animation: fadeUp 1s cubic-bezier(0.2, 0.8, 0.2, 1) forwards;
}

@keyframes fadeUp {
  from { opacity: 0; transform: translateY(40px); }
  to { opacity: 1; transform: translateY(0); }
}


.label-text {
  font-size: 13px;
  letter-spacing: 3px;
  text-transform: uppercase;
  color: #888;
  margin-bottom: 16px;
  font-weight: 600;
}

.hero-title {
  font-size: clamp(36px, 5vw, 64px);
  font-weight: 700;
  line-height: 1.2;
  margin-bottom: 24px;
}

.hero-names {
  font-size: clamp(32px, 5vw, 56px);
  font-weight: 700;
  line-height: 1.3;
  margin: 20px 0 24px;
}

.hero-names .ampersand {
  color: var(--primary);
  margin: 0 12px;
}

.hero-desc {
  font-size: 18px;
  line-height: 1.7;
  color: var(--text-sub);
  max-width: 650px;
}

.divider {
  border: none;
  height: 3px;
  width: 80px;
  background: var(--accent);
  margin: 28px 0;
  opacity: 0.8;
}

.info-card {
  background: #FFFFFF;
  border-radius: 20px;
  padding: 32px;
  margin: 24px 0;
  border: 1px solid var(--line-color);
  box-shadow: 0 10px 24px rgba(0, 0, 0, 0.05);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.info-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 16px 32px rgba(0, 0, 0, 0.08);
}

.info-row {
  display: flex;
  gap: 24px;
  flex-wrap: wrap;
  align-items: flex-start;
}

.info-item {
  flex: 1 1 200px;
  min-width: 200px;
}

.info-label {
  font-size: 14px;
  color: #777;
  margin-bottom: 12px;
  letter-spacing: 1px;
}

.info-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-main);
  margin-bottom: 24px;
}

.info-row .info-value {
  margin-bottom: 0;
}

.info-value-sm {
  font-size: 20px;
  font-weight: 600;
  color: var(--text-main);
  word-break: break-all;
}
.ratio-bar {
  width: 100%;
  height: 12px;
  background: rgba(0, 0, 0, 0.08);
  border-radius: 999px;
  overflow: hidden;
  margin: 18px 0 10px;
}
.ratio-fill {
  height: 100%;
  background: linear-gradient(90deg, rgba(7, 193, 96, 0.95), rgba(7, 193, 96, 0.35));
}
.ratio-legend {
  font-size: 14px;
  color: #666;
  display: flex;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}
.month-badges {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 14px;
}
.month-badge {
  background: #F0F2F5;
  color: #555;
  padding: 4px 12px;
  border-radius: 999px;
  font-size: 13px;
  font-weight: 600;
  border: 1px solid rgba(0, 0, 0, 0.06);
}
.export-actions {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 28px;
  max-width: 320px;
}
.capture-btn {
  padding: 14px 28px;
  border-radius: 99px;
  background: var(--primary);
  color: white;
  border: none;
  font-size: 16px;
  font-weight: 600;
  box-shadow: 0 4px 12px rgba(7, 193, 96, 0.3);
  cursor: pointer;
  transition: all 0.3s ease;
}
.capture-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(7, 193, 96, 0.4);
}
.capture-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}
.capture-btn:active {
  transform: translateY(1px) scale(0.98);
  box-shadow: 0 2px 8px rgba(7, 193, 96, 0.3);
}
.capture-btn.module-btn {
  background: var(--accent);
  box-shadow: 0 4px 12px rgba(242, 170, 0, 0.3);
}
.capture-btn.module-btn:hover {
  box-shadow: 0 6px 16px rgba(242, 170, 0, 0.4);
}
.module-progress {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: white;
  padding: 32px 48px;
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.2);
  z-index: 10001;
  text-align: center;
  min-width: 280px;
}
.module-progress h3 { margin: 0 0 16px; font-size: 18px; color: var(--text-main); }
.module-progress .progress-bar { height: 8px; background: #eee; border-radius: 4px; overflow: hidden; margin-bottom: 12px; }
.module-progress .progress-fill { height: 100%; background: var(--primary); transition: width 0.3s ease; }
.module-progress .progress-text { font-size: 14px; color: var(--text-sub); }
.module-selector-modal { position: fixed; inset: 0; background: rgba(0,0,0,0.6); z-index: 10001; display: flex; justify-content: center; align-items: center; }
.module-selector-content { background: white; padding: 28px 32px; border-radius: 16px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); max-width: 400px; width: 90%; max-height: 80vh; display: flex; flex-direction: column; }
.module-selector-content h3 { margin: 0 0 20px; font-size: 20px; color: var(--text-main); text-align: center; }
.module-list { display: flex; flex-direction: column; gap: 8px; max-height: 400px; overflow-y: auto; padding-right: 8px; margin-bottom: 20px; }
.module-item { display: flex; align-items: center; gap: 12px; padding: 10px 14px; background: #f8f8f8; border-radius: 8px; cursor: pointer; transition: all 0.2s; }
.module-item:hover { background: #f0f0f0; }
.module-item input[type="checkbox"] { width: 18px; height: 18px; accent-color: var(--primary); cursor: pointer; }
.module-item span { font-size: 14px; color: var(--text-main); }
.module-selector-actions { display: flex; gap: 10px; justify-content: center; }
.module-selector-buttons { display: flex; gap: 12px; justify-content: center; }
.module-selector-buttons .cancel-btn { padding: 12px 28px; border: 1px solid #ddd; background: white; border-radius: 99px; font-size: 15px; color: #666; cursor: pointer; transition: all 0.2s; }
.module-selector-buttons .cancel-btn:hover { background: #f5f5f5; }
.module-selector-buttons .confirm-btn { padding: 12px 28px; border: none; background: var(--primary); border-radius: 99px; font-size: 15px; color: white; font-weight: 600; cursor: pointer; box-shadow: 0 4px 12px rgba(7, 193, 96, 0.3); transition: all 0.2s; }
.module-selector-buttons .confirm-btn:hover { transform: translateY(-2px); box-shadow: 0 6px 16px rgba(7, 193, 96, 0.4); }

.emoji-thumb {
  width: 72px;
  height: 72px;
  object-fit: contain;
  border-radius: 12px;
  background: #FFFFFF;
  border: 1px solid var(--line-color);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.06);
  margin-bottom: 8px;
}

.info-value .highlight {
  color: var(--primary);
  font-size: 36px;
}

.info-value .sub-highlight {
  color: #666;
  font-size: 18px;
  font-weight: 400;
}

.conversation-box {
  background: #F3F3F3;
  border-radius: 16px;
  padding: 20px;
  margin-top: 24px;
}

.message-bubble {
  background: #FFFFFF;
  border-radius: 12px;
  padding: 16px 20px;
  margin-bottom: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.message-bubble:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 18px rgba(0, 0, 0, 0.08);
}

.message-bubble:last-child {
  margin-bottom: 0;
}

.message-sender {
  font-size: 14px;
  color: var(--primary);
  font-weight: 700;
  margin-bottom: 8px;
}

.message-content {
  font-size: 16px;
  color: var(--text-main);
  line-height: 1.6;
}

@media (max-width: 768px) {
  section.page {
    padding: 60px 24px;
  }

  .hero-title {
    font-size: 40px;
  }

  .hero-names {
    font-size: 28px;
  }

  .info-value .highlight {
    font-size: 28px;
  }
}

@media (prefers-reduced-motion: reduce) {
  * { animation-duration: 0.001ms !important; animation-iteration-count: 1 !important; transition-duration: 0.001ms !important; scroll-behavior: auto !important; }
  .main-container { scroll-snap-type: none; }
}

.word-cloud-container {
  display: flex;
  flex-wrap: wrap;
  gap: 10px 12px;
  justify-content: center;
  align-items: center;
  align-content: center;
  padding: 26px 28px;
  background: linear-gradient(135deg, rgba(255,255,255,0.95), rgba(249,249,249,0.92));
  border-radius: 20px;
  margin: 20px auto 0;
  border: 1px solid var(--line-color);
  box-shadow: 0 10px 24px rgba(0, 0, 0, 0.05);
  max-width: 920px;
  min-height: 120px;
}

.word-cloud-wrapper {
  margin: 16px auto 0;
  padding: 0;
  border: none;
  box-shadow: none;
  max-width: 920px;
  display: flex;
  justify-content: center;
  --cloud-scale: clamp(0.72, 80vw / 520, 1);
}

.word-cloud-inner {
  position: relative;
  width: 520px;
  height: 520px;
  margin: 0;
  border-radius: 50%;
  transform: scale(var(--cloud-scale));
  transform-origin: center;
}

.word-cloud-inner::before {
  content: "";
  position: absolute;
  inset: -6%;
  background:
    radial-gradient(circle at 35% 45%, rgba(7, 193, 96, 0.12), transparent 55%),
    radial-gradient(circle at 65% 50%, rgba(242, 170, 0, 0.1), transparent 58%),
    radial-gradient(circle at 50% 65%, rgba(0, 0, 0, 0.04), transparent 60%);
  filter: blur(18px);
  border-radius: 50%;
  pointer-events: none;
  z-index: 0;
}

.word-tag {
  display: inline-block;
  padding: 0;
  background: transparent;
  border-radius: 0;
  border: none;
  line-height: 1.2;
  white-space: nowrap;
  transition: transform 0.2s ease, color 0.2s ease;
  cursor: default;
  color: #2F3437;
  font-weight: 600;
  text-shadow: none;
  opacity: 0;
  animation: popIn 0.55s ease forwards;
  position: absolute;
  z-index: 1;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%) scale(0.8);
}

.word-tag:hover {
  transform: translate(-50%, -50%) scale(1.08);
  color: var(--primary);
  z-index: 2;
  opacity: 1;
}

.top-phrases-title {
  font-size: 14px;
  color: #888;
  margin-bottom: 12px;
  letter-spacing: 1px;
}

.top-phrases-list {
  display: flex;
  justify-content: center;
  gap: 8px;
  flex-wrap: wrap;
}

.word-cloud-note {
  margin-top: 16px;
  font-size: 13px;
  color: #999;
  text-align: center;
}

.top-phrases-container {
  margin: 14px auto 0;
  padding: 8px 0;
  background: transparent;
  border-radius: 0;
  border: none;
  max-width: 920px;
  text-align: center;
}

.top-badge {
  background: #F0F2F5;
  color: #555;
  padding: 4px 12px;
  border-radius: 999px;
  font-size: 13px;
  font-weight: 600;
  border: 1px solid rgba(0, 0, 0, 0.06);
}

.top-badge:first-child {
  background: #E7F9F0;
  color: #07C160;
  border-color: rgba(7, 193, 96, 0.4);
}

@keyframes popIn {
  0% {
    opacity: 0;
    transform: translate(-50%, -50%) scale(0.6);
  }
  100% {
    opacity: var(--final-opacity, 1);
    transform: translate(-50%, -50%) scale(1);
  }
}
''';
  }

  /// 构建封面
  static String _buildCoverBody(String myName, String friendName) {
    final escapedMyName = _escapeHtml(myName);
    final escapedFriendName = _escapeHtml(friendName);
    return '''
<div class="label-text">ECHO TRACE · DUAL REPORT</div>
<div class="hero-names">
  <span class="name">$escapedMyName</span>
  <span class="ampersand">&</span>
  <span class="name">$escapedFriendName</span>
</div>
<hr class="divider">
<div class="hero-desc">每一段对话<br>都是独一无二的相遇<br><br>让我们一起回顾<br>那些珍贵的聊天时光</div>
''';
  }

  /// 构建第一次聊天部分
  static String _buildFirstChatBody(
    Map<String, dynamic>? firstChat,
    Map<String, dynamic>? thisYearFirstChat,
    String myName,
    String friendName,
  ) {
    if (firstChat == null) {
      return '''
<div class="label-text">第一次聊天</div>
<div class="hero-title">暂无数据</div>
''';
    }

    final firstDate = DateTime.fromMillisecondsSinceEpoch(firstChat['createTime'] as int);
    final daysSince = DateTime.now().difference(firstDate).inDays;

    String thisYearSection = '';
    if (thisYearFirstChat != null) {
      final initiator = thisYearFirstChat['isSentByMe'] == true ? myName : friendName;
      final messages = thisYearFirstChat['firstThreeMessages'] as List<dynamic>?;

      String messagesHtml = '';
      if (messages != null && messages.isNotEmpty) {
        messagesHtml = messages.map((msg) {
          final sender = msg['isSentByMe'] == true ? myName : friendName;
          final content = _escapeHtml(msg['content'].toString());
          final timeStr = msg['createTimeStr']?.toString() ?? '';
          return '''
<div class="message-bubble">
  <div class="message-sender">$sender · $timeStr</div>
  <div class="message-content">$content</div>
</div>
''';
        }).join();
      }

      thisYearSection = '''
<div class="info-card">
  <div class="info-label">今年第一段对话</div>
  <div class="info-value">
    由 <span class="highlight">${_escapeHtml(initiator)}</span> 发起
  </div>
  <div class="info-label">前三句对话</div>
  <div class="conversation-box">
    $messagesHtml
  </div>
</div>
''';
    }

    return '''
<div class="label-text">第一次聊天</div>
<div class="hero-title">故事的开始</div>
<div class="info-card">
  <div class="info-label">我们第一次聊天在</div>
  <div class="info-value">
    <span class="highlight">${firstDate.year}年${firstDate.month}月${firstDate.day}日</span>
  </div>
  <div class="info-label">距今已有</div>
  <div class="info-value">
    <span class="highlight">$daysSince</span> <span class="sub-highlight">天</span>
  </div>
</div>
$thisYearSection
''';
  }

  /// 构建年度统计部分
  static String _buildYearlyStatsBody(
    Map<String, dynamic>? yearlyStats,
    String myName,
    String friendName,
    int? year,
  ) {
    final yearText = year != null ? '${year}年' : '历史以来';
    final sectionLabel = year != null ? '年度统计' : '历史统计';
    if (yearlyStats == null) {
      return '''
<div class="label-text">$sectionLabel</div>
<div class="hero-title">暂无数据</div>
''';
    }

    final totalMessages = yearlyStats['totalMessages'] as int? ?? 0;
    final totalWords = yearlyStats['totalWords'] as int? ?? 0;
    final imageCount = yearlyStats['imageCount'] as int? ?? 0;
    final voiceCount = yearlyStats['voiceCount'] as int? ?? 0;
    final emojiCount = yearlyStats['emojiCount'] as int? ?? 0;
    final myTopEmojiMd5 = yearlyStats['myTopEmojiMd5'] as String?;
    final friendTopEmojiMd5 = yearlyStats['friendTopEmojiMd5'] as String?;
    final myTopEmojiDataUrl = yearlyStats['myTopEmojiDataUrl'] as String?;
    final friendTopEmojiDataUrl =
        yearlyStats['friendTopEmojiDataUrl'] as String?;

    String formatEmojiMd5(String? md5) {
      if (md5 == null || md5.isEmpty) return '暂无';
      return md5;
    }

    String buildEmojiBlock(String? dataUrl, String? md5) {
      if (dataUrl == null || dataUrl.isEmpty) {
        final label = _escapeHtml(formatEmojiMd5(md5));
        return '<div class="info-value info-value-sm">$label</div>';
      }
      final safeUrl = _escapeHtml(dataUrl);
      return '''
<img class="emoji-thumb" src="$safeUrl" alt="" loading="lazy" decoding="async" />
''';
    }


    return '''
<div class="label-text">$sectionLabel</div>
<div class="hero-title">${_escapeHtml(myName)} & ${_escapeHtml(friendName)}的$yearText</div>
<div class="info-card">
  <div class="info-label">一共发出</div>
  <div class="info-value">
    <span class="highlight">${_formatNumber(totalMessages)}</span> <span class="sub-highlight">条消息</span>
  </div>
  <div class="info-label">总计</div>
  <div class="info-value">
    <span class="highlight">${_formatNumber(totalWords)}</span> <span class="sub-highlight">字</span>
  </div>
  <div class="info-label">图片</div>
  <div class="info-value">
    <span class="highlight">${_formatNumber(imageCount)}</span> <span class="sub-highlight">张</span>
  </div>
  <div class="info-label">语音</div>
  <div class="info-value">
    <span class="highlight">${_formatNumber(voiceCount)}</span> <span class="sub-highlight">条</span>
  </div>
  <div class="info-row">
    <div class="info-item">
      <div class="info-label">表情包</div>
      <div class="info-value">
        <span class="highlight">${_formatNumber(emojiCount)}</span> <span class="sub-highlight">张</span>
      </div>
    </div>
    <div class="info-item">
      <div class="info-label">我最常用的表情包</div>
      ${buildEmojiBlock(myTopEmojiDataUrl, myTopEmojiMd5)}
    </div>
    <div class="info-item">
      <div class="info-label">${_escapeHtml(friendName)}常用的表情包</div>
      ${buildEmojiBlock(friendTopEmojiDataUrl, friendTopEmojiMd5)}
    </div>
  </div>
</div>
''';
  }

  static String _buildMessageBalanceBody(
    int totalMessages,
    int sentMessages,
    int receivedMessages,
    String myName,
    String friendName,
    int? year,
  ) {
    final yearText = year != null ? '${year}年' : '历史以来';
    final safeMyName = _escapeHtml(myName);
    final safeFriendName = _escapeHtml(friendName);
    final total = totalMessages > 0
        ? totalMessages
        : sentMessages + receivedMessages;

    if (total == 0) {
      return '''
<div class="label-text">对话占比</div>
<div class="hero-title">暂无数据</div>
''';
    }

    final hasSplit = sentMessages > 0 || receivedMessages > 0;
    final myPct = total > 0 ? (sentMessages / total * 100).clamp(0, 100) : 0.0;
    final friendPct =
        total > 0 ? (receivedMessages / total * 100).clamp(0, 100) : 0.0;
    final myPctText = myPct.toStringAsFixed(1);
    final friendPctText = friendPct.toStringAsFixed(1);

    if (!hasSplit) {
      return '''
<div class="label-text">对话占比</div>
<div class="hero-title">$yearText 你们的对话</div>
<div class="info-card">
  <div class="info-label">共交换</div>
  <div class="info-value">
    <span class="highlight">${_formatNumber(total)}</span> <span class="sub-highlight">条消息</span>
  </div>
  <div class="info-label">发送/接收占比暂不可用</div>
</div>
''';
    }

    return '''
<div class="label-text">对话占比</div>
<div class="hero-title">$yearText 你们的对话分工</div>
<div class="info-card">
  <div class="info-row">
    <div class="info-item">
      <div class="info-label">$safeMyName 发出</div>
      <div class="info-value">
        <span class="highlight">${_formatNumber(sentMessages)}</span> <span class="sub-highlight">条</span>
      </div>
    </div>
    <div class="info-item">
      <div class="info-label">$safeFriendName 发来</div>
      <div class="info-value">
        <span class="highlight">${_formatNumber(receivedMessages)}</span> <span class="sub-highlight">条</span>
      </div>
    </div>
  </div>
  <div class="ratio-bar">
    <div class="ratio-fill" style="width: $myPctText%;"></div>
  </div>
  <div class="ratio-legend">$safeMyName $myPctText% · $safeFriendName $friendPctText%</div>
</div>
<div class="hero-desc">共 ${_formatNumber(total)} 条消息</div>
''';
  }

  static String _buildRhythmBody(
    Map<String, dynamic>? rhythmStats,
    List<Map<String, dynamic>> monthlyCounts,
    String myName,
    String friendName,
    int? year,
  ) {
    final yearText = year != null ? '${year}年' : '历史以来';
    if (rhythmStats == null) {
      return '''
<div class="label-text">聊天节奏</div>
<div class="hero-title">暂无数据</div>
''';
    }

    final activeDays = _parseInt(rhythmStats['activeDays']);
    final avgRaw = rhythmStats['avgPerActiveDay'];
    final avgPerActiveDay = avgRaw is num ? avgRaw.toDouble() : 0.0;
    final busiestMonth = _parseInt(rhythmStats['busiestMonth']);
    final busiestMonthCount = _parseInt(rhythmStats['busiestMonthCount']);
    final longestStreakDays = _parseInt(rhythmStats['longestStreakDays']);
    final longestGapDays = _parseInt(rhythmStats['longestGapDays']);

    final streakStart = _formatDate(rhythmStats['streakStart']?.toString());
    final streakEnd = _formatDate(rhythmStats['streakEnd']?.toString());
    final gapStart = _formatDate(rhythmStats['gapStart']?.toString());
    final gapEnd = _formatDate(rhythmStats['gapEnd']?.toString());

    final sortedMonths = List<Map<String, dynamic>>.from(monthlyCounts)
      ..sort((a, b) {
        final countA = _parseInt(a['count']);
        final countB = _parseInt(b['count']);
        return countB.compareTo(countA);
      });

    final hasMonthlyData = monthlyCounts.any(
      (item) => _parseInt(item['count']) > 0,
    );
    final hasAnyData =
        activeDays > 0 || busiestMonthCount > 0 || hasMonthlyData;
    if (!hasAnyData) {
      return '''
<div class="label-text">聊天节奏</div>
<div class="hero-title">暂无数据</div>
''';
    }

    final topMonths = sortedMonths.take(4).map((item) {
      final month = _parseInt(item['month']);
      final count = _parseInt(item['count']);
      if (month == 0 || count == 0) return '';
      return '<span class="month-badge">$month月 · ${_formatNumber(count)}条</span>';
    }).where((item) => item.isNotEmpty).join();

    final busiestMonthText =
        busiestMonth > 0 && busiestMonthCount > 0
            ? '${busiestMonth}月 · ${_formatNumber(busiestMonthCount)}条'
            : '暂无';

    final streakText = longestStreakDays > 0
        ? '${_formatNumber(longestStreakDays)} 天 ($streakStart - $streakEnd)'
        : '暂无';
    final gapText = longestGapDays > 0
        ? '${_formatNumber(longestGapDays)} 天 ($gapStart - $gapEnd)'
        : '暂无';

    return '''
<div class="label-text">聊天节奏</div>
<div class="hero-title">$yearText 你们的节拍</div>
<div class="info-card">
  <div class="info-row">
    <div class="info-item">
      <div class="info-label">活跃天数</div>
      <div class="info-value">
        <span class="highlight">${_formatNumber(activeDays)}</span> <span class="sub-highlight">天</span>
      </div>
    </div>
    <div class="info-item">
      <div class="info-label">平均每个活跃日</div>
      <div class="info-value">
        <span class="highlight">${avgPerActiveDay.toStringAsFixed(1)}</span> <span class="sub-highlight">条</span>
      </div>
    </div>
    <div class="info-item">
      <div class="info-label">最热月份</div>
      <div class="info-value info-value-sm">$busiestMonthText</div>
    </div>
  </div>
  ${topMonths.isNotEmpty ? '<div class="month-badges">$topMonths</div>' : ''}
</div>
<div class="info-card">
  <div class="info-row">
    <div class="info-item">
      <div class="info-label">最长连聊</div>
      <div class="info-value info-value-sm">$streakText</div>
    </div>
    <div class="info-item">
      <div class="info-label">最长空窗</div>
      <div class="info-value info-value-sm">$gapText</div>
    </div>
  </div>
</div>
''';
  }

  static String _buildEndingBody(String myName, String friendName) {
    final safeMyName = _escapeHtml(myName);
    final safeFriendName = _escapeHtml(friendName);
    return '''
<div class="label-text">保存记录</div>
<div class="hero-title">把这段故事收好</div>
<div class="hero-desc">$safeMyName 与 $safeFriendName 的对话，值得被珍藏。</div>
<div class="export-actions">
  <button class="capture-btn" onclick="takeScreenshot()">生成双人长图报告</button>
  <button class="capture-btn module-btn" onclick="takeModuleScreenshots()">分模块导出图片</button>
</div>
''';
  }

  static String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  static String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '-';
    return value.split('T').first;
  }

  /// HTML转义
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// 构建词云部分
  static String _buildWordCloudBody(
    Map<String, dynamic>? wordCloudData,
    String myName,
    String friendName,
    int? year,
  ) {
    final yearText = year != null ? '${year}年' : '历史以来';

    if (wordCloudData == null) {
      return _buildWordCloudEmptyState();
    }

    final words = (wordCloudData['words'] as List?) ?? [];

    if (words.isEmpty) {
      return _buildWordCloudEmptyState();
    }

    // 获取最大频率用于计算字体大小
    final maxCount = words.isNotEmpty
        ? ((words.first as Map)['count'] as int? ?? 1)
        : 1;

    final topWords = words.take(32).toList();
    final rng = Random(42);
    final placed = <Map<String, double>>[];
    const baseSize = 520.0;

    bool canPlace(double x, double y, double w, double h) {
      final halfW = w / 2;
      final halfH = h / 2;
      final dx = x - 50;
      final dy = y - 50;
      final dist = sqrt(dx * dx + dy * dy);
      final maxR = 49 - max(halfW, halfH);
      if (dist > maxR) return false;
      const pad = 1.8;
      for (final p in placed) {
        final px = p['x']!;
        final py = p['y']!;
        final pw = p['w']!;
        final ph = p['h']!;
        if ((x - halfW - pad) < (px + pw / 2) &&
            (x + halfW + pad) > (px - pw / 2) &&
            (y - halfH - pad) < (py + ph / 2) &&
            (y + halfH + pad) > (py - ph / 2)) {
          return false;
        }
      }
      return true;
    }

    // 构建词云标签（显示前32个，避免重叠）
    final wordItems = <String>[];
    for (var i = 0; i < topWords.length; i++) {
      final item = topWords[i];
      final rawWord = item['word']?.toString() ?? '';
      final sentence = _escapeHtml(rawWord);
      final count = (item['count'] as int?) ?? 1;

      // 根据频率计算字体大小 (12px - 32px)
      final ratio = count / maxCount;
      final fontSize = (12 + pow(ratio, 0.65) * 20).round();
      final opacity = (0.35 + ratio * 0.65).clamp(0.35, 1.0);
      final delay = (i * 0.04).toStringAsFixed(2);

      final charCount = max(1, rawWord.runes.length);
      final hasCjk = RegExp(r'[\u4e00-\u9fff]').hasMatch(rawWord);
      final hasLatin = RegExp(r'[A-Za-z0-9]').hasMatch(rawWord);
      final widthFactor = hasCjk && hasLatin
          ? 0.85
          : hasCjk
              ? 0.98
              : 0.6;
      final widthPx = fontSize * (charCount * widthFactor);
      final heightPx = fontSize * 1.1;
      final widthPct = (widthPx / baseSize) * 100;
      final heightPct = (heightPx / baseSize) * 100;

      double x = 50;
      double y = 50;
      bool placedOk = false;
      final tries = i == 0 ? 1 : 420;
      for (var t = 0; t < tries; t++) {
        if (i == 0) {
          x = 50;
          y = 50;
        } else {
          final idx = i + t * 0.28;
          final radius = sqrt(idx) * 7.6 + (rng.nextDouble() * 1.2 - 0.6);
          final angle = idx * 2.399963 + rng.nextDouble() * 0.35;
          x = 50 + radius * cos(angle);
          y = 50 + radius * sin(angle);
        }
        if (canPlace(x, y, widthPct, heightPct)) {
          placedOk = true;
          break;
        }
      }
      if (!placedOk) continue;
      placed.add({'x': x, 'y': y, 'w': widthPct, 'h': heightPct});

      wordItems.add('''
<span class="word-tag" style="--final-opacity: $opacity; left: ${x.toStringAsFixed(2)}%; top: ${y.toStringAsFixed(2)}%; font-size: ${fontSize}px; animation-delay: ${delay}s;" title="出现 $count 次">$sentence</span>''');
    }

    // 获取前3个高频句子
    final topThree = topWords
        .take(3)
        .map((item) {
          final sentence = _escapeHtml((item as Map)['word']?.toString() ?? '');
          return '<span class="top-badge">$sentence</span>';
        })
        .join('');

    return '''
<div class="label-text">常用语</div>
<div class="hero-title">独属于你们的秘密</div>
<div class="hero-desc">$yearText，你们说得最多的是：</div>
<div class="word-cloud-wrapper">
  <div class="word-cloud-inner">${wordItems.join()}</div>
</div>
<div class="top-phrases-container">
  <div class="top-phrases-title">你们最爱说的三句话：</div>
  <div class="top-phrases-list">$topThree</div>
</div>
<div class="word-cloud-note">颜色越深代表出现频率越高</div>
''';
  }

  static String _buildWordCloudEmptyState() {
    return '''
<div class="label-text">常用语</div>
<div class="hero-title">暂无数据</div>
<div class="hero-desc">需要足够的文本消息才能生成</div>
''';
  }


  /// 构建section
  static String _buildSection(String className, String content) {
    return '''
<section class="page $className" id="$className">
  <div class="content-wrapper">$content</div>
</section>
''';
  }

  /// 构建JavaScript
  static String _buildScript(String friendName) {
    final friendJson = jsonEncode(friendName);
    return '''
<script>
const moduleNames = {
  'cover': '封面',
  'first-chat': '第一次聊天',
  'word-cloud': '常用语',
  'yearly-stats': '年度统计',
  'message-balance': '对话占比',
  'chat-rhythm': '聊天节奏',
  'ending': '保存记录'
};

document.addEventListener('DOMContentLoaded', function() {
  const sections = document.querySelectorAll('section.page');

  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
      }
    });
  }, { threshold: 0.2 });

  sections.forEach((section) => observer.observe(section));
});

function sanitizeName(name) {
  return name.replace(/[\\\\/:*?"<>|]/g, '_').replace(/\\s+/g, '_');
}

function buildExportFolderName(prefix) {
  const stamp = new Date().toISOString().replace(/[-:]/g, '').replace('T', '_').slice(0, 15);
  return sanitizeName(prefix + '_' + stamp);
}

async function pickExportDirectory(prefix) {
  if (!window.showDirectoryPicker) {
    return { dirHandle: null, canceled: false };
  }
  try {
    const rootHandle = await window.showDirectoryPicker();
    const folderName = buildExportFolderName(prefix);
    const dirHandle = await rootHandle.getDirectoryHandle(folderName, { create: true });
    return { dirHandle, canceled: false };
  } catch (err) {
    if (err && err.name === 'AbortError') {
      return { dirHandle: null, canceled: true };
    }
    throw err;
  }
}

async function saveDataUrlToDirectory(dirHandle, fileName, dataUrl) {
  const response = await fetch(dataUrl);
  const blob = await response.blob();
  const fileHandle = await dirHandle.getFileHandle(fileName, { create: true });
  const writable = await fileHandle.createWritable();
  await writable.write(blob);
  await writable.close();
}

function hideCaptureButtons() {
  const buttons = Array.from(document.querySelectorAll('.capture-btn'));
  return buttons.map(btn => {
    const prev = btn.style.display;
    btn.style.display = 'none';
    return { btn, prev };
  });
}

function restoreCaptureButtons(state) {
  state.forEach(item => {
    item.btn.style.display = item.prev;
  });
}

async function takeScreenshot() {
  const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
  const rawFriend = $friendJson || 'dual';
  const prefix = sanitizeName('dual_report_' + rawFriend);
  const fileName = prefix + '.png';
  let dirInfo = { dirHandle: null, canceled: false };
  if (!isMobile) {
    dirInfo = await pickExportDirectory(prefix);
    if (dirInfo.canceled) {
      return;
    }
  }

  const target = document.getElementById('capture');
  const hiddenButtons = hideCaptureButtons();
  const originalStyle = target.style.cssText;
  target.style.height = 'auto';
  target.style.overflow = 'visible';
  target.style.scrollSnapType = 'none';

  const pages = document.querySelectorAll('section.page');
  pages.forEach(p => {
     p.dataset.wasVisible = p.classList.contains('visible') ? '1' : '0';
     p.classList.add('visible');
     p.dataset.originalStyle = p.style.cssText;
     p.style.minHeight = 'auto';
     p.style.height = 'auto';
     p.style.paddingBottom = '60px';
     const wrapper = p.querySelector('.content-wrapper');
     if(wrapper) {
       wrapper.dataset.originalStyle = wrapper.style.cssText;
       wrapper.style.opacity = '1';
       wrapper.style.transform = 'translateY(0)';
       wrapper.style.animation = 'none';
     }
  });

  try {
    await new Promise(resolve => setTimeout(resolve, 80));
    const sections = Array.from(pages);
    const TARGET_WIDTH = 1920;
    const BG_COLOR = '#F9F8F6';
    const captured = [];
    let totalHeight = 0;

    for (let i = 0; i < sections.length; i++) {
      const section = sections[i];
      const sectionStyle = section.style.cssText;
      section.style.width = (TARGET_WIDTH / 2) + 'px';
      section.style.minHeight = 'auto';
      section.style.height = 'auto';
      section.style.paddingTop = '60px';
      section.style.paddingBottom = '60px';
      section.style.boxSizing = 'border-box';

      const wrapper = section.querySelector('.content-wrapper');
      const wrapperOriginal = wrapper ? wrapper.style.cssText : '';
      if (wrapper) {
        wrapper.style.opacity = '1';
        wrapper.style.transform = 'translateY(0)';
        wrapper.style.animation = 'none';
        wrapper.style.maxWidth = '100%';
      }

      await new Promise(resolve => setTimeout(resolve, 60));

      const contentCanvas = await html2canvas(section, {
        scale: 2,
        useCORS: true,
        backgroundColor: BG_COLOR,
        allowTaint: true,
        logging: false,
        width: TARGET_WIDTH / 2,
      });

      const scale = TARGET_WIDTH / contentCanvas.width;
      const drawHeight = Math.ceil(contentCanvas.height * scale);
      captured.push({ canvas: contentCanvas, drawHeight });
      totalHeight += drawHeight;

      section.style.cssText = sectionStyle;
      if (wrapper) wrapper.style.cssText = wrapperOriginal;
    }

    const finalCanvas = document.createElement('canvas');
    finalCanvas.width = TARGET_WIDTH;
    finalCanvas.height = totalHeight;
    const ctx = finalCanvas.getContext('2d');
    ctx.fillStyle = BG_COLOR;
    ctx.fillRect(0, 0, TARGET_WIDTH, totalHeight);

    let offsetY = 0;
    for (let i = 0; i < captured.length; i++) {
      const item = captured[i];
      ctx.drawImage(item.canvas, 0, offsetY, TARGET_WIDTH, item.drawHeight);
      offsetY += item.drawHeight;
    }

    const imgData = finalCanvas.toDataURL('image/png');

    if (!isMobile) {
      if (dirInfo.dirHandle) {
        await saveDataUrlToDirectory(dirInfo.dirHandle, fileName, imgData);
        alert('双人报告已保存到所选目录！');
      } else {
        const link = document.createElement('a');
        link.download = fileName;
        link.href = imgData;
        link.click();
        alert('双人报告已生成并下载！');
      }
    } else {
      alert('请在桌面浏览器中生成长图，以便保存到目录');
    }
  } catch (err) {
    console.error(err);
    alert('生成失败：' + err.message);
  } finally {
    cleanup();
  }

  function cleanup() {
    restoreCaptureButtons(hiddenButtons);
    target.style.cssText = originalStyle;
    pages.forEach(p => {
       if (p.dataset.originalStyle !== undefined) {
         p.style.cssText = p.dataset.originalStyle;
         delete p.dataset.originalStyle;
       } else {
         p.style.minHeight = '100vh';
         p.style.height = '';
         p.style.paddingBottom = '';
       }
       if (p.dataset.wasVisible === '1') {
         p.classList.add('visible');
       } else {
         p.classList.remove('visible');
       }
       delete p.dataset.wasVisible;
       const wrapper = p.querySelector('.content-wrapper');
       if (wrapper && wrapper.dataset.originalStyle !== undefined) {
         wrapper.style.cssText = wrapper.dataset.originalStyle;
         delete wrapper.dataset.originalStyle;
       }
    });
  }
}

function showModuleSelector() {
  const sections = document.querySelectorAll('section.page');
  const sectionIds = Array.from(sections).map(s => s.id);

  const modal = document.createElement('div');
  modal.className = 'module-selector-modal';
  modal.innerHTML = \`
    <div class="module-selector-content">
      <h3>选择要导出的模块</h3>
      <div class="module-selector-actions" style="margin-bottom: 16px;">
        <button type="button" onclick="toggleAllModules(true)" class="select-action-btn">全选</button>
        <button type="button" onclick="toggleAllModules(false)" class="select-action-btn">全不选</button>
      </div>
      <div class="module-list">
        \${sectionIds.map((id, index) => \`
          <label class="module-item">
            <input type="checkbox" value="\${id}" checked>
            <span>\${(index + 1).toString().padStart(2, '0')}. \${moduleNames[id] || id}</span>
          </label>
        \`).join('')}
      </div>
      <div class="module-selector-buttons">
        <button type="button" onclick="closeModuleSelector()" class="cancel-btn">取消</button>
        <button type="button" onclick="startModuleExport()" class="confirm-btn">开始导出</button>
      </div>
    </div>
  \`;
  document.body.appendChild(modal);

  window.toggleAllModules = (checked) => {
    modal.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.checked = checked);
  };

  window.closeModuleSelector = () => {
    modal.remove();
    delete window.toggleAllModules;
    delete window.closeModuleSelector;
    delete window.startModuleExport;
  };

  window.startModuleExport = async () => {
    const selectedIds = Array.from(modal.querySelectorAll('input[type="checkbox"]:checked')).map(cb => cb.value);
    modal.remove();
    delete window.toggleAllModules;
    delete window.closeModuleSelector;
    delete window.startModuleExport;

    if (selectedIds.length === 0) {
      alert('请至少选择一个模块');
      return;
    }

    const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    let dirInfo = { dirHandle: null, canceled: false };
    if (!isMobile) {
      const rawFriend = $friendJson || 'dual';
      const prefix = sanitizeName('dual_report_' + rawFriend + '_modules');
      dirInfo = await pickExportDirectory(prefix);
      if (dirInfo.canceled) {
        return;
      }
    }

    await exportSelectedModules(selectedIds, dirInfo, isMobile);
  };
}

async function takeModuleScreenshots() {
  showModuleSelector();
}

async function exportSelectedModules(selectedIds, dirInfo, isMobile) {
  const allSections = document.querySelectorAll('section.page');
  const sections = Array.from(allSections).filter(s => selectedIds.includes(s.id));
  const allBtns = document.querySelectorAll('.capture-btn');
  allBtns.forEach(btn => btn.disabled = true);

  const progressDiv = document.createElement('div');
  progressDiv.className = 'module-progress';
  progressDiv.innerHTML = '<h3>正在生成模块图片</h3><div class="progress-bar"><div class="progress-fill" style="width: 0%"></div></div><div class="progress-text">准备中...</div>';
  document.body.appendChild(progressDiv);

  const progressFill = progressDiv.querySelector('.progress-fill');
  const progressText = progressDiv.querySelector('.progress-text');

  const images = [];
  const total = sections.length;
  const TARGET_WIDTH = 1920;
  const TARGET_HEIGHT = 1080;
  const BG_COLOR = '#F9F8F6';

  try {
    for (let i = 0; i < total; i++) {
      const section = sections[i];
      const sectionId = section.id;
      const wasVisible = section.classList.contains('visible');
      section.dataset.wasVisible = wasVisible ? '1' : '0';
      section.classList.add('visible');
      const moduleIndex = selectedIds.indexOf(sectionId) + 1;
      const moduleName = moduleIndex.toString().padStart(2, '0') + '_' + (moduleNames[sectionId] || sectionId);

      progressText.textContent = '正在处理: ' + (moduleNames[sectionId] || sectionId) + ' (' + (i + 1) + '/' + total + ')';
      progressFill.style.width = ((i / total) * 100) + '%';

      const originalStyle = section.style.cssText;
      section.style.width = (TARGET_WIDTH / 2) + 'px';
      section.style.minHeight = 'auto';
      section.style.height = 'auto';
      section.style.paddingTop = '60px';
      section.style.paddingBottom = '60px';
      section.style.boxSizing = 'border-box';

      const wrapper = section.querySelector('.content-wrapper');
      const wrapperOriginalStyle = wrapper ? wrapper.style.cssText : '';
      if(wrapper) {
        wrapper.style.opacity = '1';
        wrapper.style.transform = 'translateY(0)';
        wrapper.style.animation = 'none';
        wrapper.style.maxWidth = '100%';
      }

      const buttons = section.querySelectorAll('.capture-btn');
      buttons.forEach(btn => btn.style.display = 'none');

      await new Promise(resolve => setTimeout(resolve, 100));

      const contentCanvas = await html2canvas(section, {
        scale: 2,
        useCORS: true,
        backgroundColor: BG_COLOR,
        allowTaint: true,
        logging: false,
        width: TARGET_WIDTH / 2,
      });

      const finalCanvas = document.createElement('canvas');
      finalCanvas.width = TARGET_WIDTH;
      finalCanvas.height = TARGET_HEIGHT;
      const ctx = finalCanvas.getContext('2d');

      ctx.fillStyle = BG_COLOR;
      ctx.fillRect(0, 0, TARGET_WIDTH, TARGET_HEIGHT);

      const contentHeight = contentCanvas.height;
      const contentWidth = contentCanvas.width;
      let drawWidth = contentWidth;
      let drawHeight = contentHeight;
      let scale = 1;
      const scaleX = TARGET_WIDTH / contentWidth;
      const scaleY = TARGET_HEIGHT / contentHeight;
      scale = Math.min(scaleX, scaleY, 1);
      if (scale < 1) {
        drawWidth = contentWidth * scale;
        drawHeight = contentHeight * scale;
      }
      const x = (TARGET_WIDTH - drawWidth) / 2;
      const y = (TARGET_HEIGHT - drawHeight) / 2;
      ctx.drawImage(contentCanvas, x, y, drawWidth, drawHeight);

      section.style.cssText = originalStyle;
      if(wrapper) wrapper.style.cssText = wrapperOriginalStyle;
      buttons.forEach(btn => btn.style.display = '');
      if (section.dataset.wasVisible === '1') {
        section.classList.add('visible');
      } else {
        section.classList.remove('visible');
      }
      delete section.dataset.wasVisible;

      images.push({
        name: moduleName + '.png',
        data: finalCanvas.toDataURL('image/png')
      });
    }

    progressText.textContent = '正在打包导出...';
    progressFill.style.width = '100%';

    if (isMobile) {
      progressDiv.remove();
      await showMobileImages(images);
    } else {
      if (dirInfo.dirHandle) {
        for (let i = 0; i < images.length; i++) {
          const img = images[i];
          await saveDataUrlToDirectory(dirInfo.dirHandle, img.name, img.data);
        }
        progressDiv.remove();
        alert('已成功导出 ' + images.length + ' 张模块图片到所选目录！\\n\\n图片尺寸: 1920x1080');
      } else {
        for (let i = 0; i < images.length; i++) {
          const img = images[i];
          const link = document.createElement('a');
          link.download = img.name;
          link.href = img.data;
          link.click();
          await new Promise(resolve => setTimeout(resolve, 200));
        }
        progressDiv.remove();
        alert('已成功导出 ' + images.length + ' 张模块图片！\\n\\n图片尺寸: 1920x1080');
      }
    }
  } catch (err) {
    console.error(err);
    progressDiv.remove();
    alert('生成失败：' + err.message);
  } finally {
    allBtns.forEach(btn => btn.disabled = false);
  }
}

async function showMobileImages(images) {
  let currentIndex = 0;

  const modal = document.createElement('div');
  modal.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,0.9);z-index:9999;display:flex;flex-direction:column;align-items:center;padding:20px;';

  const updateModal = () => {
    const img = images[currentIndex];
    modal.innerHTML = '<div style="color:white;font-size:14px;margin-bottom:12px;">'+img.name+' ('+(currentIndex+1)+'/'+images.length+')</div><div style="flex:1;overflow:auto;width:100%;display:flex;justify-content:center;"><img src="'+img.data+'" style="max-width:100%;height:auto;border:1px solid #333;"/></div><div style="display:flex;gap:12px;margin-top:16px;"><button onclick="prevModule()" style="padding:10px 20px;border:none;border-radius:8px;background:#555;color:white;cursor:pointer;" '+(currentIndex===0?'disabled':'')+'>上一张</button><button onclick="nextModule()" style="padding:10px 20px;border:none;border-radius:8px;background:var(--primary);color:white;cursor:pointer;">'+(currentIndex===images.length-1?'完成':'下一张')+'</button></div><div style="color:#999;font-size:12px;margin-top:12px;">长按图片保存到相册</div>';
  };

  window.prevModule = () => {
    if(currentIndex > 0) {
      currentIndex--;
      updateModal();
    }
  };

  window.nextModule = () => {
    if(currentIndex < images.length - 1) {
      currentIndex++;
      updateModal();
    } else {
      modal.remove();
      delete window.prevModule;
      delete window.nextModule;
    }
  };

  updateModal();
  document.body.appendChild(modal);
}
</script>
''';
  }
}
