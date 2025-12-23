import 'package:flutter/material.dart';

class AvatarSelectionScreen extends StatelessWidget {
  // List of available avatar image paths
  final List<String> avatars = const [
    'assets/images/gamer(1).png', // Add avatar image paths here
    'assets/images/gamer2.png',
    'assets/images/gamer3.png',
    'assets/images/gamer4.png',
    'assets/images/gamer5.png',
    'assets/images/gamer6.png',
    'assets/images/gamer7.png', // newly added image
    'assets/images/gamer8.png', // newly added image
    'assets/images/gamer9.png', // newly added image
    // Add more paths here depending on how many avatar images you have
  ];

  const AvatarSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // same dark background color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // return without selection
          },
        ),
        title: const Text('Select Avatar',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 columns
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: avatars.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.pop(context, avatars[index]); // Return selected avatar
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  avatars[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
