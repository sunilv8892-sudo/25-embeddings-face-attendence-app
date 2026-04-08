import 'package:flutter/material.dart';

import '../database/database_manager.dart';
import '../models/attendance_model.dart';
import '../utils/constants.dart';
import '../widgets/animated_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DatabaseManager _dbManager;

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
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final students = await _dbManager.getAllStudents();
      final todayRecords = await _dbManager.getAttendanceForDate(DateTime.now());
      final attendance = await _dbManager.getAllAttendance();

      final presentStudentIds = todayRecords
          .where((record) => record.status == AttendanceStatus.present)
          .map((record) => record.studentId)
          .toSet();

      final uniqueSessions = attendance
          .map((record) => DateTime(record.date.year, record.date.month, record.date.day))
          .toSet()
          .length;

      if (!mounted) {
        return;
      }

      setState(() {
        _totalStudents = students.length;
        _presentToday = presentStudentIds.length;
        _totalSessions = uniqueSessions;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(7),
                child: Image.asset('assets/icons/vision_id.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AI face attendance',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Color(0xFF00E096)),
                SizedBox(width: 6),
                Text(
                  'System Ready',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () => _showAboutDialog(context),
              icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF00D4FF), size: 22),
            ),
          ),
        ],
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(context),
                const SizedBox(height: 16),
                _buildStatsRow(),
                const SizedBox(height: 20),
                _buildSectionLabel('Featured', const Color(0xFF00D4FF)),
                const SizedBox(height: 12),
                _buildFeaturedGrid(context),
                const SizedBox(height: 20),
                _buildSectionLabel('Power Tools', const Color(0xFFFFB830)),
                const SizedBox(height: 12),
                _buildToolsGrid(context),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, Color accent) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      glowColor: const Color(0xFF00D4FF),
      child: Row(
        children: [
          Expanded(child: _buildStatChip(Icons.groups_rounded, '$_totalStudents', 'Students', const Color(0xFF6C63FF))),
          const SizedBox(width: 10),
          Expanded(child: _buildStatChip(Icons.how_to_reg_rounded, '$_presentToday', 'Present', const Color(0xFF00E096))),
          const SizedBox(width: 10),
          Expanded(child: _buildStatChip(Icons.calendar_month_rounded, '$_totalSessions', 'Sessions', const Color(0xFFFFB830))),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.95), accent.withValues(alpha: 0.62)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFCDD5E0),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return GlassContainer(
      borderRadius: 34,
      padding: const EdgeInsets.all(18),
      glowColor: const Color(0xFF6C63FF),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 620;

          final orb = _buildHeroOrb();
          final copy = Column(
            crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Align(
                alignment: wide ? Alignment.centerLeft : Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E096).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF00E096).withValues(alpha: 0.28)),
                  ),
                  child: Text(
                    greeting.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF00E096),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Intelligence\nthat sees people.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  height: 1.0,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enroll students, run live face attendance, and review session history from one luminous dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFFCDD5E0),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.center,
                child: _buildPrimaryActionButton(context),
              ),
            ],
          );

          if (wide) {
            return Row(
              children: [
                Expanded(flex: 5, child: orb),
                const SizedBox(width: 18),
                Expanded(flex: 6, child: copy),
              ],
            );
          }

          return Column(
            children: [
              orb,
              const SizedBox(height: 18),
              copy,
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroOrb() {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF1E2A52), Color(0xFF0F1731), Color(0xFF060B17)],
                stops: [0.0, 0.68, 1.0],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.28),
                  blurRadius: 26,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.20),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Color(0xFF00D4FF),
                  Color(0xFF6C63FF),
                  Color(0xFFFFB830),
                  Color(0xFFFF6A88),
                  Color(0xFF00D4FF),
                ],
                stops: [0.0, 0.25, 0.52, 0.78, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF070D1A),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6C63FF).withValues(alpha: 0.24),
                          const Color(0xFF00D4FF).withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0D1B2A),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.1),
                    ),
                    child: const Icon(Icons.face_retouching_natural_rounded, color: Colors.white, size: 42),
                  ),
                  Positioned(top: 28, left: 32, child: _buildOrbAccent(const Color(0xFF00D4FF), 18)),
                  Positioned(top: 44, right: 34, child: _buildOrbAccent(const Color(0xFFFFB830), 12)),
                  Positioned(bottom: 32, left: 40, child: _buildOrbAccent(const Color(0xFFFF6A88), 14)),
                  Positioned(bottom: 24, right: 44, child: _buildOrbAccent(const Color(0xFF00E096), 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbAccent(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.12)]),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, spreadRadius: 1),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppConstants.routeAttendance),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF27E8D8), Color(0xFF6C63FF), Color(0xFFFFB86C)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Start Attendance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedGrid(BuildContext context) {
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
        title: 'Live Attendance',
        subtitle: 'Scan and mark in real time',
        c1: const Color(0xFF00D4FF),
        c2: const Color(0xFF00E096),
        route: AppConstants.routeAttendance,
      ),
      _ToolItem(
        icon: Icons.calendar_month_rounded,
        title: 'Session',
        subtitle: 'View today and history',
        c1: const Color(0xFFFFB830),
        c2: const Color(0xFFFF7043),
        route: AppConstants.routeAttendance,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            children: [
              Expanded(child: _buildFeatureCard(context, items[0])),
              const SizedBox(width: 12),
              Expanded(child: _buildFeatureCard(context, items[1])),
              const SizedBox(width: 12),
              Expanded(child: _buildFeatureCard(context, items[2])),
            ],
          );
        }

        return Column(
          children: [
            _buildFeatureCard(context, items[0]),
            const SizedBox(height: 12),
            _buildFeatureCard(context, items[1]),
            const SizedBox(height: 12),
            _buildFeatureCard(context, items[2]),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard(BuildContext context, _ToolItem item) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, item.route!),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        constraints: const BoxConstraints(minHeight: 174),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF111C33),
              item.c1.withValues(alpha: 0.14),
              const Color(0xFF0E1728),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: item.c1.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.34),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: item.c1.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [item.c1.withValues(alpha: 0.20), Colors.transparent]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [item.c1, item.c2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: Icon(Icons.arrow_forward_rounded, color: item.c1, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    final tools = [
      _ToolItem(
        icon: Icons.mood_rounded,
        title: 'Expression AI',
        subtitle: 'Emotion insights',
        c1: const Color(0xFFFFB830),
        c2: const Color(0xFFFF7043),
        route: AppConstants.routeExpressionDetection,
      ),
      _ToolItem(
        icon: Icons.download_rounded,
        title: 'Export',
        subtitle: 'Reports & CSV',
        c1: const Color(0xFF00D4FF),
        c2: const Color(0xFF00A8E8),
        route: AppConstants.routeExport,
      ),
      _ToolItem(
        icon: Icons.storage_rounded,
        title: 'Database',
        subtitle: 'Manage records',
        c1: const Color(0xFF00E096),
        c2: const Color(0xFF00A878),
        route: AppConstants.routeDatabase,
      ),
      _ToolItem(
        icon: Icons.tune_rounded,
        title: 'Settings',
        subtitle: 'App preferences',
        c1: const Color(0xFF6C63FF),
        c2: const Color(0xFF9B59F5),
        route: AppConstants.routeSettings,
      ),
      _ToolItem(
        icon: Icons.person_add_alt_1_rounded,
        title: 'Enroll',
        subtitle: 'Add students',
        c1: const Color(0xFF8B5CFF),
        c2: const Color(0xFF6C63FF),
        route: AppConstants.routeEnroll,
      ),
      _ToolItem(
        icon: Icons.help_outline_rounded,
        title: 'Help',
        subtitle: 'Support center',
        c1: const Color(0xFFB46CFF),
        c2: const Color(0xFF7B4DFF),
        onTap: () => _showAboutDialog(context),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.42,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tools.map((tool) => _buildToolCard(context, tool)).toList(),
    );
  }

  Widget _buildToolCard(BuildContext context, _ToolItem tool) {
    return InkWell(
      onTap: tool.onTap ?? () => Navigator.pushNamed(context, tool.route!),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0F1A30),
              tool.c1.withValues(alpha: 0.08),
              const Color(0xFF111B2F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tool.c1.withValues(alpha: 0.24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tool.c1, tool.c2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(tool.icon, color: Colors.white, size: 20),
            ),
            const Spacer(),
            Text(
              tool.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tool.subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF8B9BB4),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.chevron_right_rounded, color: tool.c1, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About FAS'),
        content: const Text(
          'AI-powered face recognition system for seamless attendance tracking. Works completely offline with high accuracy and real-time detection.\n\nSupervised by: Shivaprasad D L\nDeveloped by: V Sunil',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
    this.route,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color c1;
  final Color c2;
  final String? route;
  final VoidCallback? onTap;
}import 'package:flutter/material.dart';

import '../database/database_manager.dart';
import '../models/attendance_model.dart';
import '../utils/constants.dart';
import '../widgets/animated_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DatabaseManager _dbManager;

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
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final students = await _dbManager.getAllStudents();
      final todayRecords = await _dbManager.getAttendanceForDate(DateTime.now());
      final attendance = await _dbManager.getAllAttendance();

      final presentStudentIds = todayRecords
          .where((record) => record.status == AttendanceStatus.present)
          .map((record) => record.studentId)
          .toSet();

      final uniqueSessions = attendance
          .map((record) => DateTime(record.date.year, record.date.month, record.date.day))
          .toSet()
          .length;

      if (!mounted) {
        return;
      }

      setState(() {
        _totalStudents = students.length;
        _presentToday = presentStudentIds.length;
        _totalSessions = uniqueSessions;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(7),
                child: Image.asset('assets/icons/vision_id.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AI face attendance',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Color(0xFF00E096)),
                SizedBox(width: 6),
                Text(
                  'System Ready',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () => _showAboutDialog(context),
              icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF00D4FF), size: 22),
            ),
          ),
        ],
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(context),
                const SizedBox(height: 16),
                _buildStatsRow(),
                const SizedBox(height: 20),
                _buildSectionLabel('Featured', const Color(0xFF00D4FF)),
                const SizedBox(height: 12),
                _buildFeaturedGrid(context),
                const SizedBox(height: 20),
                _buildSectionLabel('Power Tools', const Color(0xFFFFB830)),
                const SizedBox(height: 12),
                _buildToolsGrid(context),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, Color accent) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      glowColor: const Color(0xFF00D4FF),
      child: Row(
        children: [
          Expanded(child: _buildStatChip(Icons.groups_rounded, '$_totalStudents', 'Students', const Color(0xFF6C63FF))),
          const SizedBox(width: 10),
          Expanded(child: _buildStatChip(Icons.how_to_reg_rounded, '$_presentToday', 'Present', const Color(0xFF00E096))),
          const SizedBox(width: 10),
          Expanded(child: _buildStatChip(Icons.calendar_month_rounded, '$_totalSessions', 'Sessions', const Color(0xFFFFB830))),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.95), accent.withValues(alpha: 0.62)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFCDD5E0),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return GlassContainer(
      borderRadius: 34,
      padding: const EdgeInsets.all(18),
      glowColor: const Color(0xFF6C63FF),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 620;

          final orb = _buildHeroOrb();
          final copy = Column(
            crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Align(
                alignment: wide ? Alignment.centerLeft : Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E096).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF00E096).withValues(alpha: 0.28)),
                  ),
                  child: Text(
                    greeting.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF00E096),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Intelligence\nthat sees people.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  height: 1.0,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enroll students, run live face attendance, and review session history from one luminous dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFFCDD5E0),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.center,
                child: _buildPrimaryActionButton(context),
              ),
            ],
          );

          if (wide) {
            return Row(
              children: [
                Expanded(flex: 5, child: orb),
                const SizedBox(width: 18),
                Expanded(flex: 6, child: copy),
              ],
            );
          }

          return Column(
            children: [
              orb,
              const SizedBox(height: 18),
              copy,
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroOrb() {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF1E2A52), Color(0xFF0F1731), Color(0xFF060B17)],
                stops: [0.0, 0.68, 1.0],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.28),
                  blurRadius: 26,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.20),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Color(0xFF00D4FF),
                  Color(0xFF6C63FF),
                  Color(0xFFFFB830),
                  Color(0xFFFF6A88),
                  Color(0xFF00D4FF),
                ],
                stops: [0.0, 0.25, 0.52, 0.78, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF070D1A),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6C63FF).withValues(alpha: 0.24),
                          const Color(0xFF00D4FF).withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0D1B2A),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.1),
                    ),
                    child: const Icon(Icons.face_retouching_natural_rounded, color: Colors.white, size: 42),
                  ),
                  Positioned(top: 28, left: 32, child: _buildOrbAccent(const Color(0xFF00D4FF), 18)),
                  Positioned(top: 44, right: 34, child: _buildOrbAccent(const Color(0xFFFFB830), 12)),
                  Positioned(bottom: 32, left: 40, child: _buildOrbAccent(const Color(0xFFFF6A88), 14)),
                  Positioned(bottom: 24, right: 44, child: _buildOrbAccent(const Color(0xFF00E096), 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbAccent(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.12)]),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, spreadRadius: 1),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppConstants.routeAttendance),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF27E8D8), Color(0xFF6C63FF), Color(0xFFFFB86C)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Start Attendance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedGrid(BuildContext context) {
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
        title: 'Live Attendance',
        subtitle: 'Scan and mark in real time',
        c1: const Color(0xFF00D4FF),
        c2: const Color(0xFF00E096),
        route: AppConstants.routeAttendance,
      ),
      _ToolItem(
        icon: Icons.calendar_month_rounded,
        title: 'Session',
        subtitle: 'View today and history',
        c1: const Color(0xFFFFB830),
        c2: const Color(0xFFFF7043),
        route: AppConstants.routeAttendance,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            children: [
              Expanded(child: _buildFeatureCard(context, items[0])),
              const SizedBox(width: 12),
              Expanded(child: _buildFeatureCard(context, items[1])),
              const SizedBox(width: 12),
              Expanded(child: _buildFeatureCard(context, items[2])),
            ],
          );
        }

        return Column(
          children: [
            _buildFeatureCard(context, items[0]),
            const SizedBox(height: 12),
            _buildFeatureCard(context, items[1]),
            const SizedBox(height: 12),
            _buildFeatureCard(context, items[2]),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard(BuildContext context, _ToolItem item) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, item.route!),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        constraints: const BoxConstraints(minHeight: 174),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF111C33),
              item.c1.withValues(alpha: 0.14),
              const Color(0xFF0E1728),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: item.c1.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.34),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: item.c1.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [item.c1.withValues(alpha: 0.20), Colors.transparent]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [item.c1, item.c2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: Icon(Icons.arrow_forward_rounded, color: item.c1, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    final tools = [
      _ToolItem(
        icon: Icons.mood_rounded,
        title: 'Expression AI',
        subtitle: 'Emotion insights',
        c1: const Color(0xFFFFB830),
        c2: const Color(0xFFFF7043),
        route: AppConstants.routeExpressionDetection,
      ),
      _ToolItem(
        icon: Icons.download_rounded,
        title: 'Export',
        subtitle: 'Reports & CSV',
        c1: const Color(0xFF00D4FF),
        c2: const Color(0xFF00A8E8),
        route: AppConstants.routeExport,
      ),
      _ToolItem(
        icon: Icons.storage_rounded,
        title: 'Database',
        subtitle: 'Manage records',
        c1: const Color(0xFF00E096),
        c2: const Color(0xFF00A878),
        route: AppConstants.routeDatabase,
      ),
      _ToolItem(
        icon: Icons.tune_rounded,
        title: 'Settings',
        subtitle: 'App preferences',
        c1: const Color(0xFF6C63FF),
        c2: const Color(0xFF9B59F5),
        route: AppConstants.routeSettings,
      ),
      _ToolItem(
        icon: Icons.person_add_alt_1_rounded,
        title: 'Enroll',
        subtitle: 'Add students',
        c1: const Color(0xFF8B5CFF),
        c2: const Color(0xFF6C63FF),
        route: AppConstants.routeEnroll,
      ),
      _ToolItem(
        icon: Icons.help_outline_rounded,
        title: 'Help',
        subtitle: 'Support center',
        c1: const Color(0xFFB46CFF),
        c2: const Color(0xFF7B4DFF),
        onTap: () => _showAboutDialog(context),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.42,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tools.map((tool) => _buildToolCard(context, tool)).toList(),
    );
  }

  Widget _buildToolCard(BuildContext context, _ToolItem tool) {
    return InkWell(
      onTap: tool.onTap ?? () => Navigator.pushNamed(context, tool.route!),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0F1A30),
              tool.c1.withValues(alpha: 0.08),
              const Color(0xFF111B2F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tool.c1.withValues(alpha: 0.24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tool.c1, tool.c2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(tool.icon, color: Colors.white, size: 20),
            ),
            const Spacer(),
            Text(
              tool.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tool.subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF8B9BB4),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.chevron_right_rounded, color: tool.c1, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About FAS'),
        content: const Text(
          'AI-powered face recognition system for seamless attendance tracking. Works completely offline with high accuracy and real-time detection.\n\nSupervised by: Shivaprasad D L\nDeveloped by: V Sunil',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
    this.route,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color c1;
  final Color c2;
  final String? route;
  final VoidCallback? onTap;
}import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/animated_background.dart';
import '../database/database_manager.dart';
import '../modules/m4_attendance_management.dart';
import '../models/attendance_model.dart';

/// Home Screen (Page 1)
/// Main navigation hub with buttons to all features
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
        surfaceTintColor: Colors.transparent,

        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(7),
                child: Image.asset(
                  'assets/icons/vision_id.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AI face attendance',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
    _attendanceModule = AttendanceManagementModule(_dbManager);
    _loadStats();
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Color(0xFF00E096)),
                SizedBox(width: 6),
                Text(
                  'System Ready',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
  }
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF00D4FF),
                  size: 22,
                ),
                onPressed: () => _showAboutDialog(context),
              ),
      final students = await _dbManager.getAllStudents();
      final totalStudents = students.length;

      // Get today's attendance count (unique students marked present)
      final today = DateTime.now();
      final todayRecords = await _dbManager.getAttendanceForDate(today);
      
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      final presentStudentIds = todayRecords
          .where((record) => record.status == AttendanceStatus.present)
          .map((record) => record.studentId)
                _buildHeaderSection(context),
      
      final presentToday = presentStudentIds.length;
                const SizedBox(height: 20),
                _buildFeaturedRow(context),
                const SizedBox(height: 20),
                _buildSectionLabel('Power Tools', const Color(0xFF00D4FF)),
      final allAttendance = await _dbManager.getAllAttendance();
          )
          .toSet()
          .length;

      setState(() {
        _totalStudents = totalStudents;
        _presentToday = presentToday;
        _totalSessions = uniqueDates;
      });
    } catch (e) {
  Widget _buildSectionLabel(String text, Color accentDot) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [accentDot, accentDot.withValues(alpha: 0.15)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentDot.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSparkline = constraints.maxWidth >= 560;

        return GlassContainer(
          borderRadius: 28,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          glowColor: const Color(0xFF00D4FF),
          child: Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  Icons.groups_rounded,
                  '$_totalStudents',
                  'Students',
                  const Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  Icons.how_to_reg_rounded,
                  '$_presentToday',
                  'Present',
                  const Color(0xFF00E096),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  Icons.calendar_month_rounded,
                  '$_totalSessions',
                  'Sessions',
                  const Color(0xFFFFB830),
                ),
              ),
              if (showSparkline) ...[
                const SizedBox(width: 12),
                Container(
                  width: 78,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      7,
                      (index) {
                        final heights = [12.0, 24.0, 18.0, 30.0, 16.0, 26.0, 14.0];
                        return Container(
                          width: 4,
                          height: heights[index],
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00D4FF), Color(0xFF6C63FF)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.95), accent.withValues(alpha: 0.62)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFCDD5E0),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedRow(BuildContext context) {
    final cards = [
      _buildFeaturedCard(
        context,
        icon: Icons.person_add_alt_1_rounded,
        title: 'Enroll',
        subtitle: 'Add new student faces',
        accent: const Color(0xFF8B5CFF),
        route: AppConstants.routeEnroll,
      ),
      _buildFeaturedCard(
        context,
        icon: Icons.face_retouching_natural_rounded,
        title: 'Live Attendance',
        subtitle: 'Scan and mark in real time',
        accent: const Color(0xFF00D4FF),
        route: AppConstants.routeAttendance,
      ),
      _buildFeaturedCard(
        context,
        icon: Icons.calendar_month_rounded,
        title: 'Session',
        subtitle: 'View today and history',
        accent: const Color(0xFFFFB830),
        route: AppConstants.routeAttendance,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
              const SizedBox(width: 12),
              Expanded(child: cards[2]),
            ],
          );
        }

        return Column(
          children: [
            cards[0],
            const SizedBox(height: 12),
            cards[1],
            const SizedBox(height: 12),
            cards[2],
          ],
        );
      },
    );
  }

  Widget _buildFeaturedCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required String route,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        constraints: const BoxConstraints(minHeight: 174),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF111C33),
              accent.withValues(alpha: 0.14),
              const Color(0xFF0E1728),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.34),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.72)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: Icon(Icons.arrow_forward_rounded, color: accent, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    final tools = [
      _ToolItem(
        icon: Icons.mood_rounded,
        title: 'Expression AI',
        subtitle: 'Emotion insights',
        c1: const Color(0xFFFFB830),
        c2: const Color(0xFFFF7043),
        route: AppConstants.routeExpressionDetection,
      ),
      _ToolItem(
        icon: Icons.download_rounded,
        title: 'Export',
        subtitle: 'Reports & CSV',
        c1: const Color(0xFF00D4FF),
        c2: const Color(0xFF00A8E8),
        route: AppConstants.routeExport,
      ),
      _ToolItem(
        icon: Icons.storage_rounded,
        title: 'Database',
        subtitle: 'Manage records',
        c1: const Color(0xFF00E096),
        c2: const Color(0xFF00A878),
        route: AppConstants.routeDatabase,
      ),
      _ToolItem(
        icon: Icons.tune_rounded,
        title: 'Settings',
        subtitle: 'App preferences',
        c1: const Color(0xFF6C63FF),
        c2: const Color(0xFF9B59F5),
        route: AppConstants.routeSettings,
      ),
      _ToolItem(
        icon: Icons.person_add_alt_1_rounded,
        title: 'Enroll',
        subtitle: 'Add students',
        c1: const Color(0xFF8B5CFF),
        c2: const Color(0xFF6C63FF),
        route: AppConstants.routeEnroll,
      ),
      _ToolItem(
        icon: Icons.face_retouching_natural_rounded,
        title: 'Attendance',
        subtitle: 'Live scanning',
        c1: const Color(0xFF00D4FF),
        c2: const Color(0xFF00E096),
        route: AppConstants.routeAttendance,
      ),
      _ToolItem(
        icon: Icons.security_rounded,
        title: 'Security',
        subtitle: 'Privacy controls',
        c1: const Color(0xFF7C8DBA),
        c2: const Color(0xFF4C5A86),
        route: AppConstants.routeSettings,
      ),
      _ToolItem(
        icon: Icons.help_outline_rounded,
        title: 'Help',
        subtitle: 'Support center',
        c1: const Color(0xFFB46CFF),
        c2: const Color(0xFF7B4DFF),
        onTap: () => _showAboutDialog(context),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.42,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tools.map((tool) => _buildToolCard2(context, tool)).toList(),
    );
  }

  Widget _buildToolCard2(BuildContext context, _ToolItem t) {
    return InkWell(
      onTap: t.onTap ?? () => Navigator.pushNamed(context, t.route!),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0F1A30),
              t.c1.withValues(alpha: 0.08),
              const Color(0xFF111B2F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: t.c1.withValues(alpha: 0.24),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: t.c1.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -18,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      t.c1.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [t.c1, t.c2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: t.c1.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(t.icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                Text(
                  t.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8B9BB4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: t.c1,
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return GlassContainer(
      borderRadius: 34,
      padding: const EdgeInsets.all(18),
      glowColor: const Color(0xFF6C63FF),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 620;

          final heroOrb = _buildHeroOrb();
          final heroCopy = Column(
            crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Align(
                alignment: isWide ? Alignment.centerLeft : Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E096).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF00E096).withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    greeting.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF00E096),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Intelligence\nthat sees people.',
                textAlign: isWide ? TextAlign.left : TextAlign.center,
                style: TextStyle(
                  fontSize: isWide ? 40 : 32,
                  height: 1.0,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enroll students, run live face attendance, and review session history from one luminous dashboard.',
                textAlign: isWide ? TextAlign.left : TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFFCDD5E0),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment:
                    isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  _buildPrimaryActionButton(context),
                ],
              ),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 5, child: heroOrb),
                const SizedBox(width: 18),
                Expanded(flex: 6, child: heroCopy),
              ],
            );
          }

          return Column(
            children: [
              heroOrb,
              const SizedBox(height: 18),
              heroCopy,
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroOrb() {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFF1E2A52),
                  Color(0xFF0F1731),
                  Color(0xFF060B17),
                ],
                stops: [0.0, 0.68, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.28),
                  blurRadius: 26,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.20),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: const [
                  Color(0xFF00D4FF),
                  Color(0xFF6C63FF),
                  Color(0xFFFFB830),
                  Color(0xFFFF6A88),
                  Color(0xFF00D4FF),
                ],
                stops: const [0.0, 0.25, 0.52, 0.78, 1.0],
                transform: GradientRotation(_controller.value * 6.28318),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF070D1A),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6C63FF).withValues(alpha: 0.24),
                          const Color(0xFF00D4FF).withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0D1B2A),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.face_retouching_natural_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  Positioned(
                    top: 28,
                    left: 32,
                    child: _buildOrbAccent(const Color(0xFF00D4FF), 18),
                  ),
                  Positioned(
                    top: 44,
                    right: 34,
                    child: _buildOrbAccent(const Color(0xFFFFB830), 12),
                  ),
                  Positioned(
                    bottom: 32,
                    left: 40,
                    child: _buildOrbAccent(const Color(0xFFFF6A88), 14),
                  ),
                  Positioned(
                    bottom: 24,
                    right: 44,
                    child: _buildOrbAccent(const Color(0xFF00E096), 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbAccent(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.12),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppConstants.routeAttendance),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF27E8D8),
              Color(0xFF6C63FF),
              Color(0xFFFFB86C),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Start Attendance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF00D4FF),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'AI Face Attendance',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E096).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF00E096).withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Color(0xFF00E096), size: 7),
                          SizedBox(width: 4),
                          Text('Offline Ready', style: TextStyle(fontSize: 10, color: Color(0xFF00E096), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  // _buildDashboardGrid replaced by _buildFeaturedRow + _buildToolsGrid above

  Widget _buildQuickToolsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(
              left: AppConstants.paddingSmall,
              bottom: AppConstants.paddingMedium,
            ),
            child: Text(
              'Management Tools',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildToolCard(
                  context,
                  icon: Icons.storage,
                  title: 'Database',
                  subtitle: 'View & manage students',
                  route: AppConstants.routeDatabase,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildToolCard(
                  context,
                  icon: Icons.download_rounded,
                  title: 'Export',
                  subtitle: 'Generate reports',
                  route: AppConstants.routeExport,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildToolCard(
                  context,
                  icon: Icons.tune,
                  title: 'Settings',
                  subtitle: 'Configure app',
                  route: AppConstants.routeSettings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
      ),
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: AppConstants.cardBorder),
        boxShadow: [AppConstants.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Key Features',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFeatureItem(Icons.offline_bolt, 'Offline Operation'),
              _buildFeatureItem(Icons.speed, 'Real-time Detection'),
              _buildFeatureItem(Icons.memory, 'Smart Embeddings'),
              _buildFeatureItem(Icons.verified, 'Accurate Matching'),
              _buildFeatureItem(Icons.history, 'Attendance Logs'),
              _buildFeatureItem(Icons.file_download, 'Export Reports'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required Gradient gradient,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withAlpha(100),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withAlpha(220),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF253454), Color(0xFF1B2A49)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          border: Border.all(color: AppConstants.cardBorder.withAlpha(180)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(74),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withAlpha(14),
              blurRadius: 6,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.primaryColor.withAlpha(35),
                      AppConstants.primaryColor.withAlpha(12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(18)),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryColor.withAlpha(35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 24, color: AppConstants.primaryColor),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppConstants.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppConstants.inputFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.cardBorder.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppConstants.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // _buildBottomStatsBar / _buildStatItem replaced by _buildStatsRow / _buildStatChip above

  // _buildHexagonalCard / _buildCircularCard removed — replaced by _buildFeaturedCard / _buildToolCard2

  Widget _buildFeatureHighlightCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.primaryColor.withAlpha(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.offline_bolt,
              color: AppConstants.primaryColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            const Text(
              'Offline\nOperation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Works without internet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: AppConstants.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About FAS'),
        content: const Text(
          'AI-powered face recognition system for seamless attendance tracking. '
          'Works completely offline with high accuracy and real-time detection.\n\n'
          'Supervised by: Shivaprasad D L\n'
          'Developed by: V Sunil',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Helper data class for tools grid
// ────────────────────────────────────────────────────────────
class _ToolItem {
  const _ToolItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.c1,
    required this.c2,
    this.route,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color c1;
  final Color c2;
  final String? route;
  final VoidCallback? onTap;
}
