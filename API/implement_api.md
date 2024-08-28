# Implementing r-a-d.io API in the Flutter App

This document outlines the steps to implement the r-a-d.io API in our Flutter application to fetch and display current track information.

## 1. Add HTTP Package

First, add the `http` package to your `pubspec.yaml` file:

yaml
dependencies:
http: ^0.13.5

Run `flutter pub get` to install the package.

## 2. Create API Service

Create a new file `lib/services/radio_api_service.dart`:

```
dart
import 'dart:convert';
import 'package:http/http.dart' as http;
class RadioApiService {
static const String apiUrl = 'https://r-a-d.io/api';
Future<Map<String, dynamic>> getCurrentTrack() async {
final response = await http.get(Uri.parse(apiUrl));
if (response.statusCode == 200) {
final data = json.decode(response.body);
final np = data['main']['np'];
final [artist, title] = np.split(' - ');
return {
'artist': artist,
'title': title,
};
} else {
throw Exception('Failed to load track info');
}
}
}
```

## 3. Update PlayerScreen

Modify `lib/screens/player_screen.dart` to use the API service:

```
dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:radio_app/services/radio_api_service.dart';
class PlayerScreen extends StatefulWidget {
@override
PlayerScreenState createState() => PlayerScreenState();
}
class PlayerScreenState extends State<PlayerScreen> {
final AudioPlayer audioPlayer = AudioPlayer();
final RadioApiService apiService = RadioApiService();
bool isPlaying = false;
String currentArtist = 'Loading...';
String currentTitle = 'Loading...';
@override
void initState() {
super.initState();
initAudioPlayer();
fetchTrackInfo();
}
// ... (keep existing initAudioPlayer and dispose methods)
Future<void> fetchTrackInfo() async {
try {
final trackInfo = await apiService.getCurrentTrack();
setState(() {
currentArtist = trackInfo['artist'];
currentTitle = trackInfo['title'];
});
} catch (e) {
print('Error fetching track info: $e');
}
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
// ... (rest of your existing UI)
],
),
),
backgroundColor: Colors.black,
);
}
}
```


## 4. Implement Periodic Updates

To keep the track information up-to-date, you can implement periodic updates:

```
dart
class PlayerScreenState extends State<PlayerScreen> {
// ... (existing code)
Timer? updateTimer;
@override
void initState() {
super.initState();
initAudioPlayer();
fetchTrackInfo();
startPeriodicUpdates();
}
void startPeriodicUpdates() {
updateTimer = Timer.periodic(Duration(seconds: 30), (timer) {
fetchTrackInfo();
});
}
@override
void dispose() {
updateTimer?.cancel();
audioPlayer.dispose();
super.dispose();
}
// ... (rest of the existing code)
}
```

This implementation will fetch the current track information every 30 seconds.

## 5. Error Handling

Implement error handling to manage API request failures:

```
dart
Future<void> fetchTrackInfo() async {
try {
final trackInfo = await apiService.getCurrentTrack();
setState(() {
currentArtist = trackInfo['artist'];
currentTitle = trackInfo['title'];
});
} catch (e) {
print('Error fetching track info: $e');
setState(() {
currentArtist = 'Unable to load';
currentTitle = 'Unable to load';
});
}
}
```

These changes will integrate the r-a-d.io API into your Flutter app, allowing you to display and update the current track information.