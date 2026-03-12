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
  String selectedCategory = 'All'; // New filter state

  bool isLoading = true;

  final List<String> states = [
    'All', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jammu and Kashmir',
    'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Punjab',
    'Rajasthan', 'Tamil Nadu', 'Telangana', 'Uttar Pradesh', 'West Bengal'
  ];

  // The categories you requested
  final List<String> categories = [
    'All', 'Insurance', 'Subsidies', 'Fertilizer', 'Animal', 'Irrigation',
    'Horticulture', 'Vehicle', 'Dairy', 'Poultry', 'Soil', 'Solar',
    'Crop Specific', 'Tractor Related'
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
        // Normalize data for searching
        String name = (scheme['scheme_name'] ?? "").toString().toLowerCase();
        String desc = (scheme['description'] ?? "").toString().toLowerCase();
        String tags = (scheme['tags'] ?? "").toString().toLowerCase();
        String statesList = (scheme['states'] ?? "").toString().toLowerCase();

        // 1. Search Query Filter
        bool matchesSearch = searchQuery.isEmpty ||
            name.contains(searchQuery.toLowerCase()) ||
            tags.contains(searchQuery.toLowerCase());

        // 2. State Filter
        bool matchesState = selectedState == 'All' ||
            statesList.contains('all') ||
            statesList.contains(selectedState.toLowerCase());

        // 3. Smart Category Filter
        bool matchesCategory = true;
        if (selectedCategory != 'All') {
          List<String> keywords = _getKeywordsForCategory(selectedCategory);
          // Check if any keyword exists in name, description, or tags
          matchesCategory = keywords.any((k) =>
          name.contains(k) || desc.contains(k) || tags.contains(k));
        }

        return matchesSearch && matchesState && matchesCategory;
      }).toList();
    });
  }

  // Map category selection to actual keywords found in the CSV
  List<String> _getKeywordsForCategory(String category) {
    switch (category) {
      case 'Insurance': return ['insurance', 'bima', 'suraksha', 'claim'];
      case 'Subsidies': return ['subsidy', 'subsidies', 'financial assistance', 'grant'];
      case 'Fertilizer': return ['fertilizer', 'manure', 'urea', 'nutrient', 'potash'];
      case 'Animal': return ['animal', 'livestock', 'cattle', 'goat', 'sheep', 'husbandry'];
      case 'Irrigation': return ['irrigation', 'water', 'pump', 'drip', 'sprinkler', 'borewell'];
      case 'Horticulture': return ['horticulture', 'fruit', 'vegetable', 'garden', 'plantation'];
      case 'Vehicle': return ['vehicle', 'transport', 'truck', 'van', 'e-rickshaw'];
      case 'Dairy': return ['dairy', 'milk', 'chilling', 'cow', 'buffalo'];
      case 'Poultry': return ['poultry', 'chicken', 'duck', 'egg', 'hatchery'];
      case 'Soil': return ['soil', 'fertility', 'land health', 'earth'];
      case 'Solar': return ['solar', 'pv', 'energy', 'kusum'];
      case 'Crop Specific': return ['crop', 'paddy', 'wheat', 'sugarcane', 'cotton', 'seed'];
      case 'Tractor Related': return ['tractor', 'tiller', 'machinery', 'mechanization', 'implement'];
      default: return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF13383A);
    const accentColor = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F6),
      appBar: AppBar(
        title: const Text('Agri Schemes',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PROPER SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: TextField(
                onChanged: (val) { searchQuery = val; _applyFilters(); },
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



          // STATE FILTERS (Scrollable)
          const Padding(
            padding: EdgeInsets.only(left: 22, top: 12, bottom: 8),
            child: Text("States", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
          ),
          _buildFilterRow(states, selectedState, (val) {
            setState(() { selectedState = val; _applyFilters(); });
          }),


          // CATEGORY FILTERS (Scrollable)
          const Padding(
            padding: EdgeInsets.only(left: 22, top: 10, bottom: 8),
            child: Text("Categories", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
          ),
          _buildFilterRow(categories, selectedCategory, (val) {
            setState(() { selectedCategory = val; _applyFilters(); });
          }),

          const SizedBox(height: 15),

          // LIST OF SCHEMES
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${filteredSchemes.length} schemes found",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
                      if (selectedCategory != 'All' || selectedState != 'All')
                        TextButton(
                          onPressed: () => setState(() { selectedCategory = 'All'; selectedState = 'All'; _applyFilters(); }),
                          child: const Text("Clear Filters", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                ),
                Expanded(
                  child: filteredSchemes.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSchemes.length,
                    itemBuilder: (context, index) => _buildSchemeCard(filteredSchemes[index]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(List<String> items, String currentSelection, Function(String) onSelected) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          bool isSelected = currentSelection == items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(items[index]),
              selected: isSelected,
              selectedColor: const Color(0xFF13383A),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF13383A),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? const Color(0xFF13383A) : Colors.grey.shade300),
              onSelected: (bool selected) { if (selected) onSelected(items[index]); },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text("No matching schemes found", style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSchemeCard(Map<String, dynamic> scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SchemeDetailScreen(scheme: scheme))),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scheme['scheme_name'] ?? 'Unknown Scheme',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF13383A), height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                scheme['description'] ?? 'No description available.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Text("Details", style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF4CAF50)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}