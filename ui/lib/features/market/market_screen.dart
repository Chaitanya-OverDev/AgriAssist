import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:agriassist/services/api_service.dart';
import '../../data/india_locations.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({Key? key}) : super(key: key);

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  late Future<List<dynamic>> _marketFuture;

  String? selectedState;
  String? selectedDistrict;

  List<String> states = indiaStatesDistricts.keys.toList();
  List<String> districts = [];

  @override
  void initState() {
    super.initState();
    _marketFuture = _loadMarketData();
  }

  Future<List<dynamic>> _loadMarketData() async {
    final data = await ApiService.getMarketData();
    print("API RESPONSE: $data");
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
      print("Market API Response: $data");
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F7), // softer background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Bazaar Bhav",
          style: TextStyle(
            color: Color(0xFF13383A),
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF13383A)),
            onPressed: applyFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _marketFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No market data found",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
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
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  hint: const Text(
                    "State",
                    style: TextStyle(color: Colors.grey),
                  ),
                  value: selectedState,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF0F7F4),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: states.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s, style: const TextStyle(fontSize: 15)),
                    );
                  }).toList(),
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
                child: DropdownButtonFormField<String>(
                  hint: const Text(
                    "District",
                    style: TextStyle(color: Colors.grey),
                  ),
                  value: selectedDistrict,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF0F7F4),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: districts.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(d, style: const TextStyle(fontSize: 15)),
                    );
                  }).toList(),
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
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: applyFilter,
              child: const Text("Apply Filter"),
            ),
          ),
        ],
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular image with gradient background
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [const Color(0xFFE1F5E8), const Color(0xFFB8E0CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    _getCommodityImage(commodity),
                    width: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "$market • $district",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: source.toLowerCase() == 'mandi'
                      ? const Color(0xFFD4EDDA).withOpacity(0.4)
                      : const Color(0xFFFFE5B4).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  source.toUpperCase(),
                  style: TextStyle(
                    color: source.toLowerCase() == 'mandi'
                        ? const Color(0xFF155724)
                        : const Color(0xFF856404),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _priceBox(
                  label: "Market Price",
                  price: price,
                  icon: Icons.trending_up,
                  color: const Color(0xFF1B5E3F),
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey.shade300),
              Expanded(
                child: _priceBox(
                  label: "MSP",
                  price: msp,
                  icon: Icons.security,
                  color: const Color(0xFFB76E2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                "Updated $date",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceBox({required String label, required String price, required IconData icon, required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              Text(
                "₹ $price",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCommodityImage(String name) {
    String n = name.toLowerCase();
    if (n.contains('cotton')) return "assets/images/crops/cotton.png";
    if (n.contains('onion')) return "assets/images/crops/onion.png";
    if (n.contains('soyabean')) return "assets/images/crops/soyabean.png";
    if (n.contains('wheat')) return "assets/images/crops/wheat.png";
    return "assets/images/crops/default.png";
  }
}