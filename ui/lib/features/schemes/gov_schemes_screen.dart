import 'package:agriassist/features/schemes/scheme_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:agriassist/services/api_service.dart';
import 'package:agriassist/l10n/app_localizations.dart';

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
  String selectedCategory = 'All';

  bool isLoading = true;

  final List<String> states = [
    'All','Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh',
    'Delhi','Goa','Gujarat','Haryana','Himachal Pradesh','Jammu and Kashmir',
    'Jharkhand','Karnataka','Kerala','Madhya Pradesh','Maharashtra','Punjab',
    'Rajasthan','Tamil Nadu','Telangana','Uttar Pradesh','West Bengal'
  ];

  final List<String> categories = [
    'All','Insurance','Subsidies','Fertilizer','Animal','Irrigation',
    'Horticulture','Vehicle','Dairy','Poultry','Soil','Solar',
    'Crop Specific','Tractor Related'
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

        String name =
        (scheme['scheme_name'] ?? "").toString().toLowerCase();

        String desc =
        (scheme['description'] ?? "").toString().toLowerCase();

        String tags =
        (scheme['tags'] ?? "").toString().toLowerCase();

        String statesList =
        (scheme['states'] ?? "").toString().toLowerCase();

        bool matchesSearch = searchQuery.isEmpty ||
            name.contains(searchQuery.toLowerCase()) ||
            tags.contains(searchQuery.toLowerCase());

        bool matchesState = selectedState == 'All' ||
            statesList.contains('all') ||
            statesList.contains(selectedState.toLowerCase());

        bool matchesCategory = true;

        if (selectedCategory != 'All') {

          List<String> keywords =
          _getKeywordsForCategory(selectedCategory);

          matchesCategory = keywords.any((k) =>
          name.contains(k) ||
              desc.contains(k) ||
              tags.contains(k));
        }

        return matchesSearch && matchesState && matchesCategory;

      }).toList();

    });

  }

  List<String> _getKeywordsForCategory(String category) {

    switch (category) {

      case 'Insurance':
        return ['insurance','bima','suraksha','claim'];

      case 'Subsidies':
        return ['subsidy','financial assistance','grant'];

      case 'Fertilizer':
        return ['fertilizer','manure','urea','nutrient'];

      case 'Animal':
        return ['animal','livestock','cattle','goat','sheep'];

      case 'Irrigation':
        return ['irrigation','water','pump','drip','sprinkler'];

      case 'Horticulture':
        return ['horticulture','fruit','vegetable'];

      case 'Vehicle':
        return ['vehicle','transport','truck'];

      case 'Dairy':
        return ['dairy','milk','cow','buffalo'];

      case 'Poultry':
        return ['poultry','chicken','duck','egg'];

      case 'Soil':
        return ['soil','fertility','land health'];

      case 'Solar':
        return ['solar','pv','energy'];

      case 'Crop Specific':
        return ['crop','paddy','wheat','cotton'];

      case 'Tractor Related':
        return ['tractor','tiller','machinery'];

      default:
        return [];
    }

  }

  @override
  Widget build(BuildContext context) {

    final t = AppLocalizations.of(context)!;

    const primaryColor = Color(0xFF13383A);
    const accentColor = Color(0xFF4CAF50);

    return Scaffold(

      backgroundColor: const Color(0xFFF4F9F6),

      appBar: AppBar(

        title: Text(
          t.agriSchemes,
          style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ),

        backgroundColor: Colors.transparent,
        elevation: 0,

        iconTheme:
        const IconThemeData(color: primaryColor),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),

            child: Container(

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),

                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),

              child: TextField(

                onChanged: (val) {
                  searchQuery = val;
                  _applyFilters();
                },

                decoration: InputDecoration(
                  hintText: t.searchSchemes,

                  prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: primaryColor),

                  border: InputBorder.none,

                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          Padding(
            padding:
            const EdgeInsets.only(left: 22, top: 12, bottom: 8),
            child: Text(
              t.states,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor),
            ),
          ),

          _buildFilterRow(
              states,
              selectedState,
                  (val) {
                setState(() {
                  selectedState = val;
                  _applyFilters();
                });
              }),

          Padding(
            padding:
            const EdgeInsets.only(left: 22, top: 10, bottom: 8),

            child: Text(
              t.categories,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor),
            ),
          ),

          _buildFilterRow(
              categories,
              selectedCategory,
                  (val) {
                setState(() {
                  selectedCategory = val;
                  _applyFilters();
                });
              }),

          const SizedBox(height: 15),

          Expanded(
            child: isLoading

                ? const Center(
                child:
                CircularProgressIndicator(color: primaryColor))

                : Column(
              children: [

                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 22),

                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children: [

                      Text(
                        t.schemesFound(filteredSchemes.length),
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),

                      if (selectedCategory != 'All' ||
                          selectedState != 'All')

                        TextButton(

                          onPressed: () {
                            setState(() {

                              selectedCategory = 'All';
                              selectedState = 'All';

                              _applyFilters();
                            });
                          },

                          child: Text(
                            t.clearFilters,
                            style: const TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold),
                          ),
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

                    itemBuilder: (context, index) =>
                        _buildSchemeCard(
                            filteredSchemes[index]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
      List<String> items,
      String currentSelection,
      Function(String) onSelected) {

    return SizedBox(

      height: 40,

      child: ListView.builder(

        scrollDirection: Axis.horizontal,

        padding:
        const EdgeInsets.symmetric(horizontal: 16),

        itemCount: items.length,

        itemBuilder: (context, index) {

          bool isSelected =
              currentSelection == items[index];

          return Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 4),

            child: ChoiceChip(

              label: Text(items[index]),

              selected: isSelected,

              selectedColor: const Color(0xFF13383A),

              backgroundColor: Colors.white,

              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF13383A),
                fontSize: 12,
              ),

              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(20)),

              onSelected: (bool selected) {

                if (selected) onSelected(items[index]);

              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {

    final t = AppLocalizations.of(context)!;

    return Center(

      child: Column(

        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          Icon(Icons.search_off_rounded,
              size: 60,
              color: Colors.grey.shade300),

          const SizedBox(height: 10),

          Text(
            t.noSchemesFound,
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeCard(
      Map<String, dynamic> scheme) {

    final t = AppLocalizations.of(context)!;

    return Container(

      margin: const EdgeInsets.only(bottom: 16),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),

      child: InkWell(

        borderRadius: BorderRadius.circular(20),

        onTap: () {

          Navigator.push(

            context,

            MaterialPageRoute(

                builder: (context) =>
                    SchemeDetailScreen(scheme: scheme)),
          );
        },

        child: Padding(

          padding: const EdgeInsets.all(20),

          child: Column(

            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              Text(
                scheme['scheme_name'] ??
                    t.unknownScheme,

                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF13383A)),
              ),

              const SizedBox(height: 8),

              Text(

                scheme['description'] ??
                    t.noDescription,

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600),
              ),

              const SizedBox(height: 16),

              Row(
                children: [

                  Text(
                    t.details,

                    style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),

                  const SizedBox(width: 4),

                  const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Color(0xFF4CAF50))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}