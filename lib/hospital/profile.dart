import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HospitalProfileScreen extends StatefulWidget {
  const HospitalProfileScreen({super.key});

  @override
  State<HospitalProfileScreen> createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends State<HospitalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  // Controllers
  final TextEditingController _orgNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _postalController = TextEditingController();

  final List<TextEditingController> _phoneControllers = [
    TextEditingController(),
  ];

  // Province–City Mapping
  final Map<String, List<String>> _provinceCities = {
    "Sindh": ["Karachi", "Hyderabad"],
    "Punjab": [
      "Lahore",
      "Rawalpindi",
      "Faisalabad",
      "Multan",
      "Sialkot",
      "Bahawalpur",
      "Sargodha",
      "Gujranwala",
    ],
    "Khyber Pakhtunkhwa": ["Peshawar", "Abbottabad", "Mardan"],
    "Balochistan": ["Quetta"],
    "Islamabad Capital Territory": ["Islamabad"],
  };

  String? _selectedProvince;
  String? _selectedCity;
  String? _orgType;
  bool _step1Done = false;

  // Request state
  // ignore: unused_field
  bool _loading = true;
  bool _requestSubmitted = false;
  String? _docId;
  String? _status;
  String? _collectionName;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _statusSub;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    _addressController.dispose();
    _licenseController.dispose();
    _emailController.dispose();
    _postalController.dispose();
    for (final c in _phoneControllers) {
      c.dispose();
    }
    _statusSub?.cancel();
    super.dispose();
  }

  Future<void> _checkExistingRequest() async {
    if (_user == null) {
      setState(() => _loading = false);
      return;
    }

    // Check hospitals
    final hospitalReq = await _firestore
        .collection('hospitals')
        .where('userId', isEqualTo: _user.uid)
        .limit(1)
        .get();

    if (hospitalReq.docs.isNotEmpty) {
      final doc = hospitalReq.docs.first;
      setState(() {
        _requestSubmitted = true;
        _docId = doc.id;
        _status = doc.data()['status'] ?? 'pending';
        _orgType = "Hospital";
        _collectionName = 'hospitals';
        _loading = false;
      });
      _startStatusListener('hospitals', doc.id);
      return;
    }

    // Check bloodbanks
    final bankReq = await _firestore
        .collection('bloodbanks')
        .where('userId', isEqualTo: _user.uid)
        .limit(1)
        .get();

    if (bankReq.docs.isNotEmpty) {
      final doc = bankReq.docs.first;
      setState(() {
        _requestSubmitted = true;
        _docId = doc.id;
        _status = doc.data()['status'] ?? 'pending';
        _orgType = "Blood Bank";
        _collectionName = 'bloodbanks';
        _loading = false;
      });
      _startStatusListener('bloodbanks', doc.id);
      return;
    }

    setState(() => _loading = false);
  }

  void _startStatusListener(String collection, String docId) {
    _statusSub?.cancel();
    _statusSub = _firestore
        .collection(collection)
        .doc(docId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final data = snap.data();
      final newStatus = (data?['status'] ?? 'pending') as String;
      if (mounted && newStatus != _status) {
        setState(() {
          _status = newStatus;
        });
        if (newStatus == 'approved') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your request has been approved ✅')),
          );
        } else if (newStatus == 'rejected') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your request was rejected.')),
          );
        }
      }
    });
  }

  Future<void> _saveProfile() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to submit.')),
      );
      return;
    }

    final isHospital = _orgType == "Hospital";
    final collection = isHospital ? 'hospitals' : 'bloodbanks';

    final data = <String, dynamic>{
      "userId": _user.uid,
      "orgType": _orgType,
      "organizationName": _orgNameController.text.trim(),
      "license": _licenseController.text.trim(),
      "province": _selectedProvince,
      "city": _selectedCity,
      "postalCode": _postalController.text.trim(),
      "address": _addressController.text.trim(),
      "email": _emailController.text.trim(),
      "phones": _phoneControllers.map((c) => c.text.trim()).toList(),
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    };

    try {
      final ref = await _firestore.collection(collection).add(data);
      setState(() {
        _requestSubmitted = true;
        _docId = ref.id;
        _status = "pending";
        _collectionName = collection;
      });
      _startStatusListener(collection, ref.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    }
  }

  Future<void> _cancelRequest() async {
    if (_docId == null || _collectionName == null) return;
    try {
      await _firestore.collection(_collectionName!).doc(_docId!).delete();
      _statusSub?.cancel();
      setState(() {
        _requestSubmitted = false;
        _docId = null;
        _status = null;
        _collectionName = null;
        _orgType = null;
        _step1Done = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your request has been cancelled.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel: $e')),
      );
    }
  }
  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.redAccent),
        title: const Text(
          "Hospital/Blood Bank Profile",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _user == null
            ? _buildLoginRequired()
            : _requestSubmitted
                ? _buildRequestStatus()
                : (!_step1Done ? _buildStep1() : _buildStep2()),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return const Center(
      child: Text(
        'Please log in to submit your organization profile.',
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Step 1 - Select Hospital or Blood Bank
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepCircle(1, "Select Type", true),
            Container(width: 40, height: 2, color: Colors.redAccent),
            _buildStepCircle(2, "Profile Form", false),
          ],
        ),
        const SizedBox(height: 40),
        const Icon(Icons.local_hospital, size: 90, color: Colors.redAccent),
        const SizedBox(height: 24),
        const Text(
          "Select Organization Type",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildChoiceButton("Hospital", Icons.local_hospital),
        const SizedBox(height: 12),
        _buildChoiceButton("Blood Bank", Icons.bloodtype),
      ],
    );
  }

  Widget _buildStepCircle(int step, String title, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: active ? Colors.redAccent : Colors.grey.shade300,
          child: Text(
            "$step",
            style: TextStyle(
              color: active ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: active ? Colors.redAccent : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceButton(String type, IconData icon) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(type, style: const TextStyle(fontSize: 16)),
      onPressed: () {
        setState(() {
          _orgType = type;
          _step1Done = true;
        });
      },
    );
  }

  // Step 2 - Full Profile Form
  Widget _buildStep2() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          Text(
            "${_orgType?.toUpperCase()} PROFILE",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionHeader("Organization Info"),
          _buildTextField(
            controller: _orgNameController,
            label: "Organization Name",
            icon: Icons.business,
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _licenseController,
            label: "License / Registration No",
            icon: Icons.confirmation_number,
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 20),

          _buildSectionHeader("Location Info"),
          DropdownButtonFormField<String>(
            value: _selectedProvince,
            items: _provinceCities.keys
                .map<DropdownMenuItem<String>>(
                  (String prov) => DropdownMenuItem<String>(
                    value: prov,
                    child: Text(prov),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedProvince = val!;
                _selectedCity = null;
              });
            },
            decoration: _inputDecoration("Province", Icons.map),
            validator: (v) => v == null ? "Select Province" : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCity,
            items: _selectedProvince == null
                ? []
                : _provinceCities[_selectedProvince]!
                    .map<DropdownMenuItem<String>>(
                      (String city) => DropdownMenuItem<String>(
                        value: city,
                        child: Text(city),
                      ),
                    )
                    .toList(),
            onChanged: (val) => setState(() => _selectedCity = val),
            decoration: _inputDecoration("City", Icons.location_city),
            validator: (v) => v == null ? "Select City" : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _postalController,
            label: "Postal Code",
            icon: Icons.markunread_mailbox,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.isEmpty) return "Required";
              if (!RegExp(r'^\d{5}$').hasMatch(v)) {
                return "Enter valid 5-digit postal code";
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressController,
            label: "Address",
            icon: Icons.home,
            maxLines: 2,
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 20),

          _buildSectionHeader("Contact Info"),
          _buildTextField(
            controller: _emailController,
            label: "Official Email",
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return "Required";
              if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v)) {
                return "Enter valid email";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          _buildSectionHeader("Phone Numbers"),
          ..._buildPhoneFields(),
          const SizedBox(height: 30),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _showDeclarationDialog();
              }
            },
            child: const Text("Submit Request", style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  /// Declaration Popup (on Agree → save and show pending)
  void _showDeclarationDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 60),
              const SizedBox(height: 16),
              const Text(
                "Declaration",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 12),
              const SingleChildScrollView(
                child: Text(
                  "I hereby declare that all the information I have provided is true and correct to the best of my knowledge.\n\n"
                  "If BloodWave finds any discrepancy or false information, the organization reserves the right to report me to the concerned authorities.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(context); // close dialog
                      if (_formKey.currentState!.validate()) {
                        await _saveProfile();
                      }
                    },
                    child: const Text("I Agree"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Pending Info Popup (after submission)
  // ignore: unused_element
  void _showPendingDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Request Submitted",
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Your request is pending approval. You will be notified once it's approved.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Request Status Screen (Pending/Approved/Rejected) + Cancel Request
Widget _buildRequestStatus() {
  final isApproved = _status == "approved";
  final isRejected = _status == "rejected";
  // ignore: unused_local_variable
  final isPending = _status == "pending" || _status == null;

  IconData icon;
  Color color;
  String title;
  String message;

  if (isApproved) {
    icon = Icons.verified;
    color = Colors.green;
    title = "Approved";
    message =
        "✅ Your request has been approved. You now have access as a ${_orgType ?? 'Organization'}.";
  } else if (isRejected) {
    icon = Icons.error_outline;
    color = Colors.redAccent;
    title = "Rejected";
    message =
        "Your request was rejected. Please contact support.";
  } else {
    icon = Icons.hourglass_bottom;
    color = Colors.orange;
    title = "Pending Approval";
    message =
        "Your request is pending for approval. You'll be notified once it's approved.";
  }

  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (_orgType != null)
                Text(
                  "Type: ${_orgType!}",
                  style: const TextStyle(fontSize: 13),
                ),
              if (_docId != null)
                Text(
                  "Ref ID: $_docId",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              const SizedBox(height: 20),

              // Cancel button (for pending or rejected, but not approved)
              if (!isApproved && !isRejected)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cancel),
                  label: const Text("Cancel Request"),
                  onPressed: _cancelRequest,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
  // Reusable Section Header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Reusable TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
    );
  }

  // Dynamic phone number fields with add & delete
  List<Widget> _buildPhoneFields() {
    final List<Widget> fields = [];
    for (int i = 0; i < _phoneControllers.length; i++) {
      fields.add(Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _phoneControllers[i],
              decoration: _inputDecoration("Phone Number", Icons.phone),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v == null || v.isEmpty ? "Enter phone number" : null,
            ),
          ),
          const SizedBox(width: 8),
          if (i == _phoneControllers.length - 1)
            IconButton(
              onPressed: () {
                setState(() {
                  _phoneControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add_circle,
                  color: Colors.green, size: 32),
            ),
          if (_phoneControllers.length > 1)
            IconButton(
              onPressed: () {
                setState(() {
                  _phoneControllers.removeAt(i);
                });
              },
              icon: const Icon(Icons.remove_circle,
                  color: Colors.redAccent, size: 32),
            ),
        ],
      ));
      fields.add(const SizedBox(height: 12));
    }
    return fields;
  }

  // Input Decoration with Icon
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.redAccent),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }
}
