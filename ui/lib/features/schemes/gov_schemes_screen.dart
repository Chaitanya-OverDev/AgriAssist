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
  String selectedLevel = 'All';

  // 1. Add a loading state
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 2. Make this async to wait for the data
  Future<void> _loadData() async {
    // If the in-memory list is somehow empty (user clicked too fast, or app restarted),
    // force it to run the sync/load function right now and wait for it.
    if (ApiService.localSchemes.isEmpty) {
      await ApiService.syncGovSchemes();
    }

    // Now update the UI safely
    setState(() {
      allSchemes = ApiService.localSchemes;
      isLoading = false; // Turn off loading spinner
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      filteredSchemes = allSchemes.where((scheme) {
        String statesStr = scheme['states'].toString();

        bool matchesState = selectedState == 'All' ||
            statesStr.contains('All') ||
            statesStr.contains(selectedState);

        bool matchesLevel = selectedLevel == 'All' || scheme['level'] == selectedLevel;

        bool matchesSearch = scheme['scheme_name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
            scheme['tags'].toString().toLowerCase().contains(searchQuery.toLowerCase());

        return matchesState && matchesLevel && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8F1),
      appBar: AppBar(
        title: const Text('Government Schemes', style: TextStyle(color: Color(0xFF13383A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF13383A)),
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) {
                searchQuery = val;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search schemes or tags...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF13383A)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- FILTERS ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterDropdown(
                  value: selectedState,
                  // Added more states based on Indian regions, you can adjust this list
                  items: ['All', 'Maharashtra', 'Gujarat', 'Karnataka', 'Rajasthan', 'Haryana', 'Assam', 'Himachal Pradesh'],
                  onChanged: (val) {
                    selectedState = val!;
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 10),
                _buildFilterDropdown(
                  value: selectedLevel,
                  items: ['All', 'Central', 'State'],
                  onChanged: (val) {
                    selectedLevel = val!;
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --- SCHEMES LIST ---
          Expanded(
            // 3. Show a loading spinner if we are still extracting the CSV or downloading
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF13383A),
              ),
            )
                : filteredSchemes.isEmpty
                ? const Center(child: Text("No schemes found for this filter."))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: filteredSchemes.length,
              itemBuilder: (context, index) {
                final scheme = filteredSchemes[index];
                return _buildSchemeCard(scheme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({required String value, required List<String> items, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB5CAC1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF13383A)),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14, color: Color(0xFF13383A))),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSchemeCard(Map<String, dynamic> scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  scheme['level'] ?? 'N/A',
                  style: const TextStyle(color: Color(0xFF13383A), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              if (scheme['close_date'] != "None" && scheme['close_date'] != null && scheme['close_date'] != "")
                Text(
                  "Closes: ${scheme['close_date']}",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            scheme['scheme_name'] ?? 'Unknown Scheme',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF13383A)),
          ),
          const SizedBox(height: 8),
          Text(
            scheme['description'] ?? 'No description available.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}