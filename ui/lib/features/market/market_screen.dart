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
      _showFilter = false;
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Bazaar Bhav",
          style: TextStyle(
            color: Color(0xFF0B3B2F),
            fontWeight: FontWeight.w700,
            fontSize: 26,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Color(0xFF0B3B2F)),
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
            secondChild: const SizedBox(),
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        const BorderRadius.vertical(bottom: Radius.circular(30)),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),
                onPressed: () {
                  setState(() {
                    _showFilter = false;
                  });
                },
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
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
        hint: Text(hint),
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: items.map((s) {
          return DropdownMenuItem(
            value: s,
            child: Text(s),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMarketCard(Map<String, dynamic> item) {
    String commodity = item["commodity"] ?? "";
    String market = item["market"] ?? "";
    String district = item["district"] ?? "";
    String price = item["price_latest"]?.toString() ?? "0";
    String msp = item["msp"]?.toString() ?? "0";
    String date = item["date"] ?? "";
    String source = item["source"] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            commodity,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF13383A),
            ),
          ),
          const SizedBox(height: 6),
          Text("$market • $district"),
          const SizedBox(height: 10),
          Row(
            children: [
              _priceBox("Market Price", price, Icons.trending_up,
                  const Color(0xFF1B5E3F)),
              const SizedBox(width: 20),
              _priceBox("MSP", msp, Icons.security,
                  const Color(0xFFB76E2E)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Updated $date",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          )
        ],
      ),
    );
  }

  Widget _priceBox(
      String label, String price, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600])),
            Text(
              "₹ $price",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text("Please select the district"),
    );
  }
}