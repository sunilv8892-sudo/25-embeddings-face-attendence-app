import 'package:flutter/material.dart';

import '../database/database_manager.dart';
import '../models/attendance_model.dart';
import '../utils/app_route_observer.dart';
import '../utils/constants.dart';
import '../widgets/animated_background.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with RouteAware {
  late final DatabaseManager _dbManager;
  bool _subscribedToRouteObserver = false;

  int _totalStudents = 0;
  int _presentToday = 0;
  int _totalSessions = 0;

  @override
  void initState() {
    super.initState();
    _dbManager = DatabaseManager();
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_subscribedToRouteObserver) {
      final route = ModalRoute.of(context);
      if (route is PageRoute<dynamic>) {
        appRouteObserver.subscribe(this, route);
        _subscribedToRouteObserver = true;
      }
    }
  }

  @override
  void didPopNext() {
    _loadStats();
  }

  @override
  void dispose() {
    if (_subscribedToRouteObserver) {
      appRouteObserver.unsubscribe(this);
    }
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final today = DateTime.now();
      final students = await _dbManager.getAllStudents();
      final todayRecords = await _dbManager.getAttendanceForDate(today);
      final todaySessions = await _dbManager.getTeacherSessionsByDate(today);

      final presentStudentIds = todayRecords
          .where((record) => record.status == AttendanceStatus.present)
          .map((record) => record.studentId)
          .toSet();

      // Daily session count: if older data has attendance but no explicit
      // teacher session entry, show at least one session for today.
      final effectiveTodaySessions =
          todaySessions.isEmpty && todayRecords.isNotEmpty
          ? 1
          : todaySessions.length;

      if (!mounted) {
        return;
      }

      setState(() {
        _totalStudents = students.length;
        _presentToday = presentStudentIds.length;
        _totalSessions = effectiveTodaySessions;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _totalStudents = 0;
        _presentToday = 0;
        _totalSessions = 0;
      });
    }
  }

  Future<void> _openRouteAndRefresh(BuildContext context, String route) async {
    await Navigator.pushNamed(context, route);
    if (!mounted) {
      return;
    }
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 62,
        title: const Text(
          'FAS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF26B6FF),
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showAboutDialog(context),
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF26B6FF),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 740;
              final horizontalPadding = constraints.maxWidth < 390 ? 12.0 : 16.0;
              final unit = constraints.maxHeight / 100.0;
              final heroHeight = unit * 20;
              final gapAfterHero = unit * 3;
              final statsHeight = unit * 10;
              final gapAfterStats = unit * 3;
              final featuredLabelHeight = unit * 3;
              final gapAfterFeaturedLabel = unit * 2;
              final featuredCardsHeight = unit * 20;
              final gapBetweenSections = unit * 3;
              final toolsLabelHeight = unit * 3;
              final gapAfterToolsLabel = unit * 2;
              final toolsCardsHeight = unit * 30;

              final usedHeight =
                heroHeight +
                gapAfterHero +
                statsHeight +
                gapAfterStats +
                featuredLabelHeight +
                gapAfterFeaturedLabel +
                featuredCardsHeight +
                gapBetweenSections +
                toolsLabelHeight +
                gapAfterToolsLabel +
                toolsCardsHeight;
              final restHeight = (constraints.maxHeight - usedHeight)
                .clamp(0.0, constraints.maxHeight)
                .toDouble();

              return Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 0),
                child: Column(
                  children: [
                    SizedBox(height: heroHeight, child: _buildHeroSection(compact)),
                    SizedBox(height: gapAfterHero),
                    SizedBox(height: statsHeight, child: _buildStatsRow(compact)),
                    SizedBox(height: gapAfterStats),
                    SizedBox(
                      height: featuredLabelHeight,
                      child: _buildSectionLabel('Featured', const Color(0xFF26D7FF), compact),
                    ),
                    SizedBox(height: gapAfterFeaturedLabel),
                    SizedBox(height: featuredCardsHeight, child: _buildFeaturedGrid(compact)),
                    SizedBox(height: gapBetweenSections),
                    SizedBox(
                      height: toolsLabelHeight,
                      child: _buildSectionLabel('More Tools', const Color(0xFFFFB830), compact),
                    ),
                    SizedBox(height: gapAfterToolsLabel),
                    SizedBox(height: toolsCardsHeight, child: _buildToolsGrid(compact)),
                    SizedBox(height: restHeight),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, Color accent, bool compact) {
    return Row(
      children: [
        Container(
          width: compact ? 9 : 10,
          height: compact ? 9 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [accent, accent.withValues(alpha: 0.15)]),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 15 : 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool compact) {
    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      glowColor: const Color(0xFF26D7FF),
      child: Row(
        children: [
          Expanded(
            child: _buildStatChip(
              Icons.groups_rounded,
              '$_totalStudents',
              'Students',
              const Color(0xFF6C63FF),
              compact,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildStatChip(
              Icons.how_to_reg_rounded,
              '$_presentToday',
              'Present',
              const Color(0xFF00E096),
              compact,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildStatChip(
              Icons.calendar_month_rounded,
              '$_totalSessions',
              'Sessions',
              const Color(0xFFFFB830),
              compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String value,
    String label,
    Color accent,
    bool compact,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 8 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 28 : 32,
            height: compact ? 28 : 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.95), accent.withValues(alpha: 0.62)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: compact ? 15 : 16),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 15 : 16,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 8 : 9,
                    color: const Color(0xFFCDD5E0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool compact) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return GlassContainer(
      borderRadius: 26,
      opacity: 0.20,
      padding: EdgeInsets.all(compact ? 10 : 12),
      glowColor: const Color(0xFF6C63FF),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    color: const Color(0xFF26D7FF),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'AI Face\nAttendance',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 22 : 26,
                    height: 0.96,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: compact ? 10 : 11,
                      height: compact ? 10 : 11,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6AFF9C),
                            const Color(0xFF00E096),
                            const Color(0xFF00E096).withValues(alpha: 0.35),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E096).withValues(alpha: 0.65),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: const Color(0xFF26D7FF).withValues(alpha: 0.42),
                            blurRadius: 12,
                            spreadRadius: -1,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFFB830).withValues(alpha: 0.30),
                            blurRadius: 14,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Offline Ready',
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: compact ? 96 : 108,
            height: compact ? 96 : 108,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.22),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/icons/vision_id.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.face_retouching_natural_rounded,
                    size: compact ? 56 : 60,
                    color: const Color(0xFFBFD7FF),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedGrid(bool compact) {
    final items = [
      _ToolItem(
        icon: Icons.person_add_alt_1_rounded,
        title: 'Enroll',
        subtitle: 'Add new student faces',
        c1: const Color(0xFF8B5CFF),
        c2: const Color(0xFF6C63FF),
        route: AppConstants.routeEnroll,
      ),
      _ToolItem(
        icon: Icons.face_retouching_natural_rounded,
        title: 'Attendance',
        subtitle: 'Scan & mark faces',
        c1: const Color(0xFF00D4FF),
        c2: const Color(0xFF00E096),
        route: AppConstants.routeAttendance,
      ),
    ];

    return Row(
      children: [
        Expanded(child: _buildFeatureCard(items[0], compact)),
        SizedBox(width: compact ? 6 : 8),
        Expanded(child: _buildFeatureCard(items[1], compact)),
      ],
    );
  }

  Widget _buildFeatureCard(_ToolItem item, bool compact) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () => _openRouteAndRefresh(context, item.route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [item.c1.withValues(alpha: 0.92), item.c2.withValues(alpha: 0.84)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: item.c1.withValues(alpha: 0.24),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 10 : 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: Colors.white, size: compact ? 20 : 22),
              ),
              SizedBox(width: compact ? 9 : 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: compact ? 14.5 : 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 9.6 : 10.4,
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolsGrid(bool compact) {
    final tools = [
      _ToolItem(
        icon: Icons.mood_rounded,
        title: 'Expression',
        subtitle: 'Emotions AI',
        c1: const Color(0xFFFFB830),
        c2: const Color(0xFFFF7043),
        route: AppConstants.routeExpressionDetection,
      ),
      _ToolItem(
        icon: Icons.download_rounded,
        title: 'Export',
        subtitle: 'Reports',
        c1: const Color(0xFF00D4FF),
        c2: const Color(0xFF00A8E8),
        route: AppConstants.routeExport,
      ),
      _ToolItem(
        icon: Icons.tune_rounded,
        title: 'Settings',
        subtitle: 'Configure',
        c1: const Color(0xFF6C63FF),
        c2: const Color(0xFF9B59F5),
        route: AppConstants.routeSettings,
      ),
      _ToolItem(
        icon: Icons.storage_rounded,
        title: 'Database',
        subtitle: 'Manage data',
        c1: const Color(0xFF00E096),
        c2: const Color(0xFF00A878),
        route: AppConstants.routeDatabase,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // 3-scale gap of the full screen equals ~10% of this 30-scale tools block.
        final mainAxisSpacing = (constraints.maxHeight * 0.10)
            .clamp(compact ? 16.0 : 18.0, compact ? 26.0 : 30.0)
            .toDouble();
        final crossAxisSpacing = compact ? 6.0 : 7.0;
        final tileHeight =
            ((constraints.maxHeight - mainAxisSpacing) / 2)
                .clamp(compact ? 54.0 : 58.0, compact ? 66.0 : 72.0)
                .toDouble();

        return GridView.builder(
          itemCount: tools.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisExtent: tileHeight,
          ),
          itemBuilder: (context, index) {
            return _buildToolCard(tools[index]);
          },
        );
      },
    );
  }

  Widget _buildToolCard(_ToolItem tool) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () => _openRouteAndRefresh(context, tool.route),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF101B33),
                tool.c1.withValues(alpha: 0.10),
                const Color(0xFF111B2F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tool.c1.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.26),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tool.c1, tool.c2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(tool.icon, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.subtitle,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF9FB0C8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: tool.c1, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('About FAS'),
        content: const Text(
          'AI-powered face recognition system for seamless attendance tracking. Works completely offline with high accuracy and real-time detection.\n\nSupervised by: Shivaprasad D L\nDeveloped by: V Sunil',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ToolItem {
  const _ToolItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.c1,
    required this.c2,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color c1;
  final Color c2;
  final String route;
}
