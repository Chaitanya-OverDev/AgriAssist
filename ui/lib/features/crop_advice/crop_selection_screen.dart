import 'package:flutter/material.dart';
import 'package:agriassist/features/chat/text_chat/text_chat_screen.dart'; // Adjust path
import 'package:agriassist/l10n/app_localizations.dart';

class CropSelectionScreen extends StatelessWidget {
  const CropSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // You can expand this list or fetch it from your backend/constants
    final List<Map<String, String>> crops = [
      {"name": "Wheat", "icon": "🌾", "localName": "Gehun"},
      {"name": "Tomato", "icon": "🍅", "localName": "Tamatar"},
      {"name": "Cotton", "icon": "☁️", "localName": "Kapas"},
      {"name": "Onion", "icon": "🧅", "localName": "Pyaaz"},
      {"name": "Potato", "icon": "🥔", "localName": "Aloo"},
      {"name": "Soyabean", "icon": "🌱", "localName": "Soyabean"},
      {"name": "Sugarcane", "icon": "🎋", "localName": "Ganna"},
      {"name": "Paddy", "icon": "🍚", "localName": "Dhan"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEAF8F1),
      appBar: AppBar(
        title: const Text(
          "Select a Crop",
          style: TextStyle(color: Color(0xFF13383A), fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF13383A)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Which crop do you want advice for?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF13383A),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: crops.length,
                itemBuilder: (context, index) {
                  final crop = crops[index];
                  return _buildCropCard(context, crop['name']!, crop['localName']!, crop['icon']!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropCard(BuildContext context, String cropName, String localName, String icon) {
    return InkWell(
      onTap: () {
        // Show the bottom sheet to collect farm details instead of jumping straight to chat
        _showFarmDetailsSheet(context, cropName, localName);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFFB5CAC1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              cropName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF13383A),
              ),
            ),
            Text(
              localName,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- THE NEW BOTTOM SHEET ---
  void _showFarmDetailsSheet(BuildContext context, String cropName, String localName) {
    // Controllers and state variables for the form
    final TextEditingController landSizeController = TextEditingController();
    String selectedWaterSource = 'Borewell';
    String selectedIrrigation = 'Drip Irrigation';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to move up when keyboard appears
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        // StatefulBuilder allows us to update the UI (dropdowns) inside the bottom sheet
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // Avoid keyboard overlap
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Farm Details for $cropName",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF13383A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Help the AI give you exact fertilizer dosages and watering schedules by providing your farm details.",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    // --- Land Size Input ---
                    const Text("Land Size (in Acres)", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: landSizeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: "e.g., 2.5",
                        filled: true,
                        fillColor: const Color(0xFFF5FBF9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFB5CAC1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFB5CAC1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF13383A)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Water Source Dropdown ---
                    const Text("Water Source", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: selectedWaterSource,
                      items: ['Borewell', 'Open Well', 'Canal / River', 'Rainfed (No Source)'],
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedWaterSource = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Irrigation Type Dropdown ---
                    const Text("Irrigation Method", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: selectedIrrigation,
                      items: ['Drip Irrigation', 'Sprinkler', 'Flood / Manual', 'None'],
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedIrrigation = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // --- Submit Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF13383A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          // Validate land size
                          String landSize = landSizeController.text.trim();
                          if (landSize.isEmpty) {
                            landSize = "1"; // Default to 1 Acre if they leave it blank
                          }

                          // Build the highly enriched prompt
                          String enrichedPrompt = """
I am planning to plant $cropName ($localName). 
My farm details are:
- Land Size: $landSize Acres
- Water Source: $selectedWaterSource
- Irrigation Method: $selectedIrrigation

Based on these specific details, please provide a complete, step-by-step agricultural guide including:
1. Soil preparation and planting process.
2. Exact fertilizers to use (Chemical name/Brand) and exact dosage calculated for $landSize Acres.
3. Specific watering schedule using $selectedIrrigation.
4. Expected time until yield.
5. Common diseases to watch out for and their pesticide treatments.
""";

                          // Close the bottom sheet
                          Navigator.pop(context);

                          // Navigate to Chat Screen with the enriched prompt
                          Navigator.pushReplacement(
                            sheetContext,
                            MaterialPageRoute(
                              builder: (_) => TextChatScreen(
                                prefilledQuery: enrichedPrompt,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Get Expert Advice",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper widget for cleaner dropdowns
  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FBF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB5CAC1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF13383A)),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 15)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}