import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:radio_app/services/radio_api_service.dart';
import 'package:audio_service/audio_service.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final RadioApiService _apiService = RadioApiService();
  Timer? _periodicUpdateTimer;
  Timer? _elapsedTimeTimer;
  final PlayerScreenState _playerScreenState;

  AudioPlayerHandler(this._playerScreenState) {
    _player.playbackEventStream.listen(_broadcastState);
    _setupPeriodicUpdates();
    _setupPlaybackStateListener();
  }

  void _setupPlaybackStateListener() {
    _player.playerStateStream.listen((playerState) {
      _playerScreenState.updatePlayingState(playerState.playing);
    });
  }

  void _setupPeriodicUpdates() {
    _periodicUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      await _updateMetadata();
    });

    _elapsedTimeTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      _playerScreenState.updateUI();
    });
  }

  Future<void> _updateMetadata() async {
    try {
      final radioInfo = await _apiService.getRadioInfo();
      _playerScreenState.updateState(radioInfo);
      mediaItem.add(MediaItem(
        id: 'radio_stream',
        album: radioInfo['dj_name'],
        title: radioInfo['title'],
        artist: radioInfo['artist'],
        duration: Duration(seconds: radioInfo['duration'] ?? 0),
      ));
    } catch (e) {
      print('Error updating metadata: $e');
    }
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.pause,
        MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
      _playerScreenState.updatePlayingState(true);
    } catch (e) {
      print("Error playing: $e");
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
      _playerScreenState.updatePlayingState(false);
    } catch (e) {
      print("Error pausing: $e");
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.dispose();
    _periodicUpdateTimer?.cancel();
    _elapsedTimeTimer?.cancel();
  }

  Future<void> initialize() async {
    try {
      await _player.setUrl('https://relay0.r-a-d.io/main.mp3');
      await _updateMetadata();
    } catch (e) {
      print("Error initializing audio player: $e");
    }
  }
}

class PlayerScreen extends StatefulWidget {
  @override
  PlayerScreenState createState() => PlayerScreenState();
}

class PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayerHandler _audioHandler;
  bool isPlaying = false;
  String currentArtist = 'Loading...';
  String currentTitle = 'Loading...';
  String djName = 'Loading...';
  int listenerCount = 0;
  String djImageUrl = '';
  Duration? currentTrackDuration;
  DateTime? currentTrackStartTime;

  Duration _getElapsedTime() {
    if (currentTrackStartTime == null) return Duration.zero;
    return DateTime.now().difference(currentTrackStartTime!);
  }

  double _calculateProgress() {
    if (currentTrackStartTime == null || currentTrackDuration == null) return 0.0;
    final elapsed = _getElapsedTime();
    final progress = elapsed.inMilliseconds / currentTrackDuration!.inMilliseconds;
    return progress.clamp(0.0, 1.0);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void initState() {
    super.initState();
    _setupAudioHandler();
  }

  Future<void> _setupAudioHandler() async {
    try {
      _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(this),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.example.radio_app.channel.audio',
          androidNotificationChannelName: 'Radio playback',
          androidNotificationOngoing: true,
          androidNotificationIcon: 'mipmap/launcher_icon',
        ),
      );
      await _audioHandler.initialize();
      
      // Set up a periodic timer for UI updates
      Timer.periodic(Duration(milliseconds: 500), (timer) {
        if (mounted) {
          setState(() {
            // This will trigger a rebuild of the progress bar
          });
        }
      });
    } catch (e) {
      print('Error setting up audio handler: $e');
    }
  }

  void _handlePlayPause() async {
    try {
      if (isPlaying) {
        await _audioHandler.pause();
      } else {
        await _audioHandler.play();
      }
    } catch (e) {
      print("Error handling play/pause: $e");
    }
  }

  void updateState(Map<String, dynamic> radioInfo) {
    setState(() {
      currentArtist = radioInfo['artist'];
      currentTitle = radioInfo['title'];
      djName = radioInfo['dj_name'];
      listenerCount = radioInfo['listener_count'];
      djImageUrl = radioInfo['dj_image_url'];
      currentTrackDuration = Duration(seconds: radioInfo['duration'] ?? 0);
      currentTrackStartTime = DateTime.fromMillisecondsSinceEpoch(
          (radioInfo['start_time'] ?? 0) * 1000);
    });
  }

  void updatePlayingState(bool playing) {
    setState(() {
      isPlaying = playing;
    });
  }

  void updateUI() {
    if (mounted) {
      setState(() {
        // This will trigger a rebuild of the progress bar
      });
    }
  }

  @override
  void dispose() {
    _audioHandler.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: EdgeInsets.all(8.0),
          child: Image.asset('assets/icon.png'),
        ),
        title: Text('r/a/dio'),
        backgroundColor: Color(0xFF1A1A1A),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 16),
        child: Column(
          children: [
            SizedBox(height: 20),
            // DJ information bar
            Container(
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                color: Color(0xFF303030),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "You're listening to:",
                                style: TextStyle(
                                  fontSize: 16, 
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 2),
                              Text(
                                djName,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'NotoSans',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Listeners: $listenerCount",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 80),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 3,
                    top: -15,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(djImageUrl),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Play/Pause button
                      Padding(
                        padding: EdgeInsets.only(top: 200),
                        child: _buildPlayPauseButton(),
                      ),
                      Spacer(),
                      // Track info and duration bar section
                      Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            // Track info with horizontal scroll
                            Container(
                              width: MediaQuery.of(context).size.width,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      currentTitle,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                        fontFamily: 'NotoSans',
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      currentArtist,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontFamily: 'NotoSans',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Progress bar
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: LinearProgressIndicator(
                                  value: _calculateProgress(),
                                  backgroundColor: Colors.grey[700],
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  minHeight: 5,
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            // Duration text row
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_getElapsedTime()),
                                    style: TextStyle(
                                      color: Color(0xFF828282),
                                      fontSize: 12
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(currentTrackDuration ?? Duration.zero),
                                    style: TextStyle(
                                      color: Color(0xFF828282),
                                      fontSize: 12
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Color(0xFF111111),
    );
  }

  Widget _buildPlayPauseButton() {
    return GestureDetector(
      onTap: _handlePlayPause,
      child: SizedBox(
        width: 100,
        height: 100,
        child: CustomPaint(
          painter: PlayPausePainter(isPlaying: isPlaying),
        ),
      ),
    );
  }
}

class PlayPausePainter extends CustomPainter {
  final bool isPlaying;

  PlayPausePainter({required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    if (isPlaying) {
      // Draw pause icon
      canvas.drawRect(Rect.fromLTWH(size.width * 0.3, size.height * 0.25, size.width * 0.15, size.height * 0.5), paint);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.55, size.height * 0.25, size.width * 0.15, size.height * 0.5), paint);
    } else {
      // Draw play icon
      final path = Path();
      path.moveTo(size.width * 0.3, size.height * 0.25);
      path.lineTo(size.width * 0.3, size.height * 0.75);
      path.lineTo(size.width * 0.7, size.height * 0.5);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
