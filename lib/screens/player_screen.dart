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
    _elapsedTimeTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
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
                            Container(
                              width: MediaQuery.of(context).size.width,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: LinearProgressIndicator(
                                value: _calculateProgress(),
                                backgroundColor: Colors.grey[700],
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                minHeight: 5,
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
