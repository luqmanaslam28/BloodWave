import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DonorApprovalScreen extends StatefulWidget {
  const DonorApprovalScreen({super.key});

  @override
  State<DonorApprovalScreen> createState() => _DonorApprovalScreenState();
}

class _DonorApprovalScreenState extends State<DonorApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _updateStatus(String docId, String status) async {
    await _firestore.collection('donation_requests').doc(docId).update({
      'status': status.toLowerCase(),
    });
  }

  Stream<List<Map<String, dynamic>>> _getDonorsByStatus(String status) {
    return _firestore
        .collection('donation_requests')
        .where('status', isEqualTo: status.toLowerCase())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'docId': doc.id,
              })
          .toList();
    });
  }

  // -------------------------
  // Show Donor Details Dialog
  // -------------------------
  void _showDetailsDialog(Map<String, dynamic> donor) {
    final donorStatus = donor['status'] ?? 'pending';
    final isPaid =
        donor['donation_type']?.toString().toLowerCase() == 'paid';
    final answers = donor['answers'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Text(
                    (donor['name'] ?? 'Donor').toString().toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailCard(
                            "Blood Group", donor['blood_group']),
                        _buildDetailCard(
                            "Donation Type",
                            isPaid
                                ? "Paid (${donor['expected_amount'] ?? 'N/A'})"
                                : "Free"),
                        _buildDetailCard("City", donor['city']),
                        
                        const SizedBox(height: 10),
                        const Text(
                          "Eligibility Answers:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        ...answers.entries.map((entry) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              dense: true,
                              title: Text(entry.key),
                              trailing: Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  color: entry.value.toString().toLowerCase() ==
                                          'yes'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (donorStatus == 'pending') ...[
                        _actionButton(
                            "Approve",
                            Colors.green,
                            () => _updateStatus(donor['docId'], 'approved')),
                        _actionButton(
                            "Reject",
                            Colors.red,
                            () => _updateStatus(donor['docId'], 'rejected')),
                      ] else if (donorStatus == 'approved') ...[
                        _actionButton(
                            "Mark Pending",
                            Colors.orange,
                            () => _updateStatus(donor['docId'], 'pending')),
                        _actionButton(
                            "Reject",
                            Colors.red,
                            () => _updateStatus(donor['docId'], 'rejected')),
                      ] else if (donorStatus == 'rejected') ...[
                        _actionButton(
                            "Mark Pending",
                            Colors.orange,
                            () => _updateStatus(donor['docId'], 'pending')),
                        _actionButton(
                            "Approve",
                            Colors.green,
                            () => _updateStatus(donor['docId'], 'approved')),
                      ],
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(String label, dynamic value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                "$label:",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                value?.toString() ?? "-",
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: () {
        onPressed();
        Navigator.pop(context);
      },
      child: Text(text),
    );
  }

  Widget _buildDonorList(String status) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getDonorsByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final donors = snapshot.data ?? [];
        if (donors.isEmpty) {
          return Center(child: Text("No $status donors found."));
        }

        return ListView.builder(
          itemCount: donors.length,
          itemBuilder: (context, index) {
            final donor = donors[index];
            final donorName = (donor['name'] ?? 'No Name').toString();

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(
                  donorName.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Tap to view details"),
                onTap: () => _showDetailsDialog(donor),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donor Approvals'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.redAccent,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDonorList('pending'),
          _buildDonorList('approved'),
          _buildDonorList('rejected'),
        ],
      ),
    );
  }
}
