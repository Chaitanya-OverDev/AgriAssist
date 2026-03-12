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

        String statesStr = scheme['states'].toString().toLowerCase();
        String tagsStr = scheme['tags'].toString().toLowerCase();
        String descriptionStr = scheme['description'].toString().toLowerCase();

        /// STATE FILTER
        bool matchesState = selectedState == 'All' ||
            statesStr.contains('all') ||
            statesStr.contains(selectedState.toLowerCase());

        /// SEARCH FILTER
        bool matchesSearch =
            scheme['scheme_name']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
                tagsStr.contains(searchQuery.toLowerCase());

        /// AGRICULTURE FILTER
        bool isAgricultureScheme =
            tagsStr.contains('agriculture') ||
                tagsStr.contains('farmer') ||
                tagsStr.contains('crop') ||
                tagsStr.contains('irrigation') ||
                tagsStr.contains('farming') ||
                tagsStr.contains('soil') ||
                tagsStr.contains('livestock') ||
                descriptionStr.contains('agriculture') ||
                descriptionStr.contains('farmer') ||
                descriptionStr.contains('crop');

        return matchesState && matchesSearch && isAgricultureScheme;

      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8F1),
      appBar: AppBar(
        title: const Text(
          'Government Schemes',
          style: TextStyle(color: Color(0xFF13383A)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF13383A)),
      ),
      body: Column(
        children: [

          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) {
                searchQuery = val;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search agriculture schemes...',
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

          /// STATE FILTER
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterDropdown(
                  value: selectedState,
                  items: [
                    'All',
                    'Andhra Pradesh',
                    'Arunachal Pradesh',
                    'Assam',
                    'Bihar',
                    'Chandigarh',
                    'Chhattisgarh',
                    'Dadra & Nagar Haveli and Daman & Diu',
                    'Delhi',
                    'Goa',
                    'Gujarat',
                    'Haryana',
                    'Himachal Pradesh',
                    'Jammu and Kashmir',
                    'Jharkhand',
                    'Karnataka',
                    'Kerala',
                    'Lakshadweep',
                    'Madhya Pradesh',
                    'Maharashtra',
                    'Manipur',
                    'Meghalaya',
                    'Mizoram',
                    'Nagaland',
                    'Odisha',
                    'Puducherry',
                    'Punjab',
                    'Rajasthan',
                    'Sikkim',
                    'Tamil Nadu',
                    'Telangana',
                    'Tripura',
                    'Uttar Pradesh',
                    'Uttarakhand',
                    'West Bengal'
                  ],
                  onChanged: (val) {
                    selectedState = val!;
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// SCHEMES LIST
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF13383A),
              ),
            )
                : filteredSchemes.isEmpty
                ? const Center(
              child: Text(
                "No agriculture schemes found.",
                style: TextStyle(fontSize: 16),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
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

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
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
          icon:
          const Icon(Icons.arrow_drop_down, color: Color(0xFF13383A)),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF13383A)),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSchemeCard(Map<String, dynamic> scheme) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SchemeDetailScreen(scheme: scheme),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// CLOSING DATE
            if (scheme['close_date'] != "None" &&
                scheme['close_date'] != null &&
                scheme['close_date'] != "")
              Text(
                "Closes: ${scheme['close_date']}",
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 8),

            /// SCHEME NAME
            Text(
              scheme['scheme_name'] ?? 'Unknown Scheme',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF13383A),
              ),
            ),

            const SizedBox(height: 8),

            /// SHORT DESCRIPTION
            Text(
              scheme['description'] ?? 'No description available.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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
}