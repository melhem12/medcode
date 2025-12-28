import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Helper class for exporting files to device storage
class FileExportHelper {
  static Future<Directory> getExportDirectory() async {
    if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      debugPrint('📁 iOS Export Directory: ${dir.path}');
      return dir;
    } else if (Platform.isAndroid) {
      // Prefer a top-level /storage/.../medcode directory (outside Android/data)
      try {
        final topLevel = Directory('/storage/emulated/0/medcode');
        if (!await topLevel.exists()) {
          await topLevel.create(recursive: true);
          debugPrint('✅ Created top-level export directory: ${topLevel.path}');
        }
        debugPrint('📁 Android Export Directory (Top-level): ${topLevel.path}');
        return topLevel;
      } catch (e) {
        debugPrint('⚠️ Could not use top-level export dir: $e');
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

    final headers = data.first.keys.toList();
    final csvBuffer = StringBuffer();
    
    csvBuffer.writeln(headers.map((h) => _escapeCsvField(h)).join(','));
    
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
      if (fullPath.contains('MedCode_Exports')) {
        return 'Files app > Internal storage > Android > data > MedCode > files > MedCode_Exports';
      } else if (fullPath.contains('app_flutter')) {
        return 'Files app > Internal storage > Android > data > MedCode > app_flutter';
      }
      return 'Files app > Internal storage > Android > data > MedCode';
    }
    return fullPath;
  }
}
