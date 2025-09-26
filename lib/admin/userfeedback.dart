import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Userfeedback extends StatefulWidget {
  const Userfeedback({super.key});

  @override
  State<Userfeedback> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<Userfeedback> {
  Map<String, String> userNames = {}; // userId -> userName

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    final Map<String, String> names = {};
    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      String name = data['name'] ?? 'Unknown User';
      names[doc.id] = _capitalize(name);
    }

    setState(() {
      userNames = names;
    });
  }

  String _capitalize(String name) {
    if (name.isEmpty) return name;
    return name
        .split(' ')
        .map((str) => str[0].toUpperCase() + str.substring(1))
        .join(' ');
  }

  void _showFeedbackDetails(Map<String, dynamic> feedback, String userName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Email : ',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: feedback['email'] ?? '-',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Contact : ',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: feedback['contactNumber'] ?? '-',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Feedback :',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  feedback['feedback'] ?? '-',
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'User Feedback',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.redAccent),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('feedback').snapshots(),
        builder: (context, feedbackSnapshot) {
          if (feedbackSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!feedbackSnapshot.hasData || feedbackSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No feedback found."));
          }

          final feedbackDocs = feedbackSnapshot.data!.docs;

          return ListView.builder(
            itemCount: feedbackDocs.length,
            itemBuilder: (context, index) {
              final feedbackData =
                  feedbackDocs[index].data() as Map<String, dynamic>;
              final userId = feedbackData['userId'] ?? '';
              final userName = userNames[userId] ?? 'Unknown User';
              final feedbackText = feedbackData['feedback'] ?? '';
              final snippet = feedbackText.length > 50
                  ? '${feedbackText.substring(0, 50)}...'
                  : feedbackText;

              return GestureDetector(
                onTap: () => _showFeedbackDetails(feedbackData, userName),
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: Colors.redAccent.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.feedback,
                                color: Colors.redAccent, size: 40),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snippet,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}