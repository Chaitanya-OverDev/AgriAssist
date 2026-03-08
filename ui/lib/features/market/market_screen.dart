
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

  /// LOAD DEFAULT MARKET DATA
  Future<List<dynamic>> _loadMarketData() async {

    final data = await ApiService.getMarketData();

    print("API RESPONSE: $data");

    if (data == null) return [];

    return (data["data"]?["data"] ?? []) as List<dynamic>;
  }

  /// FILTER MARKET DATA
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

      final data = await ApiService.searchMarketByState(
        selectedState!,
      );

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
      backgroundColor: const Color(0xFFEAF8F1),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Bazaar Bhav",
          style: TextStyle(
            color: Color(0xFF13383A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [

          /// FILTER SECTION
          _buildFilterSection(),

          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _marketFuture,
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("No market data found"),
                  );
                }

                final data = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
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

  /// FILTER UI
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          Row(
            children: [

              /// STATE DROPDOWN
              Expanded(
                child: DropdownButtonFormField<String>(
                  hint: const Text("Select State"),
                  value: selectedState,
                  isExpanded: true,
                  items: states.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s),
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

              /// DISTRICT DROPDOWN
              Expanded(
                child: DropdownButtonFormField<String>(
                  hint: const Text("Select District"),
                  value: selectedDistrict,
                  isExpanded: true,
                  items: districts.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(d),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedDistrict = val;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: applyFilter,
            child: const Text("Apply Filter"),
          ),
        ],
      ),
    );
  }

  /// MARKET CARD
  Widget _buildMarketCard(Map<String, dynamic> item) {

    String commodity = item["commodity"] ?? "";
    String market = item["market"] ?? "";
    String district = item["district"] ?? "";
    String price = item["price_latest"]?.toString() ?? "0";
    String msp = item["msp"]?.toString() ?? "0";
    String date = item["date"] ?? "";
    String source = item["source"] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEAF8F1),
                child: Image.asset(
                  _getCommodityImage(commodity),
                  width: 28,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      commodity,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    Text(
                      "$market • $district",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  source.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              _priceBox("Market Price", price),

              _priceBox("MSP", msp),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            "Updated on $date",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          )
        ],
      ),
    );
  }

  Widget _priceBox(String label, String price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),

        Text(
          "₹ $price",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF13383A),
          ),
        )
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