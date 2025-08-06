import 'package:flutter/material.dart';
import '../../domain/repositories/download_repository.dart';
import '../../service_locator.dart';
import '../config/theme/app_color.dart';

class DownloadStatusIndicator extends StatefulWidget {
  final String reciterId;
  final int surahNumber;
  final Widget Function(bool isDownloaded) builder;

  const DownloadStatusIndicator({
    super.key,
    required this.reciterId,
    required this.surahNumber,
    required this.builder,
  });

  @override
  State<DownloadStatusIndicator> createState() =>
      _DownloadStatusIndicatorState();
}

class _DownloadStatusIndicatorState extends State<DownloadStatusIndicator> {
  late Future<bool> _downloadStatusFuture;

  @override
  void initState() {
    super.initState();
    _loadDownloadStatus();
  }

  void _loadDownloadStatus() {
    _downloadStatusFuture = locator<DownloadRepository>().isSurahDownloaded(
      widget.reciterId,
      widget.surahNumber,
    );
  }

  @override
  void didUpdateWidget(DownloadStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reciterId != widget.reciterId ||
        oldWidget.surahNumber != widget.surahNumber) {
      _loadDownloadStatus();
    }
  }

  void refresh() {
    setState(() {
      _loadDownloadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _downloadStatusFuture,
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;
        return widget.builder(isDownloaded);
      },
    );
  }
}

class DownloadStatusIcon extends StatelessWidget {
  final String reciterId;
  final int surahNumber;
  final double size;

  const DownloadStatusIcon({
    super.key,
    required this.reciterId,
    required this.surahNumber,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return DownloadStatusIndicator(
      reciterId: reciterId,
      surahNumber: surahNumber,
      builder: (isDownloaded) {
        if (!isDownloaded) return const SizedBox.shrink();

        return Icon(
          Icons.download_done,
          size: size,
          color: AppColor.primaryGreen,
        );
      },
    );
  }
}
