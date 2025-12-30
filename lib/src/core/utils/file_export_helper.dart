import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper class for exporting files to device storage
class FileExportHelper {
  static const String _exportBaseDirKey = 'export_base_directory';
  static const String _medcodeMarker = '/Medcode';

  static Future<void> _ensureAndroidStoragePermission() async {
    if (!Platform.isAndroid) {
      return;
    }
    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) {
      return;
    }
    final storageStatus = await Permission.storage.request();
    if (!storageStatus.isGranted) {
      throw Exception('Storage permission denied');
    }
  }

  static String _normalizeMedcodeBase(String base) {
    final index = base.indexOf(_medcodeMarker);
    if (index != -1) {
      return base.substring(0, index + _medcodeMarker.length);
    }
    return base.endsWith(_medcodeMarker) ? base : '$base$_medcodeMarker';
  }

  static Future<String?> _getAndroidBaseDirectory() async {
    await _ensureAndroidStoragePermission();
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_exportBaseDirKey);
    if (cached != null && cached.isNotEmpty) {
      final normalized = _normalizeMedcodeBase(cached);
      if (normalized != cached) {
        await prefs.setString(_exportBaseDirKey, normalized);
      }
      return normalized;
    }
    final picked = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose export folder',
    );
    if (picked != null && picked.isNotEmpty) {
      final normalized = _normalizeMedcodeBase(picked);
      await prefs.setString(_exportBaseDirKey, normalized);
      return normalized;
    }
    return picked;
  }

  static Future<String> getAndroidExportDirectoryPath({
    required String subDir,
  }) async {
    await _ensureAndroidStoragePermission();
    final base = await _getAndroidBaseDirectory();
    if (base == null || base.isEmpty) {
      throw Exception('Export folder not selected');
    }
    final baseWithMedcode = _normalizeMedcodeBase(base);
    return '$baseWithMedcode/$subDir';
  }

  static Future<Directory> getExportDirectory() async {
    if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      debugPrint('📁 iOS Export Directory: ${dir.path}');
      return dir;
    } else if (Platform.isAndroid) {
      await _ensureAndroidStoragePermission();
      // For Android, prefer a user-selected directory (SAF)
      try {
        final base = await _getAndroidBaseDirectory();
        if (base != null && base.isNotEmpty) {
          final exportDir = Directory(_normalizeMedcodeBase(base));
          if (!await exportDir.exists()) {
            await exportDir.create(recursive: true);
          }
          debugPrint('📁 Android Export Directory (SAF): ${exportDir.path}');
          return exportDir;
        }
      } catch (e) {
        debugPrint('⚠️ Could not use SAF export dir: $e');
      }
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final exportDir = Directory('${externalDir.path}/MedCode_Exports');
          if (!await exportDir.exists()) {
            await exportDir.create(recursive: true);
          }
          debugPrint('📁 Android Export Directory (External Storage): ${exportDir.path}');
          return exportDir;
        }
      } catch (e) {
        debugPrint('⚠️ Android external storage not available: $e');
      }
      final dir = await getApplicationDocumentsDirectory();
      debugPrint('📁 Android Export Directory (App Documents): ${dir.path}');
      return dir;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      debugPrint('📁 Desktop/Web Export Directory: ${dir.path}');
      return dir;
    }
  }

  static Future<String> exportToCsv({
    required List<Map<String, dynamic>> data,
    required String fileName,
    String? directoryPath,
    bool includeHeaders = true,
  }) async {
    if (data.isEmpty) {
      throw Exception('No data to export');
    }

    final exportDir = directoryPath != null
        ? Directory(directoryPath)
        : await getExportDirectory();

    debugPrint('📂 Export directory path: ${exportDir.path}');
    debugPrint('📂 Export directory exists: ${await exportDir.exists()}');

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
      debugPrint('✅ Created export directory: ${exportDir.path}');
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final csvFileName = '${fileName}_$timestamp.csv';
    final file = File('${exportDir.path}/$csvFileName');
    
    debugPrint('📄 Full file path: ${file.path}');

    // Determine headers based on data structure
    // For medical codes: ensure code, description order
    // For contents: ensure section_label, system_title, category_title, subcategory_title, code_hint, page_marker order
    List<String> headers;
    if (data.isNotEmpty) {
      final firstRow = data.first;
      if (firstRow.containsKey('code') && firstRow.containsKey('description')) {
        // Medical codes format
        headers = ['code', 'description'];
      } else if (firstRow.containsKey('section_label')) {
        // Contents format
        headers = [
          'section_label',
          'system_title',
          'category_title',
          'subcategory_title',
          'code_hint',
          'page_marker',
        ];
      } else {
        // Fallback to original behavior
        headers = data.first.keys.toList();
      }
    } else {
      headers = [];
    }
    
    final csvBuffer = StringBuffer();
    
    // Add headers only if requested
    // Note: Contents import doesn't skip headers, so we don't include them for contents
    // Medical codes import skips headers, so we include them for medical codes
    if (includeHeaders) {
      csvBuffer.writeln(headers.map((h) => _escapeCsvField(h)).join(','));
    }
    
    for (final row in data) {
      final values = headers.map((header) {
        final value = row[header];
        return _escapeCsvField(value?.toString() ?? '');
      });
      csvBuffer.writeln(values.join(','));
    }

    await file.writeAsString(csvBuffer.toString());
    
    final fileExists = await file.exists();
    final fileSize = fileExists ? await file.length() : 0;
    debugPrint('✅ File written successfully: $fileExists');
    debugPrint('📊 File size: $fileSize bytes');
    debugPrint('📄 Final file path: ${file.path}');
    
    try {
      final files = exportDir.listSync();
      debugPrint('📋 Files in export directory (${files.length}):');
      for (var file in files) {
        debugPrint('   - ${file.path}');
      }
    } catch (e) {
      debugPrint('⚠️ Could not list directory files: $e');
    }

    return file.path;
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static String getDisplayPath(String fullPath) {
    if (Platform.isIOS) {
      return 'Files app > On My iPhone > MedCode';
    } else if (Platform.isAndroid) {
      if (fullPath.contains('/Medcode/contents')) {
        return 'Files app > Internal storage > Medcode > contents';
      } else if (fullPath.contains('/Medcode/medical_codes')) {
        return 'Files app > Internal storage > Medcode > medical_codes';
      } else if (fullPath.contains('/Medcode')) {
        return 'Files app > Internal storage > Medcode';
      } else if (fullPath.contains('MedCode_Exports')) {
        return 'Files app > Internal storage > Android > data > MedCode > files > MedCode_Exports';
      } else if (fullPath.contains('app_flutter')) {
        return 'Files app > Internal storage > Android > data > MedCode > app_flutter';
      }
      return 'Files app > Internal storage > Android > data > MedCode';
    }
    return fullPath;
  }
}
