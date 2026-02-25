import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import 'package:agriassist/services/api_service.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({Key? key}) : super(key: key);

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  late Future<Map<String, dynamic>?> _marketFuture;

  // Dynamic Dates Calculation
  final String _latestDate = DateFormat('dd MMM').format(DateTime.now().subtract(const Duration(days: 2)));
  final String _midDate = DateFormat('dd MMM').format(DateTime.now().subtract(const Duration(days: 3)));
  final String _oldDate = DateFormat('dd MMM').format(DateTime.now().subtract(const Duration(days: 4)));

  @override
  void initState() {
    super.initState();
    // Will load instantly if cached, otherwise fetches from network
    _marketFuture = ApiService.getMarketData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF13383A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Bazaar Bhav",
          style: TextStyle(
            color: Color(0xFF13383A),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _marketFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!['data'] == null) {
            return _buildErrorState();
          }

          final location = snapshot.data!['location'] ?? "Unknown Location";
          final List commodities = snapshot.data!['data'];

          if (commodities.isEmpty) {
            return const Center(child: Text("No market data available for your state right now."));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  "Market Prices in $location",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: commodities.length,
                  itemBuilder: (context, index) {
                    return _buildCommodityCard(commodities[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommodityCard(Map<String, dynamic> item) {
    String name = item['commodity'] ?? "Unknown";
    String msp = item['msp'] ?? "—";
    String latest = item['price_latest'] ?? "—";
    String mid = item['price_mid'] ?? "—";
    String old = item['price_old'] ?? "—";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Side: Text and Prices
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF13383A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "MSP: ₹$msp",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const Divider(height: 20),
                _priceRow("Latest ($_latestDate):", latest, isBold: true),
                const SizedBox(height: 4),
                _priceRow("Mid ($_midDate):", mid),
                const SizedBox(height: 4),
                _priceRow("Old ($_oldDate):", old),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right Side: Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF5FBF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB5CAC1).withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                _getCommodityImage(name),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.grass, size: 40, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String price, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isBold ? Colors.black87 : Colors.black54,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          price == "—" ? "—" : "₹$price",
          style: TextStyle(
            fontSize: 14,
            color: isBold ? const Color(0xFF13383A) : Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Map commodity names to asset paths
  String _getCommodityImage(String name) {
    String n = name.toLowerCase();
    if (n.contains('cotton') || n.contains('kapas')) return "assets/images/crops/cotton.png";
    if (n.contains('wheat')) return "assets/images/crops/wheat.png";
    if (n.contains('soyabean')) return "assets/images/crops/soyabean.png";
    if (n.contains('onion')) return "assets/images/crops/onion.png";
    if (n.contains('bajra')) return "assets/images/crops/bajra.png";
    if (n.contains('jowar')) return "assets/images/crops/jowar.png";
    if (n.contains('maize')) return "assets/images/crops/maize.png";
    if (n.contains('paddy')) return "assets/images/crops/paddy.png";
    // Default fallback
    return "assets/images/crops/default.png";
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text("Could not load market data."),
          TextButton(
            onPressed: () {
              setState(() {
                _marketFuture = ApiService.getMarketData(forceRefresh: true);
              });
            },
            child: const Text("Retry"),
          )
        ],
      ),
    );
  }
}