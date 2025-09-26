import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  // Org controllers
  final TextEditingController _orgNameController = TextEditingController();
  final TextEditingController _orgTypeController = TextEditingController();
  final TextEditingController _orgEmailController = TextEditingController();
  final TextEditingController _orgLicenseController = TextEditingController();
  final TextEditingController _orgAddressController = TextEditingController();
  final TextEditingController _orgCityController = TextEditingController();
  final TextEditingController _orgProvinceController = TextEditingController();
  final TextEditingController _orgPostalController = TextEditingController();
  final TextEditingController _orgStatusController = TextEditingController();
  final TextEditingController _orgPhoneController = TextEditingController();

  bool isLoading = true;
  bool isSavingUser = false;
  bool isSavingOrg = false;

  String? orgDocId;
  String? orgCollection; // hospitals OR bloodbanks

  @override
  void initState() {
    super.initState();
    fetchUserAndOrgData();
  }

  Future<void> fetchUserAndOrgData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Fetch user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _contactController.text = data['contactNumber'] ?? ''; // ✅ fixed
          _cityController.text = data['city'] ?? '';
        }
      }

      // Check hospitals
      final hospitalDoc = await _firestore
          .collection('hospitals')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (hospitalDoc.docs.isNotEmpty) {
        orgDocId = hospitalDoc.docs.first.id;
        orgCollection = "hospitals";
        final data = hospitalDoc.docs.first.data();
        fillOrgControllers(data);
      } else {
        // Check bloodbanks
        final bloodbankDoc = await _firestore
            .collection('bloodbanks')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (bloodbankDoc.docs.isNotEmpty) {
          orgDocId = bloodbankDoc.docs.first.id;
          orgCollection = "bloodbanks";
          final data = bloodbankDoc.docs.first.data();
          fillOrgControllers(data);
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }

    setState(() => isLoading = false);
  }

  void fillOrgControllers(Map<String, dynamic> data) {
    _orgNameController.text = data['organizationName'] ?? '';
    _orgTypeController.text = data['orgType'] ?? '';
    _orgEmailController.text = data['email'] ?? '';
    _orgLicenseController.text = data['license'] ?? '';
    _orgAddressController.text = data['address'] ?? '';
    _orgCityController.text = data['city'] ?? '';
    _orgProvinceController.text = data['province'] ?? '';
    _orgPostalController.text = data['postalCode'] ?? '';
    _orgStatusController.text = data['status'] ?? '';
    if (data['phones'] != null && data['phones'].isNotEmpty) {
      _orgPhoneController.text = data['phones'][0];
    }
  }

  Future<void> saveUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => isSavingUser = true);

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'contactNumber': _contactController.text.trim(), // ✅ fixed
        'city': _cityController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User profile updated successfully")),
      );
    } catch (e) {
      debugPrint("Error saving user profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update user profile")),
      );
    }

    setState(() => isSavingUser = false);
  }

  Future<void> saveOrgData() async {
    if (orgDocId == null || orgCollection == null) return;

    setState(() => isSavingOrg = true);

    try {
      await _firestore.collection(orgCollection!).doc(orgDocId).update({
        'organizationName': _orgNameController.text.trim(),
        'orgType': _orgTypeController.text.trim(),
        'email': _orgEmailController.text.trim(),
        'license': _orgLicenseController.text.trim(),
        'address': _orgAddressController.text.trim(),
        'city': _orgCityController.text.trim(),
        'province': _orgProvinceController.text.trim(),
        'postalCode': _orgPostalController.text.trim(),
        'status': _orgStatusController.text.trim(),
        'phones': [_orgPhoneController.text.trim()],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Organization data updated successfully")),
      );
    } catch (e) {
      debugPrint("Error saving org profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update organization data")),
      );
    }

    setState(() => isSavingOrg = false);
  }

  Widget buildField(String label, TextEditingController controller,
      {bool editable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: !editable,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
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
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// User Fields
                    buildField("Full Name", _nameController),
                    buildField("Email", _emailController, editable: false),
                    buildField("Contact", _contactController),
                    buildField("City", _cityController),

                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: isSavingUser ? null : saveUserData,
                      child: isSavingUser
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Save User Data",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      "Organization",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Divider(thickness: 1),
                    const SizedBox(height: 10),

                    /// Organization Fields
                    buildField("Organization Name", _orgNameController),
                    buildField("Organization Type", _orgTypeController),
                    buildField("Email", _orgEmailController),
                    buildField("License", _orgLicenseController),
                    buildField("Address", _orgAddressController),
                    buildField("City", _orgCityController),
                    buildField("Province", _orgProvinceController),
                    buildField("Postal Code", _orgPostalController),
                    buildField("Status", _orgStatusController),
                    buildField("Phone", _orgPhoneController),

                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: isSavingOrg ? null : saveOrgData,
                      child: isSavingOrg
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Save Organization Data",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
