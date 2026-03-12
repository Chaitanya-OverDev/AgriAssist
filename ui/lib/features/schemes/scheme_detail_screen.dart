import 'package:flutter/material.dart';

class SchemeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> scheme;

  const SchemeDetailScreen({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final statesList = scheme['states'] is List
        ? scheme['states'] as List
        : (scheme['states']?.toString().split(',') ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. Sleek Collapsing Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF13383A), Color(0xFF2E6B6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
              title: Text(
                scheme['scheme_name'] ?? "Scheme Details",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 50, bottom: 16),
            ),
          ),

          // 2. Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Info Grid (e.g., Dates, Eligibility)
                  _buildQuickInfoGrid(scheme),

                  const SizedBox(height: 32),

                  _buildSectionHeader(Icons.description_rounded, "Overview"),
                  const SizedBox(height: 12),
                  Text(
                    scheme['description'] ?? "No description provided.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey[800],
                      height: 1.6,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (statesList.isNotEmpty) ...[
                    _buildSectionHeader(Icons.map_rounded, "Geographic Eligibility"),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: statesList.map<Widget>((state) => _buildStateChip(state.toString())).toList(),
                    ),
                  ],

                  // Extra padding for the fixed button at bottom
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // 3. Floating Action Footer
      bottomSheet: _buildStickyFooter(),
    );
  }

  Widget _buildQuickInfoGrid(Map<String, dynamic> scheme) {
    return Row(
      children: [
        _infoCard(
            "Closing Date",
            scheme['close_date'] ?? "N/A",
            Icons.calendar_today_rounded,
            Colors.orange.shade800
        ),
        const SizedBox(width: 16),
        _infoCard(
            "Status",
            "Active", // Example hardcoded value
            Icons.verified_user_rounded,
            const Color(0xFF13383A)
        ),
      ],
    );
  }

  Widget _infoCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStateChip(String label) {
    return Chip(
      label: Text(label.trim()),
      labelStyle: const TextStyle(color: Color(0xFF13383A), fontWeight: FontWeight.w500),
      backgroundColor: const Color(0xFFF0F7F4),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF13383A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF13383A)),
        ),
      ],
    );
  }

  Widget _buildStickyFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF13383A),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text("Apply for Scheme", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}