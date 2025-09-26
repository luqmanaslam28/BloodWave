import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> faqs = [
      {
        "section": "Who Can Donate?",
        "qa": [
          {
            "q": "Who is eligible to donate blood?",
            "a":
                "Generally, healthy individuals aged 18–65, weighing at least 50kg, and with no recent illnesses can donate.",
          },
          {
            "q": "Can I donate if I recently had COVID-19?",
            "a":
                "You should wait at least 14 days after complete recovery before donating.",
          },
        ],
      },
      {
        "section": "Donation Process (Step-by-step)",
        "qa": [
          {
            "q": "How does the blood donation process work?",
            "a":
                "1) Registration, 2) Health screening, 3) Donation, 4) Rest & refreshment.",
          },
          {
            "q": "How long does the donation take?",
            "a":
                "The actual donation takes about 8–10 minutes, but the whole process may take 30–45 minutes.",
          },
        ],
      },
      {
        "section": "Health Benefits",
        "qa": [
          {
            "q": "Are there health benefits to donating blood?",
            "a":
                "Yes, it can improve heart health, stimulate blood cell production, and help save lives.",
          },
          {
            "q": "How often can I donate blood?",
            "a": "Every 3 months for men and every 4 months for women.",
          },
        ],
      },
      {
        "section": "Common Myths",
        "qa": [
          {
            "q": "Does donating blood make you weak?",
            "a":
                "No, your body replaces the lost fluids within 24 hours and red cells within weeks.",
          },
          {
            "q": "Can donating blood cause weight gain?",
            "a": "No, it has no effect on weight.",
          },
        ],
      },
      {
        "section": "What to Expect (First Time)",
        "qa": [
          {
            "q": "Does it hurt to donate blood?",
            "a":
                "You’ll feel a small pinch at the beginning. Most donors say it’s painless and over in 10 minutes.",
          },
          {
            "q": "What should I do before donating?",
            "a":
                "Eat a healthy meal, drink plenty of water, and get a good night’s sleep.",
          },
          {
            "q": "What happens after donation?",
            "a":
                "You’ll be asked to rest for a few minutes and have refreshments before leaving.",
          },
        ],
      },
    ];

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
            "Learn & FAQ's",
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
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: faqs.length,
          itemBuilder: (context, index) {
            final sectionTitle = faqs[index]["section"] as String;
            final List<Map<String, String>> qaList = (faqs[index]["qa"] as List)
                .map((e) => Map<String, String>.from(e))
                .toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 18),
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
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Text(
                      sectionTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Q&A List
                    ...qaList.map((qa) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.help_outline,
                                    color: Colors.redAccent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    qa["q"] ?? "",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    qa["a"] ?? "",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
