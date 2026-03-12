import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:agriassist/services/api_service.dart';
import '../../data/india_locations.dart';
import 'dart:async';

class MarketScreen extends StatefulWidget {
  const MarketScreen({Key? key}) : super(key: key);

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with TickerProviderStateMixin {
  late Future<List<dynamic>> _marketFuture;

  String? selectedState;
  String? selectedDistrict;

  List<String> states = indiaStatesDistricts.keys.toList();
  List<String> districts = [];

  bool _showFilter = true;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _marketFuture = _loadMarketData();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _loadMarketData() async {
    final data = await ApiService.getMarketData();
    if (data == null) return [];
    return (data["data"]?["data"] ?? []) as List<dynamic>;
  }

  Future<List<dynamic>> _filterMarketData() async {
    if (selectedState != null && selectedDistrict != null) {
      final data = await ApiService.searchMarketByDistrict(
        selectedState!,
        selectedDistrict!,
      );
      if (data == null) return [];
      return (data["data"]?["data"] ?? []) as List<dynamic>;
    }

    if (selectedState != null) {
      final data = await ApiService.searchMarketByState(selectedState!);
      if (data == null) return [];
      return (data["data"]?["data"] ?? []) as List<dynamic>;
    }

    final data = await ApiService.getMarketData();
    if (data == null) return [];
    return (data["data"]?["data"] ?? []) as List<dynamic>;
  }

  void applyFilter() {
    setState(() {
      _marketFuture = _filterMarketData();
      _showFilter = false; // Automatically hide filter on apply
    });
  }

  Future<void> _onRefresh() async {
    applyFilter();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Bazaar Bhav",
          style: TextStyle(
            color: Color(0xFF0B3B2F),
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilter ? Icons.filter_alt_off : Icons.filter_alt,
              color: const Color(0xFF0B3B2F),
            ),
            onPressed: () {
              setState(() {
                _showFilter = !_showFilter;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0B3B2F)),
            onPressed: applyFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedCrossFade(
            firstChild: _buildFilterSection(),
            secondChild: _buildCollapsedFilterSummary(),
            crossFadeState: _showFilter
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              child: FutureBuilder<List<dynamic>>(
                future: _marketFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmerLoading();
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final data = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return _buildMarketCard(data[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // A small bar that shows when filter is hidden so the user knows what's selected
  Widget _buildCollapsedFilterSummary() {
    if (selectedState == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.location_on, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            "${selectedState}${selectedDistrict != null ? ' > $selectedDistrict' : ''}",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showFilter = true),
            child: Text(
              "Change",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Filter Markets",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),
                onPressed: () => setState(() => _showFilter = false),
              )
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  hint: "State",
                  value: selectedState,
                  items: states,
                  onChanged: (val) {
                    setState(() {
                      selectedState = val;
                      districts = indiaStatesDistricts[val] ?? [];
                      selectedDistrict = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  hint: "District",
                  value: selectedDistrict,
                  items: districts,
                  onChanged: (val) {
                    setState(() => selectedDistrict = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: applyFilter,
              child: const Text(
                "Apply Filter",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF0F7F4),
      ),
      child: DropdownButtonFormField<String>(
        hint: Text(hint, style: const TextStyle(fontSize: 14)),
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 20),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMarketCard(Map<String, dynamic> item) {
    String commodity = item["commodity"] ?? "Crop";
    String market = item["market"] ?? "";
    String district = item["district"] ?? "";
    String price = item["price_latest"]?.toString() ?? "0";
    String msp = item["msp"]?.toString() ?? "0";
    String date = item["date"] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CROP PHOTO SECTION ---
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                _getCommodityImage(commodity),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.agriculture, color: AppColors.primary, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // --- INFO SECTION ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commodity,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF13383A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "$market, $district",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _priceBox("Market", price, const Color(0xFF1B5E3F)),
                    const SizedBox(width: 24),
                    _priceBox("MSP", msp, const Color(0xFFB76E2E)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Updated $date",
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceBox(String label, String price, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        Text(
          "₹$price",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getCommodityImage(String name) {
    String n = name.toLowerCase();
    if (n.contains('wheat')) return "assets/images/crops/wheat.png";
    if (n.contains('cotton')) return "assets/images/crops/cotton.png";
    if (n.contains('onion')) return "assets/images/crops/onion.png";
    if (n.contains('rice') || n.contains('paddy')) return "assets/images/crops/rice.png";
    if (n.contains('soyabean')) return "assets/images/crops/soyabean.png";
    if (n.contains('tomato')) return "assets/images/crops/tomato.png";
    return "assets/images/crops/default.png";
  }

  Widget _buildShimmerLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Please select your location\nto see market prices",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}