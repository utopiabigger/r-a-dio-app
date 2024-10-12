import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:radio_app/services/radio_api_service.dart';

class PlayerScreen extends StatefulWidget {
  @override
  PlayerScreenState createState() => PlayerScreenState();
}

class PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final RadioApiService apiService = RadioApiService();
  bool isPlaying = false;
  String currentArtist = 'Loading...';
  String currentTitle = 'Loading...';
  String djName = 'Loading...';
  int listenerCount = 0;
  String djImageUrl = '';
  Duration? currentTrackDuration;
  String lastTrackId = '';
  StreamSubscription<Duration>? _positionSubscription;
  Timer? _periodicUpdateTimer;
  Timer? _frequentUpdateTimer;
  bool _isNearEndOfTrack = false;
  DateTime? currentTrackStartTime;
  Timer? _elapsedTimeTimer;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    fetchRadioInfo();
    _startPeriodicUpdates();
    _startElapsedTimeTimer();
  }

  void _startPeriodicUpdates() {
    _periodicUpdateTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      fetchRadioInfo();
    });
  }

  void _startFrequentUpdates() {
    _frequentUpdateTimer?.cancel();
    _frequentUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchRadioInfo();
    });
  }

  void _stopFrequentUpdates() {
    _frequentUpdateTimer?.cancel();
    _frequentUpdateTimer = null;
  }

  void _startElapsedTimeTimer() {
    _elapsedTimeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        // This will trigger a rebuild of the duration display
      });
    });
  }

  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.setUrl('https://relay0.r-a-d.io/main.mp3');
      _audioPlayer.playerStateStream.listen((playerState) {
        setState(() {
          isPlaying = playerState.playing;
        });
      });

      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        if (currentTrackDuration != null) {
          final remainingTime = currentTrackDuration! - position;
          if (remainingTime <= Duration(minutes: 1) && !_isNearEndOfTrack) {
            _isNearEndOfTrack = true;
            _startFrequentUpdates();
          } else if (remainingTime > Duration(minutes: 1) && _isNearEndOfTrack) {
            _isNearEndOfTrack = false;
            _stopFrequentUpdates();
          }
        }
        setState(() {
          // Update UI
        });
      });

      // Handle errors
      _audioPlayer.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace stackTrace) {
        print('A stream error occurred: $e');
      });

      // Request audio focus
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse('https://relay0.r-a-d.io/main.mp3')));
    } catch (e) {
      print("Error initializing audio player: $e");
    }
  }

  Future<void> fetchRadioInfo() async {
    try {
      final radioInfo = await apiService.getRadioInfo();
      final newTrackId = '${radioInfo['artist']}-${radioInfo['title']}';

      setState(() {
        currentArtist = radioInfo['artist'];
        currentTitle = radioInfo['title'];
        djName = radioInfo['dj_name'];
        listenerCount = radioInfo['listener_count'];
        djImageUrl = radioInfo['dj_image_url'];
        currentTrackDuration = Duration(seconds: radioInfo['duration'] ?? 0);

        if (newTrackId != lastTrackId) {
          lastTrackId = newTrackId;
          currentTrackStartTime = DateTime.fromMillisecondsSinceEpoch(radioInfo['start_time'] * 1000);
          _isNearEndOfTrack = false;
          _stopFrequentUpdates();
        }
      });
    } catch (e) {
      print('Error fetching radio info: $e');
      setState(() {
        currentArtist = 'Unable to load';
        currentTitle = 'Unable to load';
        djName = 'Unable to load';
        listenerCount = 0;
        djImageUrl = '';
        currentTrackDuration = null;
        lastTrackId = '';
      });
    }
  }

  Duration _getElapsedTime() {
    if (currentTrackStartTime == null) return Duration.zero;
    return DateTime.now().difference(currentTrackStartTime!);
  }

  double _calculateProgress() {
    if (currentTrackStartTime == null || currentTrackDuration == null) return 0.0;
    final elapsed = _getElapsedTime();
    return (elapsed.inMilliseconds / currentTrackDuration!.inMilliseconds).clamp(0.0, 1.0);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _periodicUpdateTimer?.cancel();
    _frequentUpdateTimer?.cancel();
    _elapsedTimeTimer?.cancel();
    _audioPlayer.dispose();
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
              height: 110, // Increased from 100 to 110 to accommodate the overflow
              decoration: BoxDecoration(
                color: Color(0xFF303030),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
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
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 4),
                              Text(
                                djName,
                                style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Listeners: $listenerCount",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 80), // Space for the image
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: -10, // Adjusted from -15 to -10
                    child: Container(
                      width: 110, // Reduced from 120 to 110
                      height: 110, // Reduced from 120 to 110
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
                        padding: EdgeInsets.only(top: 140), // Increased from 40 to 60
                        child: GestureDetector(
                          onTap: () {
                            if (isPlaying) {
                              _audioPlayer.pause();
                            } else {
                              _audioPlayer.play();
                            }
                          },
                          child: CustomPaint(
                            size: Size(100, 100),
                            painter: PlayPausePainter(isPlaying: isPlaying),
                          ),
                        ),
                      ),
                      // Spacer to push duration to bottom
                      Spacer(),
                      // Duration and progress bar
                      Padding(
                        padding: EdgeInsets.only(bottom: 120),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: _calculateProgress(),
                                backgroundColor: Colors.grey[700],
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${_formatDuration(_getElapsedTime())} / ${_formatDuration(currentTrackDuration ?? Duration.zero)}',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Now playing section
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        color: Color(0xFF1A1A1A),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Now Playing:",
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 3),
                            Text(
                              currentTitle,
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 3),
                            Text(
                              currentArtist,
                              style: TextStyle(fontSize: 18, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
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
