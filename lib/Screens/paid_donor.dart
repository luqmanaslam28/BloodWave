import 'package:bloodwave/Screens/RequestBloodForm.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaidDonorScreen extends StatelessWidget {
  const PaidDonorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB2EBF2), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Paid Blood Donors",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              shadows: [
                Shadow(
                  offset: Offset(1.2, 1.2),
                  blurRadius: 3,
                  color: Colors.black26,
                ),
              ],
              decoration: TextDecoration.underline,
              decorationColor: Colors.black12,
              decorationThickness: 1,
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('donation_requests')
              .where('donation_type', isEqualTo: 'paid')
              .where('status', isEqualTo: 'approved')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.red),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No paid donors available right now.",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              );
            }

            final donors = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: donors.length,
              itemBuilder: (context, index) {
                final donorData =
                    donors[index].data() as Map<String, dynamic>;
                final donorUid = donorData['uid'];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(donorUid)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) return const SizedBox();

                    final userData = userSnapshot.data!.data()
                            as Map<String, dynamic>? ??
                        {};
                    final contactNumber =
                        userData['contactNumber'] ?? 'N/A';

                    final name =
                        capitalizeName(donorData['name'] ?? 'Unknown');
                    final bloodGroup = donorData['blood_group'] ?? 'N/A';
                    final expectedAmount =
                        donorData['expected_amount']?.toString() ??
                            'Not specified';

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        onTap: () {
                          _showDonorDetails(
                              context, donorData, contactNumber);
                        },
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.red.shade100,
                          child: Text(
                            bloodGroup,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            const Text(
                              "Paid Donor",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Asking Amount: $expectedAmount",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.monetization_on,
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Popup for donor details (unchanged logic)
  void _showDonorDetails(
    BuildContext context,
    Map<String, dynamic> donor,
    String contactNumber,
  ) {
    final name = capitalizeName(donor['name'] ?? 'Unknown');
    final bloodGroup = donor['blood_group'] ?? 'N/A';
    final city = donor['city'] ?? 'N/A';
    final age = donor['age']?.toString() ?? 'N/A';
    final expectedAmount =
        donor['expected_amount']?.toString() ?? 'Not specified';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.red.shade100,
                  child: Text(
                    bloodGroup,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDetailRow("Blood Group", bloodGroup),
                _buildDetailRow("Age", age),
                _buildDetailRow("Contact", contactNumber),
                _buildDetailRow("City", city),
                _buildDetailRow("Asking Amount", expectedAmount),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RequestBloodForm(
                            donorCity: city,
                            donorId: donor['uid'],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.bloodtype, color: Colors.white),
                    label: const Text(
                      "Request Blood",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper widget for detail rows
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  static String capitalizeName(String name) {
    if (name.isEmpty) return name;
    return name
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }
}
