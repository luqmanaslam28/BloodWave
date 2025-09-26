import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonateBlood extends StatefulWidget {
  const DonateBlood({super.key});

  @override
  State<DonateBlood> createState() => _DonateBloodState();
}

class _DonateBloodState extends State<DonateBlood> {
  // ----------------------------
  // Services
  // ----------------------------
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ----------------------------
  // Form state
  // ----------------------------
  String? donationType; // 'free' | 'paid'
  String? bloodGroup;
  final Map<int, bool?> answers = {}; // index -> true/false
  String? paymentAmount;

  // ----------------------------
  // User + request state
  // ----------------------------
  bool isLoading = true;
  bool hasRequest = false;
  String? requestId;
  String? requestStatus; // 'pending' | 'approved'
  String? userName;
  String? userCity;
  String? userContact;

  // ----------------------------
  // Constants
  // ----------------------------
  final List<String> questions = const [
    "Are you between the age of 18 and 65?",
    "Do you weigh at least 50 kg (110 lbs)?",
    "Are you currently feeling healthy and well?",
    "Have you had a good meal in the past 4 hours?",
    "Have you had at least 6 hours of sleep last night?",
    "Are you free from cold, flu, or any infection currently?",
    "Have you taken any antibiotics or medications recently?",
    "Have you had a tattoo or piercing in the past 6–12 months?",
    "Have you donated blood in the last 3 months (for whole blood)?",
    "Are you currently pregnant, breastfeeding, or given birth in the last 6 months?",
    "Do you suffer from any heart disease, cancer, or chronic illness?",
    "Have you ever tested positive for hepatitis B, hepatitis C, or HIV?",
    "Have you traveled recently to areas with malaria, dengue, or other infectious diseases?",
    "Have you undergone surgery or received a blood transfusion in the last 12 months?",
    "Do you consent to your blood being tested for safety and used for donation purposes?",
    "Have you consumed alcohol in the past 24 hours?",
    "Have you had any recent dental work or tooth extraction?",
    "Have you experienced unexplained weight loss or night sweats recently?",
  ];

