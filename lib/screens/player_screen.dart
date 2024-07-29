import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PlayerScreen extends StatefulWidget {
  @override
  PlayerScreenState createState() => PlayerScreenState();
}

class PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
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

  @override
  void dispose() {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You're listening to:",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 3),
            Row(
              children: [
                Text(
                  'Hanyuu-Sama',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                Spacer(),
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/hanyuu.png'),
                ),
              ],
            ),
            SizedBox(height: 20),
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
            // ... rest of your player screen implementation
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      leading: Image.asset('assets/icon.png'), // Add this line
      title: Text('r/a/dio'),
      backgroundColor: Colors.grey[900],
    ),
    // ... rest of your build method
  );
}
