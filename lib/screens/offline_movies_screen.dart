import 'package:flutter/material.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import '../models/offline_movie.dart';
import '../services/database_service.dart';
import '../services/download_manager.dart';
import '../services/localization_service.dart';

class OfflineMoviesScreen extends StatefulWidget {
  const OfflineMoviesScreen({super.key});

  @override
  State<OfflineMoviesScreen> createState() => _OfflineMoviesScreenState();
}

class _OfflineMoviesScreenState extends State<OfflineMoviesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final DownloadManager _downloadManager = DownloadManager();
  List<OfflineMovie> _offlineMovies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfflineMovies();
  }

  Future<void> _loadOfflineMovies() async {
    try {
      final movies = await _databaseService.getOfflineMovies();
      setState(() {
        _offlineMovies = movies.where((movie) => movie.isDownloaded).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${LocalizationService().t('error')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteMovie(OfflineMovie movie) async {
    try {
      await _downloadManager.deleteDownloadedMovie(movie.id);
      await _loadOfflineMovies();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService().t('movie_deleted_successfully')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${LocalizationService().t('error')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Movies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOfflineMovies,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offlineMovies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No offline movies found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Download movies to watch offline',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _offlineMovies.length,
                  itemBuilder: (context, index) {
                    final movie = _offlineMovies[index];
                    return _buildMovieCard(movie);
                  },
                ),
    );
  }

  Widget _buildMovieCard(OfflineMovie movie) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(
            File(movie.coverPath),
            width: 50,
            height: 75,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 50,
                height: 75,
                color: Colors.grey,
                child: const Icon(Icons.movie, color: Colors.white),
              );
            },
          ),
        ),
        title: Text(
          movie.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quality: ${movie.quality}'),
            Text('Size: ${_formatFileSize(movie.fileSize)}'),
            Text('Downloaded: ${_formatDate(movie.downloadDate)}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Play'),
              onTap: () => _playMovie(movie),
            ),
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: () => _deleteMovie(movie),
            ),
          ],
        ),
      ),
    );
  }

  void _playMovie(OfflineMovie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfflineVideoPlayerScreen(
          filePath: movie.filePath,
          movieTitle: movie.title,
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (bytes.toString().length - 1) ~/ 3;
    var size = bytes / (1024 * 1024 * 1024);
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class OfflineVideoPlayerScreen extends StatefulWidget {
  final String filePath;
  final String movieTitle;

  const OfflineVideoPlayerScreen({
    required this.filePath,
    required this.movieTitle,
    super.key,
  });

  @override
  State<OfflineVideoPlayerScreen> createState() =>
      _OfflineVideoPlayerScreenState();
}

class _OfflineVideoPlayerScreenState extends State<OfflineVideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isBuffering = true;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isBuffering = false;
            _controller.setLooping(true);
            _controller.play();
          });
        }
      }).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تحميل الفيديو: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });

    _controller.addListener(() {
      if (!_controller.value.isBuffering && _isBuffering) {
        if (mounted) {
          setState(() {
            _isBuffering = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inHours > 0 ? '$hours:' : ''}$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.movieTitle),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // فيديو اللاعب
            Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
            ),

            // أزرار التحكم
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // شريط التقدم
                      if (_controller.value.isInitialized)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: VideoProgressColors(
                              playedColor: Colors.orange,
                              bufferedColor:
                                  Colors.orange.withValues(alpha: 0.5),
                              backgroundColor: Colors.grey,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // العروض الزمنية والأزرار
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_controller.value.position),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(_controller.value.duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // أزرار التحكم
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.replay_10,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _controller.seekTo(
                                _controller.value.position -
                                    const Duration(seconds: 10),
                              );
                            },
                          ),
                          const SizedBox(width: 20),
                          FloatingActionButton(
                            backgroundColor: Colors.orange,
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                            child: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(
                              Icons.forward_10,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _controller.seekTo(
                                _controller.value.position +
                                    const Duration(seconds: 10),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
