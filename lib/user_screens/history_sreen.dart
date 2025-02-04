import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Donation History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_requests')
            .where('authorId',
                isEqualTo: currentUserId) // Only requests by the current user
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No donation history found'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final request = snapshot.data!.docs[index];
              final requestData = request.data() as Map<String, dynamic>;

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('blood_requests')
                    .doc(request.id)
                    .collection('replies')
                    .where('isOffer',
                        isEqualTo: true) // Only replies where isOffer is true
                    .get(),
                builder: (context, repliesSnapshot) {
                  if (repliesSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(title: Text('Loading...'));
                  }

                  if (!repliesSnapshot.hasData ||
                      repliesSnapshot.data!.docs.isEmpty) {
                    return SizedBox(); // Skip if no offers found
                  }

                  final replies = repliesSnapshot.data!.docs;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requestData['title'] ?? 'Blood Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...replies.map((reply) {
                        final replyData = reply.data() as Map<String, dynamic>;

                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  replyData['content'] ?? 'Offered help',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.person,
                                        size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      replyData['authorName'] ?? 'Anonymous',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Spacer(),
                                    Icon(Icons.access_time,
                                        size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      DateFormat('MMM dd, yyyy - HH:mm').format(
                                        (replyData['timestamp'] as Timestamp)
                                            .toDate(),
                                      ),
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      Divider(),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
