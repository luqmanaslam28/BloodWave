import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class RequestBloodForm extends StatefulWidget {
  final String donorCity;
  final String donorId;

  const RequestBloodForm({
    super.key,
    required this.donorCity,
    required this.donorId,
  });

  @override
  State<RequestBloodForm> createState() => _RequestBloodFormState();
}

class OrgOption {
  final String id;
  final String name;
  final String orgType; // Hospital / Bloodbank

  OrgOption({required this.id, required this.name, required this.orgType});
}

class _RequestBloodFormState extends State<RequestBloodForm> {
  String? selectedOrgType;
  OrgOption? selectedOrg;
  String? selectedUrgency;
  bool _isSubmitting = false;

  late Future<List<OrgOption>> _orgsFuture;

  final List<String> urgencyOptions = [
    "ASAP",
    "Within 1 Hour",
    "Within 2 Hours",
    "Urgent",
  ];

  @override
  void initState() {
    super.initState();
    _orgsFuture = Future.value([]);
  }

  Future<List<OrgOption>> _fetchOrganizations(String city, String orgType) async {
    final fs = FirebaseFirestore.instance;
    final colName = orgType == "Hospital" ? "hospitals" : "bloodbank";

    final snap = await fs
        .collection(colName)
        .where('status', isEqualTo: 'approved')
        .get();

    final lowerCity = city.toLowerCase();

    final docs = snap.docs.where((d) {
      final data = d.data();
      final c = (data['city'] ?? '').toString().toLowerCase();
      return c == lowerCity;
    }).toList();

    return docs.map((d) {
      final data = d.data();
      return OrgOption(
        id: d.id,
        name: data['organizationName'] ?? "Unnamed",
        orgType: orgType,
      );
    }).toList();
  }

  Future<void> _submitRequest(BuildContext context) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User not logged in!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String collectionName =
          selectedOrg!.orgType == "Hospital" ? "hospitals" : "bloodbank";

      final orgDoc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(selectedOrg!.id)
          .get();

      final ownerId = orgDoc.data()?['userId'] ?? "";

      await FirebaseFirestore.instance.collection('blood_requests').add({
        'userId': currentUser.uid,
        'donorId': widget.donorId,
        'city': widget.donorCity,
        'orgId': selectedOrg!.id,
        'orgType': selectedOrg!.orgType,
        'orgName': selectedOrg!.name,
        'urgency': selectedUrgency,
        'ownerId': ownerId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen(name: '')),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.donorCity;

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
          iconTheme: const IconThemeData(color: Colors.black87),
          title: const Text(
            "Request Blood",
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.bloodtype, size: 80, color: Colors.redAccent),
              const SizedBox(height: 15),
              Text(
                "You are requesting blood in $city",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),

              // Org Type Selector
              _buildCard(
                child: DropdownButtonFormField<String>(
                  value: selectedOrgType,
                  items: ["Hospital", "Bloodbank"]
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedOrgType = value;
                      selectedOrg = null;
                      selectedUrgency = null;
                      if (value != null) {
                        _orgsFuture = _fetchOrganizations(city, value);
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Select Organization Type",
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Org Selector
              if (selectedOrgType != null)
                _buildCard(
                  child: FutureBuilder<List<OrgOption>>(
                    future: _orgsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        );
                      }

                      final orgs = snapshot.data ?? [];
                      if (orgs.isEmpty) {
                        return const Text(
                          "No organizations found in this city.",
                          style: TextStyle(color: Colors.grey),
                        );
                      }

                      return DropdownButtonFormField<OrgOption>(
                        value: selectedOrg,
                        items: orgs.map((org) {
                          return DropdownMenuItem<OrgOption>(
                            value: org,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  org.orgType == 'Hospital'
                                      ? Icons.local_hospital
                                      : Icons.bloodtype,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    org.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => selectedOrg = value),
                        decoration: const InputDecoration(
                          labelText: "Select Organization",
                          border: InputBorder.none,
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),

              // Urgency Selector
              if (selectedOrg != null)
                _buildCard(
                  child: DropdownButtonFormField<String>(
                    value: selectedUrgency,
                    items: urgencyOptions
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedUrgency = v),
                    decoration: const InputDecoration(
                      labelText: "When do you need it?",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              const SizedBox(height: 30),

              // Submit Button
              if (selectedOrg != null && selectedUrgency != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isSubmitting ? null : () => _submitRequest(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Submit Request",
                            style: TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card-style wrapper for inputs
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: child,
      ),
    );
  }
}
