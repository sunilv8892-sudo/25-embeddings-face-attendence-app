import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/constants.dart';
import '../utils/export_utils.dart';
import '../widgets/animated_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _CreditProfile _guruProfile = _CreditProfile(
    fullName: 'Dr. D S Guru',
    title: 'Senior Professor',
    photoAsset: 'assets/icons/guru.jpeg',
    descriptionLines: [
      'Senior Professor',
      'Department of Studies in Computer Science',
      'Manasagangotri, University of Mysore, Mysuru',
      'Email: dsg@compsci.uni-mysore.ac.in',
    ],
    frostyGlass: true,
  );

  static const _CreditProfile _shivaprasadProfile = _CreditProfile(
    fullName: 'Shivaprasad D L',
    title: 'Research Scholar',
    photoAsset: 'assets/icons/shivaprasad.jpeg',
    descriptionLines: [
      'Research Scholar',
      'Department of Studies in Computer Science',
      'Manasagangotri, University of Mysore, Mysuru',
      'Email: shivaprasaddl143@gmail.com',
    ],
    frostyGlass: true,
  );

  static const _CreditProfile _sunilProfile = _CreditProfile(
    fullName: 'V Sunil',
    title: 'Developer',
    photoAsset: 'assets/icons/sunil.jpeg',
    descriptionLines: [
      'Developer',
      'MIT First Grade College, Mysuru',
      'Email: sunil.v8892@gmail.com',
    ],
    frostyGlass: true,
  );

  // Real stats
  int _totalStudents = 0;
  int _totalEmbeddings = 0;
  int _totalAttendance = 0;
  int _totalSubjects = 0;
  int _totalSessions = 0;
  String _dataSize = '...';
  bool _ttsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load TTS preference
    _ttsEnabled = prefs.getBool('tts_enabled') ?? true;

    // Load real database stats
    final students = prefs.getStringList('students') ?? [];
    final embeddings = prefs.getStringList('embeddings') ?? [];
    final attendance = prefs.getStringList('attendance') ?? [];
    final subjects = prefs.getStringList('subjects') ?? [];
    final sessions = prefs.getStringList('teacherSessions') ?? [];

    // Calculate approximate data size
    int totalBytes = 0;
    for (final s in students) {
      totalBytes += s.length;
    }
    for (final s in embeddings) {
      totalBytes += s.length;
    }
    for (final s in attendance) {
      totalBytes += s.length;
    }
    for (final s in subjects) {
      totalBytes += s.length;
    }
    for (final s in sessions) {
      totalBytes += s.length;
    }

    String sizeStr;
    if (totalBytes < 1024) {
      sizeStr = '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      sizeStr = '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      sizeStr = '${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    if (mounted) {
      setState(() {
        _totalStudents = students.length;
        _totalEmbeddings = embeddings.length;
        _totalAttendance = attendance.length;
        _totalSubjects = subjects.length;
        _totalSessions = sessions.length;
        _dataSize = sizeStr;
      });
    }
  }

  Future<void> _toggleTts(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_enabled', enabled);
    setState(() => _ttsEnabled = enabled);
  }

  Future<void> _backupDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backup = <String, dynamic>{
        'version': 1,
        'exportDate': DateTime.now().toIso8601String(),
        'students': prefs.getStringList('students') ?? [],
        'embeddings': prefs.getStringList('embeddings') ?? [],
        'attendance': prefs.getStringList('attendance') ?? [],
        'subjects': prefs.getStringList('subjects') ?? [],
        'teacherSessions': prefs.getStringList('teacherSessions') ?? [],
      };

      final jsonStr = jsonEncode(backup);

      // Save to file
      final dir = await getExportDirectory();

      final dateStr = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[:\\.]'), '-');
      final file = File('${dir.path}/backup_$dateStr.json');
      await file.writeAsString(jsonStr, flush: true);

      if (mounted) {
        // Offer to share
        final shouldShare = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Backup Created'),
            content: Text(
              'Backup saved successfully.\n\n'
              'Students: $_totalStudents\n'
              'Embeddings: $_totalEmbeddings\n'
              'Attendance Records: $_totalAttendance\n\n'
              'Share the backup file?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Done'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
              ),
            ],
          ),
        );

        if (shouldShare == true) {
          await Share.shareXFiles(
            [XFile(file.path)],
            text: 'Face Attendance Database Backup',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _restoreFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select backup JSON file',
      );
      if (result == null) return;
      final path = result.files.single.path;
      if (path == null) return;

      final file = File(path);
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Validate it looks like our backup format
      if (!data.containsKey('students') && !data.containsKey('embeddings')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid backup file — missing expected data keys.'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
        return;
      }

      // Show confirmation with stats before overwriting
      final studentCount = (data['students'] as List?)?.length ?? 0;
      final embeddingCount = (data['embeddings'] as List?)?.length ?? 0;
      final attendanceCount = (data['attendance'] as List?)?.length ?? 0;
      final subjectCount = (data['subjects'] as List?)?.length ?? 0;
      final sessionCount = (data['teacherSessions'] as List?)?.length ?? 0;
      final exportDate = data['exportDate'] ?? 'Unknown';

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore From Backup?'),
          content: Text(
            'This will REPLACE all current data with the backup.\n\n'
            'Backup info:\n'
            'Export date: $exportDate\n'
            'Students: $studentCount\n'
            'Embeddings: $embeddingCount\n'
            'Attendance: $attendanceCount\n'
            'Subjects: $subjectCount\n'
            'Sessions: $sessionCount\n\n'
            'Current data will be lost. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Restore'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('students', List<String>.from(data['students'] ?? []));
      await prefs.setStringList('embeddings', List<String>.from(data['embeddings'] ?? []));
      await prefs.setStringList('attendance', List<String>.from(data['attendance'] ?? []));
      await prefs.setStringList('subjects', List<String>.from(data['subjects'] ?? []));
      await prefs.setStringList('teacherSessions', List<String>.from(data['teacherSessions'] ?? []));

      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restored $studentCount students, $attendanceCount attendance records from backup.'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _mergeFromFile() async {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    String normalizeText(dynamic value) {
      return (value as String? ?? '').trim().toLowerCase();
    }

    int readStudentId(Map<String, dynamic> map) {
      return asInt(map['studentId'] ?? map['student_id']);
    }

    Map<String, dynamic> normalizeEmbeddingMap(Map<String, dynamic> source) {
      final map = Map<String, dynamic>.from(source);
      final studentId = readStudentId(map);
      final captureRaw = map['captureDate'] ?? map['capture_date'];

      List<double> vector;
      final vectorRaw = map['vector'];
      if (vectorRaw is List) {
        vector = vectorRaw
            .map((e) => (e is num) ? e.toDouble() : double.tryParse('$e'))
            .whereType<double>()
            .toList();
      } else if (vectorRaw is String) {
        vector = vectorRaw
            .split(RegExp(r'[;,]'))
            .map((e) => double.tryParse(e.trim()))
            .whereType<double>()
            .toList();
      } else {
        vector = <double>[];
      }

      final captureDate = DateTime.tryParse('${captureRaw ?? ''}') ?? DateTime.now();

      map['studentId'] = studentId;
      map['captureDate'] = captureDate.toIso8601String();
      map['vector'] = vector;
      map.remove('student_id');
      map.remove('capture_date');
      return map;
    }

    Map<String, dynamic> normalizeAttendanceMap(Map<String, dynamic> source) {
      final map = Map<String, dynamic>.from(source);
      final studentId = readStudentId(map);
      final recordedRaw = map['recordedAt'] ?? map['recorded_at'];
      final recordedAt = DateTime.tryParse('${recordedRaw ?? ''}') ?? DateTime.now();

      map['studentId'] = studentId;
      map['recordedAt'] = recordedAt.toIso8601String();
      map['status'] = (map['status'] as String? ?? 'absent').trim().isEmpty
          ? 'absent'
          : map['status'];
      map.remove('student_id');
      map.remove('recorded_at');
      return map;
    }

    List<String> parseCsvLine(String line) {
      final fields = <String>[];
      var buffer = StringBuffer();
      var inQuotes = false;

      for (int i = 0; i < line.length; i++) {
        final char = line[i];

        if (char == '"') {
          if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
            buffer.write('"');
            i++;
          } else {
            inQuotes = !inQuotes;
          }
        } else if (char == ',' && !inQuotes) {
          fields.add(buffer.toString());
          buffer = StringBuffer();
        } else {
          buffer.write(char);
        }
      }

      fields.add(buffer.toString());
      return fields;
    }

    Map<String, dynamic> parseEmbeddingsCsvAsMergePayload(String csvText) {
      final rawLines = csvText
          .split(RegExp(r'\r?\n'))
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (rawLines.isEmpty) {
        throw const FormatException('CSV file is empty.');
      }

      final header = parseCsvLine(rawLines.first)
          .map((h) => h.trim())
          .toList();

      final requiredColumns = <String>{
        'id',
        'student_id',
        'student_name',
        'roll_number',
        'class',
        'gender',
        'age',
        'phone_number',
        'enrollment_date',
        'capture_date',
        'dimension',
        'vector',
      };

      final headerSet = header.toSet();
      if (!requiredColumns.every(headerSet.contains)) {
        throw const FormatException(
          'CSV format not supported. Expected embeddings export columns.',
        );
      }

      final col = <String, int>{
        for (int i = 0; i < header.length; i++) header[i]: i,
      };

      String valueAt(List<String> row, String key) {
        final idx = col[key]!;
        if (idx < 0 || idx >= row.length) return '';
        return row[idx].trim();
      }

      final studentsByImportedId = <int, Map<String, dynamic>>{};
      final embeddings = <String>[];

      for (int lineIndex = 1; lineIndex < rawLines.length; lineIndex++) {
        final line = rawLines[lineIndex];
        final row = parseCsvLine(line);
        if (row.length < header.length) {
          continue;
        }

        final importedStudentId = asInt(valueAt(row, 'student_id'));
        final studentName = valueAt(row, 'student_name');
        if (importedStudentId <= 0 || studentName.isEmpty) {
          continue;
        }

        studentsByImportedId.putIfAbsent(importedStudentId, () {
          final enrollmentRaw = valueAt(row, 'enrollment_date');
          final enrollmentDate = DateTime.tryParse(enrollmentRaw) ?? DateTime.now();
          return {
            'id': importedStudentId,
            'name': studentName,
            'roll_number': valueAt(row, 'roll_number'),
            'class': valueAt(row, 'class'),
            'gender': valueAt(row, 'gender'),
            'age': asInt(valueAt(row, 'age')),
            'phone_number': valueAt(row, 'phone_number'),
            'enrollment_date': enrollmentDate.toIso8601String(),
          };
        });

        final vector = valueAt(row, 'vector')
            .split(';')
            .map((e) => double.tryParse(e.trim()))
            .whereType<double>()
            .toList();
        final dimension = asInt(valueAt(row, 'dimension'));
        if (vector.isEmpty || (dimension > 0 && vector.length != dimension)) {
          continue;
        }

        final captureRaw = valueAt(row, 'capture_date');
        final captureDate = DateTime.tryParse(captureRaw) ?? DateTime.now();

        final embeddingMap = <String, dynamic>{
          'id': asInt(valueAt(row, 'id')),
          'studentId': importedStudentId,
          'vector': vector,
          'captureDate': captureDate.toIso8601String(),
        };

        embeddings.add(jsonEncode(embeddingMap));
      }

      return {
        'version': 1,
        'exportDate': DateTime.now().toIso8601String(),
        'students': studentsByImportedId.values.map(jsonEncode).toList(),
        'embeddings': embeddings,
        'attendance': <String>[],
        'subjects': <String>[],
        'teacherSessions': <String>[],
      };
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
        dialogTitle: 'Select backup JSON or embeddings CSV file to merge',
      );
      if (result == null) return;
      final path = result.files.single.path;
      if (path == null) return;

      final file = File(path);
      final lowerPath = path.toLowerCase();
      late final Map<String, dynamic> data;
      if (lowerPath.endsWith('.csv')) {
        final csvStr = await file.readAsString();
        data = parseEmbeddingsCsvAsMergePayload(csvStr);
      } else {
        final jsonStr = await file.readAsString();
        data = jsonDecode(jsonStr) as Map<String, dynamic>;
      }

      // Validate backup format
      if (!data.containsKey('students') && !data.containsKey('embeddings')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid backup file — missing expected data keys.'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
        return;
      }

      final importStudents = List<String>.from(data['students'] ?? []);
      final importEmbeddings = List<String>.from(data['embeddings'] ?? []);
      final importAttendance = List<String>.from(data['attendance'] ?? []);
      final importSubjects = List<String>.from(data['subjects'] ?? []);
      final importSessions = List<String>.from(data['teacherSessions'] ?? []);
      final exportDate = data['exportDate'] ?? 'Unknown';

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Merge Backup Data?'),
          content: Text(
            'This will MERGE the backup data with your current data.\n'
            'Existing data will be preserved.\n\n'
            'Backup info:\n'
            'Export date: $exportDate\n'
            'Students: ${importStudents.length}\n'
            'Embeddings: ${importEmbeddings.length}\n'
            'Attendance: ${importAttendance.length}\n'
            'Subjects: ${importSubjects.length}\n'
            'Sessions: ${importSessions.length}\n\n'
            'New items will be added, duplicates will be skipped.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.merge_type, size: 18),
              label: const Text('Merge'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final prefs = await SharedPreferences.getInstance();

      // Get current data
      final currentStudents = prefs.getStringList('students') ?? [];
      final currentEmbeddings = prefs.getStringList('embeddings') ?? [];
      final currentAttendance = prefs.getStringList('attendance') ?? [];
      final currentSubjects = prefs.getStringList('subjects') ?? [];
      final currentSessions = prefs.getStringList('teacherSessions') ?? [];

      // ── Merge Students ──
      final existingStudentKeys = <String>{};
      int maxStudentId = 0;
      for (final s in currentStudents) {
        final map = jsonDecode(s) as Map<String, dynamic>;
        final key = '${normalizeText(map['name'])}|${normalizeText(map['roll_number'])}';
        final id = asInt(map['id']);
        existingStudentKeys.add(key);
        if (id > maxStudentId) maxStudentId = id;
      }

      // Map old imported IDs → new IDs (for embedding/attendance remapping)
      final idMapping = <int, int>{};
      int addedStudents = 0;

      for (final s in importStudents) {
        final map = jsonDecode(s) as Map<String, dynamic>;
        final key = '${normalizeText(map['name'])}|${normalizeText(map['roll_number'])}';
        final oldId = asInt(map['id']);

        if (existingStudentKeys.contains(key)) {
          // Student already exists — find their current ID for remapping
          for (final cs in currentStudents) {
            final cMap = jsonDecode(cs) as Map<String, dynamic>;
            final cKey = '${normalizeText(cMap['name'])}|${normalizeText(cMap['roll_number'])}';
            if (cKey == key) {
              idMapping[oldId] = asInt(cMap['id']);
              break;
            }
          }
          continue;
        }

        // New student — assign fresh ID
        maxStudentId++;
        idMapping[oldId] = maxStudentId;
        map['id'] = maxStudentId;
        currentStudents.add(jsonEncode(map));
        existingStudentKeys.add(key);
        addedStudents++;
      }

      // ── Merge Embeddings ──
      int addedEmbeddings = 0;
      int maxEmbeddingId = 0;
      final existingEmbeddingKeys = <String>{};
      for (final e in currentEmbeddings) {
        final map = normalizeEmbeddingMap(jsonDecode(e) as Map<String, dynamic>);
        final studentId = readStudentId(map);
        final captureDate = map['captureDate'] as String? ?? '';
        final vector = List<double>.from(map['vector'] as List? ?? const <double>[]);
        final sample = vector.take(6).map((v) => v.toStringAsFixed(6)).join(';');
        existingEmbeddingKeys.add('$studentId|$captureDate|${vector.length}|$sample');
        final id = asInt(map['id']);
        if (id > maxEmbeddingId) maxEmbeddingId = id;
      }

      for (final e in importEmbeddings) {
        final map = normalizeEmbeddingMap(jsonDecode(e) as Map<String, dynamic>);
        final oldStudentId = readStudentId(map);
        final newStudentId = idMapping[oldStudentId] ?? oldStudentId;
        map['studentId'] = newStudentId;

        final captureDate = map['captureDate'] as String? ?? '';
        final vector = List<double>.from(map['vector'] as List? ?? const <double>[]);
        if (newStudentId <= 0 || vector.isEmpty) continue;

        final sample = vector.take(6).map((v) => v.toStringAsFixed(6)).join(';');
        final key = '$newStudentId|$captureDate|${vector.length}|$sample';
        if (existingEmbeddingKeys.contains(key)) continue;

        maxEmbeddingId++;
        map['id'] = maxEmbeddingId;
        currentEmbeddings.add(jsonEncode(map));
        existingEmbeddingKeys.add(key);
        addedEmbeddings++;
      }

      // ── Merge Attendance ──
      int addedAttendance = 0;
      int maxAttendanceId = 0;
      final existingAttendanceKeys = <String>{};
      for (final a in currentAttendance) {
        final map = normalizeAttendanceMap(jsonDecode(a) as Map<String, dynamic>);
        final studentId = readStudentId(map);
        final date = (map['date'] as String? ?? '').split('T').first;
        existingAttendanceKeys.add('${studentId}_$date');
        final id = asInt(map['id']);
        if (id > maxAttendanceId) maxAttendanceId = id;
      }

      for (final a in importAttendance) {
        final map = normalizeAttendanceMap(jsonDecode(a) as Map<String, dynamic>);
        final oldStudentId = readStudentId(map);
        final newStudentId = idMapping[oldStudentId] ?? oldStudentId;
        map['studentId'] = newStudentId;
        if (newStudentId <= 0) continue;

        final date = (map['date'] as String? ?? '').split('T').first;
        final key = '${newStudentId}_$date';
        if (existingAttendanceKeys.contains(key)) continue;

        maxAttendanceId++;
        map['id'] = maxAttendanceId;
        currentAttendance.add(jsonEncode(map));
        existingAttendanceKeys.add(key);
        addedAttendance++;
      }

      // ── Merge Subjects ──
      int addedSubjects = 0;
      int maxSubjectId = 0;
      final existingSubjectNames = <String>{};
      for (final s in currentSubjects) {
        final map = jsonDecode(s) as Map<String, dynamic>;
        existingSubjectNames.add((map['name'] as String? ?? '').toLowerCase().trim());
        final id = asInt(map['id']);
        if (id > maxSubjectId) maxSubjectId = id;
      }

      for (final s in importSubjects) {
        final map = jsonDecode(s) as Map<String, dynamic>;
        final name = (map['name'] as String? ?? '').toLowerCase().trim();
        if (existingSubjectNames.contains(name)) continue;

        maxSubjectId++;
        map['id'] = maxSubjectId;
        currentSubjects.add(jsonEncode(map));
        existingSubjectNames.add(name);
        addedSubjects++;
      }

      // ── Merge Sessions ──
      int addedSessions = 0;
      final existingSessionKeys = currentSessions.toSet();
      for (final s in importSessions) {
        if (existingSessionKeys.contains(s)) continue;
        currentSessions.add(s);
        existingSessionKeys.add(s);
        addedSessions++;
      }

      // Save all merged data
      await prefs.setStringList('students', currentStudents);
      await prefs.setStringList('embeddings', currentEmbeddings);
      await prefs.setStringList('attendance', currentAttendance);
      await prefs.setStringList('subjects', currentSubjects);
      await prefs.setStringList('teacherSessions', currentSessions);

      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Merged: +$addedStudents students, +$addedEmbeddings embeddings, '
              '+$addedAttendance attendance, +$addedSubjects subjects, +$addedSessions sessions',
            ),
            backgroundColor: AppConstants.successColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Merge failed: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _clearAttendanceOnly() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Attendance Records?'),
        content: const Text(
          'This will delete all attendance records, sessions, and subjects.\n\n'
          'Students and their face embeddings will be kept.\n'
          'You can take fresh attendance afterward.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppConstants.errorColor),
            child: const Text('Clear Attendance'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('attendance');
      await prefs.remove('subjects');
      await prefs.remove('teacherSessions');

      // Also remove session_attendance_ keys
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith('session_attendance_')) {
          await prefs.remove(key);
        }
      }

      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance records cleared. Students preserved.'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppConstants.errorColor),
        );
      }
    }
  }

  Future<void> _deleteExportedFiles() async {
    try {
      final dir = await getExportDirectory();

      if (!await dir.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No exported files found.')),
          );
        }
        return;
      }

      final files = dir.listSync().whereType<File>().toList();
      if (files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No exported files found.')),
          );
        }
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete All Exported Files?'),
          content: Text(
            'This will delete ${files.length} exported CSV/backup files.\nThis cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  TextButton.styleFrom(foregroundColor: AppConstants.errorColor),
              child: const Text('Delete All'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      int deleted = 0;
      for (final file in files) {
        try {
          await file.delete();
          deleted++;
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted $deleted exported files.'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppConstants.errorColor),
        );
      }
    }
  }

  void _confirmResetDatabase(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Everything?'),
        content: const Text(
          'This will permanently delete:\n\n'
          '• All enrolled students\n'
          '• All face embeddings\n'
          '• All attendance records\n'
          '• All subjects & sessions\n\n'
          'This action CANNOT be undone.\n'
          'Consider creating a backup first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final prefs = await SharedPreferences.getInstance();
                final allKeys = prefs.getKeys().toList();
                for (final key in allKeys) {
                  if (key == 'tts_enabled' ||
                      key == 'required_samples') {
                    continue; // Keep settings
                  }
                  await prefs.remove(key);
                }
                await _loadSettings();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data cleared. Settings preserved.'),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppConstants.errorColor),
                  );
                }
              }
            },
            child: const Text(
              'Reset All Data',
              style: TextStyle(color: AppConstants.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppConstants.blueGradient),
        ),
      ),
      body: AnimatedBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // ── Voice Feedback ──
            _sectionHeader('Voice Feedback', Icons.volume_up),
            Card(
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: 4,
              ),
              child: SwitchListTile(
                title: const Text(
                  'TTS Attendance Confirmation',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Speak student name when attendance is marked',
                  style: TextStyle(fontSize: 12, color: AppConstants.textTertiary),
                ),
                secondary: Icon(
                  _ttsEnabled ? Icons.record_voice_over : Icons.voice_over_off,
                  color: _ttsEnabled
                      ? AppConstants.primaryColor
                      : AppConstants.textTertiary,
                  size: 22,
                ),
                value: _ttsEnabled,
                activeThumbColor: AppConstants.primaryColor,
                onChanged: _toggleTts,
              ),
            ),

            const SizedBox(height: 8),

            // ── Data Management ──
            _sectionHeader('Data Management', Icons.storage),
            _buildDataCard(),

            const SizedBox(height: 8),

            // ── Model Information ──
            _sectionHeader('Models & Algorithms', Icons.memory),
            Card(
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: 4,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  children: [
                    _infoRow('Face Detector', 'Google ML Kit (MediaPipe)'),
                    const Divider(height: 1, color: AppConstants.dividerColor),
                    _infoRow('Embedding Model', 'FaceNet-128 (TFLite)'),
                    const Divider(height: 1, color: AppConstants.dividerColor),
                    _infoRow('Embedding Dimension', '128D vectors'),
                    const Divider(height: 1, color: AppConstants.dividerColor),
                    _infoRow('Matching Algorithm', 'KNN (Euclidean)'),
                    const Divider(height: 1, color: AppConstants.dividerColor),
                    _infoRow('Inference', 'XNNPack CPU, 4 threads'),
                    const Divider(height: 1, color: AppConstants.dividerColor),
                    _infoRow('Enrollment Samples', '${AppConstants.requiredEnrollmentSamples} per student'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Project Credits ──
            _sectionHeader('Project Credits', Icons.badge_outlined),
            Card(
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: 4,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  children: [
                    _creditPersonTile(
                      label: 'Supervision',
                      profile: _guruProfile,
                    ),
                    const Divider(height: 1, color: AppConstants.dividerColor),
                    _creditPersonTile(
                      label: 'Modelling',
                      profile: _shivaprasadProfile,
                    ),
                    const Divider(height: 1, color: AppConstants.dividerColor),
                    _creditPersonTile(
                      label: 'Developer',
                      profile: _sunilProfile,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── About ──
            _sectionHeader('About', Icons.info_outline),
            Card(
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: 4,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('App', AppConstants.appName),
                    const Divider(height: 1, color: AppConstants.dividerColor),
                    _infoRow('Version', AppConstants.appVersion),
                    const Divider(height: 1, color: AppConstants.dividerColor),
                    _infoRow('Storage', 'SharedPreferences (Offline)'),
                    const SizedBox(height: 12),
                    Text(
                      AppConstants.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textTertiary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                '© 2026 FAS',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppConstants.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Data Management Card ──
  Widget _buildDataCard() {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: 4,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Real data stats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.inputFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _miniStat('Students', _totalStudents.toString()),
                      _miniStat('Embeddings', _totalEmbeddings.toString()),
                      _miniStat('Records', _totalAttendance.toString()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _miniStat('Subjects', _totalSubjects.toString()),
                      _miniStat('Sessions', _totalSessions.toString()),
                      _miniStat('Size', _dataSize),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Backup
            _actionTile(
              icon: Icons.backup,
              title: 'Backup Database',
              subtitle: 'Export all data as JSON (shareable)',
              color: AppConstants.primaryColor,
              onTap: _backupDatabase,
            ),
            const Divider(height: 1, color: AppConstants.dividerColor),

            // Restore from backup file
            _actionTile(
              icon: Icons.restore,
              title: 'Restore From Backup',
              subtitle: 'Upload a JSON backup to restore app state',
              color: AppConstants.primaryColor,
              onTap: _restoreFromFile,
            ),
            const Divider(height: 1, color: AppConstants.dividerColor),

            // Merge from backup file
            _actionTile(
              icon: Icons.merge_type,
              title: 'Merge From Backup',
              subtitle: 'Add new data from JSON without erasing existing',
              color: AppConstants.primaryColor,
              onTap: _mergeFromFile,
            ),
            const Divider(height: 1, color: AppConstants.dividerColor),

            // Clear attendance only
            _actionTile(
              icon: Icons.event_busy,
              title: 'Clear Attendance Records',
              subtitle: 'Keep students, remove attendance & sessions',
              color: AppConstants.warningColor,
              onTap: _clearAttendanceOnly,
            ),
            const Divider(height: 1, color: AppConstants.dividerColor),

            // Delete exports
            _actionTile(
              icon: Icons.folder_delete,
              title: 'Delete Exported Files',
              subtitle: 'Remove all saved CSV and backup files',
              color: AppConstants.warningColor,
              onTap: _deleteExportedFiles,
            ),
            const Divider(height: 1, color: AppConstants.dividerColor),

            // Full reset
            _actionTile(
              icon: Icons.delete_forever,
              title: 'Reset All Data',
              subtitle: 'Delete everything — students, faces, attendance',
              color: AppConstants.errorColor,
              onTap: () => _confirmResetDatabase(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _creditPersonTile({
    required String label,
    required _CreditProfile profile,
  }) {
    return InkWell(
      onTap: () => _showCreditProfileDialog(profile),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'View Card',
              style: TextStyle(
                fontSize: 11,
                color: AppConstants.textTertiary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppConstants.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreditProfileDialog(_CreditProfile profile) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final cardBody = Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F1C31),
                Color(0xFF162B48),
                Color(0xFF10243C),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2F5E96).withValues(alpha: 0.30),
                blurRadius: 26,
                spreadRadius: -2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Stack(
            children: [
              Positioned(
                top: -78,
                right: -52,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x2E77B6E6), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -86,
                left: -60,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x1F5E8CC7), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      profile.photoAsset,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppConstants.inputFill,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppConstants.textSecondary,
                            size: 44,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9ED1FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...profile.descriptionLines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Icon(
                              Icons.circle,
                              size: 6,
                              color: Color(0xFF83BDEE),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              line,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFE9F4FF),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Color(0xFFE9F4FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: cardBody,
            ),
          ),
        );
      },
    );
  }

  // ── Helper Widgets ──

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppConstants.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppConstants.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color == AppConstants.errorColor
                          ? color
                          : AppConstants.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppConstants.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppConstants.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppConstants.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppConstants.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditProfile {
  const _CreditProfile({
    required this.fullName,
    required this.title,
    required this.photoAsset,
    required this.descriptionLines,
    this.frostyGlass = false,
  });

  final String fullName;
  final String title;
  final String photoAsset;
  final List<String> descriptionLines;
  final bool frostyGlass;
}
