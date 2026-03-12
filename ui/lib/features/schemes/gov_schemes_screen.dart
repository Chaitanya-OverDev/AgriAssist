import 'package:agriassist/features/schemes/scheme_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:agriassist/services/api_service.dart';

class GovSchemesScreen extends StatefulWidget {
  const GovSchemesScreen({super.key});

  @override
  State<GovSchemesScreen> createState() => _GovSchemesScreenState();
}

class _GovSchemesScreenState extends State<GovSchemesScreen> {
  List<dynamic> allSchemes = [];
  List<dynamic> filteredSchemes = [];
  String searchQuery = "";
  String selectedState = 'All';
  bool isLoading = true;

  final List<String> states = [
    'All', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jammu and Kashmir',
    'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Punjab',
    'Rajasthan', 'Tamil Nadu', 'Telangana', 'Uttar Pradesh', 'West Bengal'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (ApiService.localSchemes.isEmpty) {
      await ApiService.syncGovSchemes();
    }
    setState(() {
      allSchemes = ApiService.localSchemes;
      isLoading = false;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      filteredSchemes = allSchemes.where((scheme) {
        String statesStr = scheme['states']?.toString().toLowerCase() ?? "";
        String tagsStr = scheme['tags']?.toString().toLowerCase() ?? "";
        String descriptionStr = scheme['description']?.toString().toLowerCase() ?? "";
        String nameStr = scheme['scheme_name']?.toString().toLowerCase() ?? "";

        bool matchesState = selectedState == 'All' ||
            statesStr.contains('all') ||
            statesStr.contains(selectedState.toLowerCase());

        bool matchesSearch = nameStr.contains(searchQuery.toLowerCase()) ||
            tagsStr.contains(searchQuery.toLowerCase());

        bool isAgriculture = tagsStr.contains('agriculture') ||
            tagsStr.contains('farmer') ||
            descriptionStr.contains('agriculture');

        return matchesState && matchesSearch && isAgriculture;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF13383A);
    const accentColor = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F6), // Softer mint background
      appBar: AppBar(
        title: const Text(
          'Agri Schemes',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// MODERN SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: TextField(
                onChanged: (val) {
                  searchQuery = val;
                  _applyFilters();
                },
                decoration: InputDecoration(
                  hintText: 'Search schemes, crops, or benefits...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: primaryColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 20, top: 10, bottom: 8),
            child: Text("Filter by State", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
          ),

          /// HORIZONTAL STATE CHIPS (Much better than Dropdown)
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: states.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedState == states[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(states[index]),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : primaryColor,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: isSelected ? primaryColor : Colors.grey.shade300),
                    onSelected: (bool selected) {
                      setState(() {
                        selectedState = states[index];
                        _applyFilters();
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 15),

          /// RESULTS COUNT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "${filteredSchemes.length} schemes available",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),

          /// SCHEMES LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : filteredSchemes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredSchemes.length,
              itemBuilder: (context, index) => _buildSchemeCard(filteredSchemes[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text("No schemes found", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSchemeCard(Map<String, dynamic> scheme) {
    bool hasDate = scheme['close_date'] != null && scheme['close_date'] != "None" && scheme['close_date'] != "";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SchemeDetailScreen(scheme: scheme)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "GOVT SCHEME",
                        style: TextStyle(color: Color(0xFF13383A), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (hasDate)
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            scheme['close_date'],
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  scheme['scheme_name'] ?? 'Unknown Scheme',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF13383A), height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  scheme['description'] ?? 'No description available.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Text("View Details", style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF4CAF50)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}