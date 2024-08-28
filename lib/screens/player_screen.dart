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
  Timer? updateTimer;
  String djImageUrl = '';

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    fetchRadioInfo();
    startPeriodicUpdates();
  }

  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.setUrl('https://relay0.r-a-d.io/main.mp3');
      _audioPlayer.playerStateStream.listen((playerState) {
        setState(() {
          isPlaying = playerState.playing;
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

  void startPeriodicUpdates() {
    updateTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchRadioInfo();
    });
  }

  Future<void> fetchRadioInfo() async {
    try {
      final radioInfo = await apiService.getRadioInfo();
      setState(() {
        currentArtist = radioInfo['artist'];
        currentTitle = radioInfo['title'];
        djName = radioInfo['dj_name'];
        listenerCount = radioInfo['listener_count'];
        djImageUrl = radioInfo['dj_image_url'];
      });
    } catch (e) {
      print('Error fetching radio info: $e');
      setState(() {
        currentArtist = 'Unable to load';
        currentTitle = 'Unable to load';
        djName = 'Unable to load';
        listenerCount = 0;
        djImageUrl = '';
      });
    }
  }

  @override
  void dispose() {
    updateTimer?.cancel();
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
        backgroundColor: Colors.grey[900],
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade800, Colors.red.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(djImageUrl),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "DJ: $djName",
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.headset, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "$listenerCount",
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: IconButton(
                iconSize: 100,
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.red,
                ),
                onPressed: () {
                  if (isPlaying) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.play();
                  }
                },
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            color: Colors.grey[900],
            child: Column(
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
                ),
                SizedBox(height: 3),
                Text(
                  currentArtist,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
