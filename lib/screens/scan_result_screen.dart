import 'package:flutter/material.dart';

class ScanResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const ScanResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final String item =
    (result['item'] ?? 'Unknown food').toString();

    final bool safe =
        result['safe'] == true;

    final String? allergen =
    result['allergen']?.toString();

    final String explanation =
    (result['explanation'] ?? 'No explanation available.')
        .toString();

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (safe) {
      statusColor = Colors.green;
      statusText = "SAFE TO CONSUME";
      statusIcon = Icons.check_circle;
    } else if (allergen != null && allergen.isNotEmpty) {
      statusColor = Colors.red;
      statusText = "UNSAFE";
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.orange;
      statusText = "WARNING";
      statusIcon = Icons.error;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Result"),
        backgroundColor: statusColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Food Item
            const Text(
              "Identified Item",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Allergen Info
            const Text(
              "Allergen",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              allergen ?? "None detected",
              style: TextStyle(
                fontSize: 18,
                color: allergen == null
                    ? Colors.green
                    : Colors.red,
              ),
            ),

            const SizedBox(height: 20),

            // Explanation
            const Text(
              "Explanation",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              explanation,
              style: const TextStyle(fontSize: 16),
            ),

            const Spacer(),

            // Scan Again Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text("Scan Another Item"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}