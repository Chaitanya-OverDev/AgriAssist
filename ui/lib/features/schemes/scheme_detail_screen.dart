import 'package:flutter/material.dart';
import 'package:agriassist/l10n/app_localizations.dart';

class SchemeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> scheme;

  const SchemeDetailScreen({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {

    final t = AppLocalizations.of(context)!;

    final statesList = scheme['states'] is List
        ? scheme['states'] as List
        : (scheme['states']?.toString().split(',') ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [

          /// HEADER
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF13383A),

            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],

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
                    size: 100,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              title: Padding(
                padding: const EdgeInsets.only(right: 16, left: 16),
                child: Text(
                  scheme['scheme_name'] ?? t.schemeDetails,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black26,
                      )
                    ],
                  ),
                ),
              ),

              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
            ),
          ),

          /// MAIN CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  /// QUICK INFO
                  _buildQuickInfoGrid(context, scheme),

                  const SizedBox(height: 32),

                  /// OVERVIEW
                  _buildSectionHeader(
                    Icons.description_rounded,
                    t.overview,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    scheme['description'] ?? t.noDescription,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey[800],
                      height: 1.6,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// STATE ELIGIBILITY
                  if (statesList.isNotEmpty) ...[

                    _buildSectionHeader(
                      Icons.map_rounded,
                      t.geographicEligibility,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      statesList
                          .join(", ")
                          .replaceAll('[', '')
                          .replaceAll(']', ''),

                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey[800],
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      /// APPLY BUTTON
      bottomSheet: _buildStickyFooter(context),
    );
  }

  /// QUICK INFO GRID
  Widget _buildQuickInfoGrid(
      BuildContext context,
      Map<String, dynamic> scheme,
      ) {

    final t = AppLocalizations.of(context)!;

    return Row(
      children: [

        _infoCard(
          t.closingDate,
          scheme['close_date'] ?? t.notAvailable,
          Icons.calendar_today_rounded,
          Colors.orange.shade800,
        ),

        const SizedBox(width: 16),

        _infoCard(
          t.status,
          t.active,
          Icons.verified_user_rounded,
          const Color(0xFF13383A),
        ),
      ],
    );
  }

  Widget _infoCard(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {

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

            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),

            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      IconData icon,
      String title,
      ) {

    return Row(
      children: [

        Container(
          padding: const EdgeInsets.all(6),

          decoration: BoxDecoration(
            color: const Color(0xFF13383A),
            borderRadius: BorderRadius.circular(8),
          ),

          child: Icon(
            icon,
            size: 18,
            color: Colors.white,
          ),
        ),

        const SizedBox(width: 12),

        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF13383A),
          ),
        ),
      ],
    );
  }

  /// APPLY BUTTON
  Widget _buildStickyFooter(BuildContext context) {

    final t = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 52),

      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),

      child: ElevatedButton(

        onPressed: () {},

        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF13383A),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),

        child: Text(
          t.applyForScheme,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}