  final List<String> bloodTypes = const [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  // ----------------------------
  // Lifecycle
  // ----------------------------
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([loadUserData(), checkUserRequest()]);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  // ----------------------------
  // Data Loading
  // ----------------------------
  Future<void> loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!mounted) return;
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['name']?.toString() ?? '';
          userCity = doc.data()?['city']?.toString() ?? '';
          userContact = doc.data()?['contactNumber']?.toString() ?? '';
        });
      }
    } catch (_) {
      // Optional: log error
    }
  }

  /// Fetch user's donation request **without** requiring a composite index.
  Future<void> checkUserRequest() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    try {
      final querySnap = await _firestore
          .collection('donation_requests')
          .where('uid', isEqualTo: uid)
          .get();

      if (!mounted) return;

      if (querySnap.docs.isEmpty) {
        setState(() {
          hasRequest = false;
          requestId = null;
          requestStatus = null;
        });
        return;
      }

      // Sort client-side by submitted_at desc
      final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
        querySnap.docs,
      );

      docs.sort((a, b) {
        final ta = a.data()['submitted_at'];
        final tb = b.data()['submitted_at'];
        final da = _asTimestamp(ta)?.toDate();
        final db = _asTimestamp(tb)?.toDate();
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da); // newest first
      });

      final latest = docs.first;
      final data = latest.data();

      setState(() {
        hasRequest = true;
        requestId = latest.id;
        requestStatus = data['status']?.toString();
        donationType = data['donation_type']?.toString();
        bloodGroup = data['blood_group']?.toString();
        paymentAmount = data['expected_amount']?.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        hasRequest = false;
        requestId = null;
        requestStatus = null;
      });
    }
  }

  Timestamp? _asTimestamp(dynamic v) {
    if (v is Timestamp) return v;
    return null;
  }

  // ----------------------------
  // Validation
  // ----------------------------
  bool _isFormComplete() {
    if (donationType == null) return false;
    if (bloodGroup == null) return false;

    for (int i = 0; i < questions.length; i++) {
      if (!answers.containsKey(i) || answers[i] == null) {
        return false;
      }
    }

    if (donationType == 'paid') {
      if (paymentAmount == null || paymentAmount!.trim().isEmpty) return false;
    }

    return true;
  }

  // ----------------------------
  // Dialog helpers (safe)
  // ----------------------------
  Future<void> _showInfoDialog({
    required String title,
    required String message,
    String okText = 'OK',
    VoidCallback? onOk,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onOk?.call();
            },
            child: Text(okText),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    Color confirmColor = Colors.redAccent,
  }) {
    if (!mounted) return Future.value(false);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // Submit / Cancel / Removal
  // ----------------------------
  Future<void> submitForm() async {
    if (!_isFormComplete()) {
      return _showInfoDialog(
        title: "Incomplete",
        message: "Please complete all fields before submitting.",
      );
    }

    final accepted = await _showConfirmDialog(
      title: "Declaration of Truth",
      message:
          "I hereby declare that all the information I’ve provided is true to the best of my knowledge.\n\n"
          "If any false information is found, BloodWave reserves the right to inform legal authorities.",
      cancelText: "Decline",
      confirmText: "I Agree",
      confirmColor: Colors.redAccent,
    );

    if (accepted != true) return;

    final uid = _auth.currentUser?.uid ?? '';
    final submission = <String, dynamic>{
      'uid': uid,
      'name': userName ?? '',
      'city': userCity ?? '',
      'contactNumber': userContact ?? '',
      'donation_type': donationType,
      'blood_group': bloodGroup,
      'submitted_at': FieldValue.serverTimestamp(),
      'status': 'pending',
      'answers': {
        for (int i = 0; i < questions.length; i++)
          questions[i]: answers[i] == true ? "Yes" : "No",
      },
      if (donationType == 'paid') 'expected_amount': paymentAmount?.trim(),
    };

    try {
      await _firestore.collection('donation_requests').add(submission);

      await checkUserRequest();

      await _showInfoDialog(
        title: "Submitted",
        message:
            "Your request has been sent.\nYou will be notified if you qualify.",
        onOk: () {
          if (!mounted) return;
          Navigator.pop(context);
        },
      );
    } catch (e) {
      await _showInfoDialog(
        title: "Error",
        message: "Failed to submit request:\n$e",
      );
    }
  }

  Future<void> cancelRequest() async {
    if (requestId == null) return;

    final confirm = await _showConfirmDialog(
      title: "Cancel Request",
      message: "Are you sure you want to cancel your pending donation request?",
      cancelText: "No",
      confirmText: "Yes, Cancel",
    );
    if (confirm != true) return;

    try {
      await _firestore.collection("donation_requests").doc(requestId!).delete();

      if (!mounted) return;
      setState(() {
        hasRequest = false;
        requestId = null;
        requestStatus = null;
      });

      await _showInfoDialog(
        title: "Cancelled",
        message: "Your request has been cancelled.",
        onOk: () {
          if (!mounted) return;
          Navigator.pop(context);
        },
      );
    } catch (e) {
      await _showInfoDialog(
        title: "Error",
        message: "Failed to cancel request:\n$e",
      );
    }
  }

  Future<void> requestRemoval() async {
    final reasonController = TextEditingController();

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove as Donor"),
        content: TextField(
          controller: reasonController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Please tell us why you want to remove yourself",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Submit"),
          ),
        ],
      ),
    );

    if (confirm == true && reasonController.text.trim().isNotEmpty) {
      try {
        final uid = _auth.currentUser?.uid ?? '';
        await _firestore.collection("removal_requests").add({
          "uid": uid,
          "name": userName ?? '',
          "donation_type": donationType,
          "reason": reasonController.text.trim(),
          "submitted_at": FieldValue.serverTimestamp(),
        });

        await _showInfoDialog(
          title: "Request Sent",
          message:
              "Your removal request has been submitted. Our team will review it.",
        );
      } catch (e) {
        await _showInfoDialog(
          title: "Error",
          message: "Failed to submit removal request:\n$e",
        );
      }
    }
  }

  // ----------------------------
  // UI Builders
  // ----------------------------
  PreferredSizeWidget _buildAppBarMain() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Donate Blood",
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
    );
  }

  PreferredSizeWidget _buildAppBarStatus() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Donate Blood",
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
    );
  }

  Widget _buildQuestionCard({required int index, required String question}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${index + 1}. $question",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: answers[index],
                  onChanged: (value) {
                    if (!mounted) return;
                    setState(() {
                      answers[index] = value;
                    });
                  },
                ),
                const Text("Yes"),
                const SizedBox(width: 20),
                Radio<bool>(
                  value: false,
                  groupValue: answers[index],
                  onChanged: (value) {
                    if (!mounted) return;
                    setState(() {
                      answers[index] = value;
                    });
                  },
                ),
                const Text("No"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedCard() {
    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: const [
            Icon(Icons.check_circle, size: 60, color: Colors.green),
            SizedBox(height: 10),
            Text(
              "🎉 You are now a donor.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "You already have a pending donation request.",
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: cancelRequest,
          child: const Text(
            "Cancel Request",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildApprovedCard(),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: requestRemoval,
          child: const Text(
            "Remove Myself as Donor",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ----------------------------
  // Build
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
        appBar: hasRequest ? _buildAppBarStatus() : _buildAppBarMain(),
        body: hasRequest
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: requestStatus == 'approved'
                      ? _buildApprovedSection()
                      : _buildPendingSection(),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: (donationType == null
                    ? 1
                    : questions.length + 3 + (donationType == 'paid' ? 1 : 0)),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Are you donating for charity or asking for money?",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ListTile(
                          title: const Text("Charity (Free)"),
                          leading: Radio<String>(
                            value: 'free',
                            groupValue: donationType,
                            onChanged: (value) {
                              if (!mounted) return;
                              setState(() {
                                donationType = value;
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: const Text("For Money"),
                          leading: Radio<String>(
                            value: 'paid',
                            groupValue: donationType,
                            onChanged: (value) {
                              if (!mounted) return;
                              setState(() {
                                donationType = value;
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  if (donationType == null) {
                    return const SizedBox.shrink();
                  }

                  // Step 1: Select blood group
                  if (index == 1) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Select your blood group",
                          labelStyle: TextStyle(fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(),
                        ),
                        value: bloodGroup,
                        items: bloodTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (!mounted) return;
                          setState(() {
                            bloodGroup = val;
                          });
                        },
                      ),
                    );
                  }

                  // Question cards
                  final qIndex = index - 2;

                  // Extra field for paid donors (expected amount)
                  if (donationType == 'paid' && qIndex == questions.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "How much are you asking per donation?",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => paymentAmount = val,
                      ),
                    );
                  }

                  // Submit button placement
                  if ((donationType == 'free' &&
                          index == questions.length + 2) ||
                      (donationType == 'paid' &&
                          index == questions.length + 3)) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: submitForm,
                        child: const Text(
                          "Submit",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    );
                  }

                  // Render each question card
                  return _buildQuestionCard(
                    index: qIndex,
                    question: questions[qIndex],
                  );
                },
              ),
      ),
    );
  }
}
