import 'package:flutter/material.dart';

class PlayerScreen extends StatelessWidget {
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
            // ... rest of your player screen implementation
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}