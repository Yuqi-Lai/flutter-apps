import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('gamesWon', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading leaderboard',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create Firestore index: users collection, gamesWon (Descending)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return Center(
              child: Text(
                'No players yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>? ?? {};
              final displayName = userData['displayName'] ?? 'Anonymous';
              final gamesPlayed = userData['gamesPlayed'] ?? 0;
              final gamesWon = userData['gamesWon'] ?? 0;
              final gamesLost = userData['gamesLost'] ?? 0;
              final gamesDraw = userData['gamesDraw'] ?? 0;
              
              final winRate = gamesPlayed > 0 
                  ? ((gamesWon / gamesPlayed) * 100).toStringAsFixed(1)
                  : '0.0';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRankColor(index),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  title: Text(
                    displayName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Played: $gamesPlayed | Win Rate: $winRate%',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'W: $gamesWon',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'L: $gamesLost | D: $gamesDraw',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey[600]!; // Silver
      case 2:
        return Colors.brown; // Bronze
      default:
        return Colors.blue;
    }
  }
}

