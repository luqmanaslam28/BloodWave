import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedCollection = "hospitals"; // default

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _updateStatus(
      String collection, String docId, String status) async {
    await _firestore.collection(collection).doc(docId).update({
      'status': status.toLowerCase(),
    });
  }

  Stream<QuerySnapshot> _getRequests(String status) {
    return _firestore
        .collection(_selectedCollection)
        .where('status', isEqualTo: status.toLowerCase())
        .snapshots();
  }

  // ---------------------
  // Show Popup with Full Details
  // ---------------------
  void _showDetailsDialog(String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';

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
                    (data['organizationName'] ?? 'Organization')
                        .toString()
                        .toUpperCase(),
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
                        _buildDetailCard("Organization Type", data['orgType']),
                        _buildDetailCard("Email", data['email']),
                        _buildDetailCard("City", data['city']),
                        _buildDetailCard("Province", data['province']),
                        _buildDetailCard("Address", data['address']),
                        _buildDetailCard("Postal Code", data['postalCode']),
                        _buildDetailCard("License", data['license']),
                        _buildDetailCard(
                          "Phones",
                          (data['phones'] != null && data['phones'] is List)
                              ? (data['phones'] as List).join(", ")
                              : "No Contact",
                        ),
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
                      if (status == 'pending') ...[
                        _actionButton(
                            "Approve",
                            Colors.green,
                            () => _updateStatus(
                                _selectedCollection, docId, 'approved')),
                        _actionButton(
                            "Reject",
                            Colors.red,
                            () => _updateStatus(
                                _selectedCollection, docId, 'rejected')),
                      ] else if (status == 'approved') ...[
                        _actionButton(
                            "Mark Pending",
                            Colors.orange,
                            () => _updateStatus(
                                _selectedCollection, docId, 'pending')),
                        _actionButton(
                            "Reject",
                            Colors.red,
                            () => _updateStatus(
                                _selectedCollection, docId, 'rejected')),
                      ] else if (status == 'rejected') ...[
                        _actionButton(
                            "Mark Pending",
                            Colors.orange,
                            () => _updateStatus(
                                _selectedCollection, docId, 'pending')),
                        _actionButton(
                            "Approve",
                            Colors.green,
                            () => _updateStatus(
                                _selectedCollection, docId, 'approved')),
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

  Widget _buildRequestList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getRequests(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading data"));
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return Center(child: Text("No $status requests."));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final doc = requests[index];
            final data = doc.data() as Map<String, dynamic>;

            final orgName = (data['organizationName'] ?? 'No Name')
                .toString()
                .toUpperCase();

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(orgName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Tap to view details"),
                onTap: () => _showDetailsDialog(doc.id, data),
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Approval Panel'),
        actions: [
          DropdownButton<String>(
            value: _selectedCollection,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: "hospitals",
                child: Text("Hospitals"),
              ),
              DropdownMenuItem(
                value: "bloodbanks",
                child: Text("Blood Banks"),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCollection = value;
                });
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
          _buildRequestList('pending'),
          _buildRequestList('approved'),
          _buildRequestList('rejected'),
        ],
      ),
    );
  }
}
