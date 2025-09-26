import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalDetailScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;

  const HospitalDetailScreen({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
  });

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen> {
  String? selectedType;

  final List<String> donationTypes = [
    "Whole Blood",
    "Plasma",
    "Platelets",
    "Red Cells",
  ];

  Stream<QuerySnapshot> _getInventory() {
    final query = FirebaseFirestore.instance
        .collection('blood_inventory')
        .where('orgId', isEqualTo: widget.hospitalId);

    if (selectedType != null) {
      return query.where('donationType', isEqualTo: selectedType).snapshots();
    } else {
      return query.snapshots();
    }
  }

  void _showInventorySheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(2, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text(
                  "Blood Inventory Details",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: [
                      _buildInfoTile(Icons.water_drop, "Blood Type",
                          item['bloodType']),
                      _buildInfoTile(Icons.local_hospital, "Donation Type",
                          item['donationType']),
                      _buildInfoTile(Icons.inventory, "Units",
                          item['units'].toString()),
                      _buildInfoTile(
                          Icons.calendar_today, "Date", item['date']),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.redAccent.withOpacity(0.15),
          child: Icon(icon, color: Colors.redAccent),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value, style: const TextStyle(color: Colors.black87)),
      ),
    );
  }

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
          title: Text(
            widget.hospitalName,
            style: const TextStyle(
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
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  labelText: "Select Required Type",
                  labelStyle: const TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 2,
                    ),
                  ),
                ),
                value: selectedType,
                items: [
                  const DropdownMenuItem<String>(
                    value: "All",
                    child: Text("All Types",
                        style: TextStyle(color: Colors.black)),
                  ),
                  ...donationTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child:
                          Text(type, style: const TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedType = value == "All" ? null : value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getInventory(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          selectedType == null
                              ? "No inventory available"
                              : "No $selectedType available",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }

                    final inventory = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: inventory.length,
                      itemBuilder: (context, index) {
                        final item =
                            inventory[index].data() as Map<String, dynamic>;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(2, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            leading: const Icon(Icons.bloodtype,
                                color: Colors.redAccent, size: 35),
                            title: Text(
                              "Blood Type: ${item['bloodType']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              "Donation Type: ${item['donationType']} - Units: ${item['units']}",
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 18, color: Colors.black54),
                            onTap: () => _showInventorySheet(item),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
