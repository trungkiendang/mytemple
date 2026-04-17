import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: AppTheme.darkWood,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('tapCount', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildMockLeaderboard();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
            return _buildMockLeaderboard();
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildLeaderboardItem(
                index + 1,
                data['displayName'] ?? 'Anonymous',
                data['tapCount'] ?? 0,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardItem(int rank, String name, int count) {
    Color rankColor = Colors.grey;
    if (rank == 1) rankColor = Colors.amber;
    if (rank == 2) rankColor = Colors.blueGrey;
    if (rank == 3) rankColor = Colors.brown;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rankColor,
          child: Text(
            rank.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          '$count taps',
          style: const TextStyle(
            color: AppTheme.woodBrown,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildMockLeaderboard() {
    final mockData = [
      {'name': 'Zen Master', 'count': 1500},
      {'name': 'Peaceful Soul', 'count': 1200},
      {'name': 'Mindful Walker', 'count': 950},
      {'name': 'Lotus Flower', 'count': 800},
      {'name': 'Morning Dew', 'count': 650},
      {'name': 'Golden Bell', 'count': 500},
      {'name': 'Silent Forest', 'count': 450},
      {'name': 'Mountain Peak', 'count': 300},
      {'name': 'River Flow', 'count': 250},
      {'name': 'Prototype User', 'count': 100},
    ];

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Showing Mock Data (Firebase not connected)',
            style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: mockData.length,
            itemBuilder: (context, index) {
              return _buildLeaderboardItem(
                index + 1,
                mockData[index]['name'] as String,
                mockData[index]['count'] as int,
              );
            },
          ),
        ),
      ],
    );
  }
}
