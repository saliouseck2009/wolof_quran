import 'package:flutter/material.dart';
import '../widgets/ayah_play_button.dart';

/// Example of how to use AyahPlayButton in any page
/// This demonstrates the reusability of the component
class ExampleUsageOfAyahPlayButton extends StatelessWidget {
  const ExampleUsageOfAyahPlayButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayah Play Button Examples')),
      body: Column(
        children: [
          // Example 1: Simple usage
          ListTile(
            title: const Text('Al-Fatiha, Ayah 1'),
            subtitle: const Text('In the name of Allah...'),
            trailing: const AyahPlayButton(
              surahNumber: 1,
              ayahNumber: 1,
              surahName: 'Al-Fatiha',
            ),
          ),

          // Example 2: Custom size and color
          ListTile(
            title: const Text('Al-Baqarah, Ayah 255 (Ayat al-Kursi)'),
            subtitle: const Text('Allah - there is no deity except Him...'),
            trailing: const AyahPlayButton(
              surahNumber: 2,
              ayahNumber: 255,
              surahName: 'Al-Baqarah',
              size: 32.0,
              color: Colors.blue,
            ),
          ),

          // Example 3: In a custom card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Al-Ikhlas, Ayah 1',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Say, "He is Allah, [who is] One"'),
                      ],
                    ),
                  ),
                  const AyahPlayButton(
                    surahNumber: 112,
                    ayahNumber: 1,
                    surahName: 'Al-Ikhlas',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
