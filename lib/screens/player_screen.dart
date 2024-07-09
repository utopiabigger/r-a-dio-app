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
    await _audioPlayer.setUrl('https://relay0.r-a-d.io/main.mp3');
    _audioPlayer.playerStateStream.listen((playerState) {
      setState(() {
        isPlaying = playerState.playing;
      });
    });
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
        title: Text('R/a/dio'),
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
                  radius: 50,
                  backgroundImage: NetworkImage('https://via.placeholder.com/60'),
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