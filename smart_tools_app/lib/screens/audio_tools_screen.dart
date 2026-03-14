import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class AudioToolsScreen extends StatefulWidget {
  const AudioToolsScreen({super.key});

  @override
  State<AudioToolsScreen> createState() => _AudioToolsScreenState();
}

class _AudioToolsScreenState extends State<AudioToolsScreen> {
  String _activeTab = 'trim';
  
  // Trim state
  File? _audioFile;
  double _trimStart = 0;
  double _trimEnd = 100;
  double _duration = 100;

  // Record state
  late AudioRecorder _recorder;
  bool _isRecording = false;
  String? _recordedPath;
  Duration _recordDuration = Duration.zero;
  bool _busy = false;

  // Player
  late AudioPlayer _player;
  bool _isPlaying = false;
  String? _currentPlayPath;

  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _player = AudioPlayer();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path!;
      
      setState(() {
        _audioFile = File(path);
        _error = null;
        _success = null;
        _trimStart = 0;
        _busy = true;
      });

      // Reset player and load source
      await _player.stop();
      await _player.setSource(DeviceFileSource(path));
      
      // Give it a moment to load
      await Future.delayed(const Duration(milliseconds: 500));
      final d = await _player.getDuration();
      
      setState(() {
        if (d != null && d.inMilliseconds > 0) {
          _duration = d.inMilliseconds.toDouble();
          _trimEnd = _duration;
        } else {
          // Fallback if metadata fails
          _duration = 100000; // 100s fallback
          _trimEnd = 100000;
        }
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل تحميل الملف الصوتي: $e';
        _busy = false;
      });
    }
  }

  Future<void> _playFile(String path) async {
    if (_isPlaying && _currentPlayPath == path) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(DeviceFileSource(path));
      setState(() { _isPlaying = true; _currentPlayPath = path; });
    }
  }

  Future<void> _saveFile(String path) async {
    setState(() { _error = null; _success = null; _busy = true; });

    try {
      final fileName = path.split('/').last;
      final extension = fileName.split('.').last;
      final bytes = await File(path).readAsBytes();

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكان حفظ الملف الصوتي',
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: [extension],
      );

      if (outputPath != null) {
        setState(() => _success = 'تم حفظ الملف الصوتي بنجاح ✓');
      }
    } catch (e) {
      setState(() => _error = 'حدث خطأ أثناء الحفظ. التفاصيل: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _trimAudio() async {
    if (_audioFile == null) return;
    setState(() { _busy = true; _error = null; _success = null; });
    
    try {
      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/trimmed_${DateTime.now().millisecondsSinceEpoch}.mp3';
      
      final start = _trimStart / 1000;
      final duration = (_trimEnd - _trimStart) / 1000;

      // ffmpeg command: -ss start -i input -t duration -c copy output
      // Note: -c copy is fast but might not be precise on some formats. 
      // Re-encoding is safer for precision.
      final command = '-ss $start -i "${_audioFile!.path}" -t $duration -c:a libmp3lame -q:a 2 "$outPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        await _saveFile(outPath);
      } else {
        final logs = await session.getLogs();
        final msg = logs.isNotEmpty ? logs.last.getMessage() : 'خطأ غير معروف';
        throw Exception('فشل القص: $msg');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _startRecording() async {
    setState(() { _error = null; _success = null; });
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      setState(() => _error = 'يجب منح صلاحية المايكروفون');
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordedPath = path;
      _recordDuration = Duration.zero;
    });

    _tickRecording();
  }

  void _tickRecording() async {
    while (_isRecording) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording) {
        setState(() => _recordDuration += const Duration(seconds: 1));
      }
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _recordedPath = path;
      _success = 'تم إيقاف التسجيل بنجاح';
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('أدوات الصوت')),
      body: ListView(
        children: [
          GradientHeroSection(
            title: 'أدوات الصوت الذكية',
            subtitle: 'تسجيل الصوت وقص الملفات الصوتية بسهولة.',
          ),

          // Tab Selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _tabButton('تسجيل صوت', 'record', Icons.mic_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _tabButton('قص صوتي', 'trim', Icons.content_cut_rounded)),
              ],
            ),
          ),

          if (_activeTab == 'record') _buildRecordTab(isDark),
          if (_activeTab == 'trim') _buildTrimTab(isDark),

          if (_error != null) StatusBanner(message: _error!, isError: true),
          if (_success != null) 
            StatusBanner(
              message: _success!,
              // We'll show the save button if there's a recorded path or audio file
              actionLabel: (_recordedPath != null && !_isRecording) ? 'حفظ التسجيل الآن' : null,
              onAction: (_recordedPath != null && !_isRecording) ? () => _saveFile(_recordedPath!) : null,
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _tabButton(String label, String tab, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? AppTheme.primary : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? Colors.white : null),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: active ? Colors.white : null)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            // Record Indicator
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? AppTheme.destructive.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.1),
                border: Border.all(
                  color: _isRecording ? AppTheme.destructive : AppTheme.primary,
                  width: 3,
                ),
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: 44,
                color: _isRecording ? AppTheme.destructive : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            if (_isRecording) ...[
              Text(_formatDuration(_recordDuration), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('جاري التسجيل...', style: TextStyle(fontSize: 13, color: AppTheme.destructive, fontWeight: FontWeight.w700)),
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? AppTheme.destructive : AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isRecording ? 'إيقاف التسجيل' : 'بدء التسجيل',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),

            if (_recordedPath != null && !_isRecording) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _playFile(_recordedPath!),
                      icon: Icon(_isPlaying && _currentPlayPath == _recordedPath ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      label: Text(_isPlaying && _currentPlayPath == _recordedPath ? 'إيقاف' : 'تشغيل'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _saveFile(_recordedPath!),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('حفظ في جهازي'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrimTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilePickerButton(
              title: _audioFile != null ? _audioFile!.path.split('/').last : 'اختر ملف صوتي',
              subtitle: 'MP3, WAV, M4A, OGG',
              icon: Icons.audiotrack_rounded,
              onTap: _pickAudio,
            ),

            if (_busy && _audioFile == null) 
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              
            if (_audioFile != null) ...[
              const SizedBox(height: 20),
              const Text('نطاق القص', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              RangeSlider(
                values: RangeValues(_trimStart, _trimEnd),
                min: 0,
                max: _duration,
                activeColor: AppTheme.primary,
                onChanged: (v) => setState(() {
                  _trimStart = v.start;
                  _trimEnd = v.end;
                }),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _digitalTimeController('البداية', _trimStart, (v) => setState(() => _trimStart = v.clamp(0, _trimEnd - 100)))),
                  const SizedBox(width: 8),
                  Expanded(child: _digitalTimeController('النهاية', _trimEnd, (v) => setState(() => _trimEnd = v.clamp(_trimStart + 100, _duration)))),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_audioFile != null && !_busy) ? _trimAudio : null,
                  icon: const Icon(Icons.content_cut_rounded),
                  label: Text(_busy ? 'جاري المعالجة...' : 'قص وحفظ في جهازي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _playFile(_audioFile!.path),
                      icon: Icon(_isPlaying && _currentPlayPath == _audioFile?.path ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      label: const Text('تشغيل الأصل'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _digitalTimeController(String label, double value, Function(double) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final display = (value / 1000).toStringAsFixed(2);
    
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => onChanged(value - 1000),
                icon: const Icon(Icons.remove_circle_outline, size: 16),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    display,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => onChanged(value + 1000),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
