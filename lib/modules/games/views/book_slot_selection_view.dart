import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../data/models/court_model.dart';
import '../controllers/create_game_controller.dart';

class BookSlotSelectionView extends StatelessWidget {
  const BookSlotSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CreateGameController>()
        ? Get.find<CreateGameController>()
        : Get.put(CreateGameController(), permanent: true);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeHeaderImagePath = isDark
        ? 'assets/images/Home_page/dark.png'
        : 'assets/images/Home_page/light.png';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Hero Banner Header with Home Page Image & Back Button
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(24)),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Image.asset(
                      homeHeaderImagePath,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark
                            ? const Color(0xFF07120E)
                            : const Color(0xFF1E1035),
                      ),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(24)),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.60),
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  right: 16,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 24),
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF7E57C2), width: 1.2),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/App_Logo/smash_up_india.png',
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: AppColors.primary,
                              child: const Icon(Icons.sports_soccer_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Smash Up India',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Scrollable Content
            Expanded(
              child: ResponsiveBuilder(
                builder: (context, deviceType) {
                  final isTabletOrDesktop = deviceType == DeviceType.desktop ||
                      deviceType == DeviceType.tablet;
                  final isLandscape = MediaQuery.of(context).orientation ==
                      Orientation.landscape;
                  final maxContainerWidth = (isTabletOrDesktop || isLandscape)
                      ? 680.0
                      : double.infinity;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContainerWidth),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Book a Slot',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Grid of Court Cards
                            _buildGridCourtCards(context, controller),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCourtCards(
      BuildContext context, CreateGameController controller) {
    return Obx(() {
      final pickleCourts = controller.availableCourts
          .where((c) =>
              !c.name.toLowerCase().contains('padel') &&
              !c.id.toLowerCase().contains('padel'))
          .toList();

      final padelCourts = controller.availableCourts
          .where((c) =>
              c.name.toLowerCase().contains('padel') ||
              c.id.toLowerCase().contains('padel'))
          .toList();

      final List<Map<String, dynamic>> items = [];

      final defaultPickle = [
        CourtModel(
          id: 'court_1',
          clubId: 'smash_up_india_club',
          clubName: 'Smash Up India',
          name: 'Pickle Court 1',
          surfaceType: 'Turf',
          basePricePerHour: 1200.0,
          status: 'AVAILABLE',
          city: 'Raipur',
          address: 'VIP Road, Raipur',
        ),
        CourtModel(
          id: 'court_2',
          clubId: 'smash_up_india_club',
          clubName: 'Smash Up India',
          name: 'Pickle Court 2',
          surfaceType: 'Turf',
          basePricePerHour: 1200.0,
          status: 'AVAILABLE',
          city: 'Raipur',
          address: 'VIP Road, Raipur',
        ),
        CourtModel(
          id: 'court_3',
          clubId: 'smash_up_india_club',
          clubName: 'Smash Up India',
          name: 'Pickle Court 3',
          surfaceType: 'Turf',
          basePricePerHour: 1200.0,
          status: 'AVAILABLE',
          city: 'Raipur',
          address: 'VIP Road, Raipur',
        ),
      ];

      final defaultPadel = CourtModel(
        id: 'padel_court_1',
        clubId: 'smash_up_india_club',
        clubName: 'Smash Up India',
        name: 'Padel Court 1',
        surfaceType: 'Standard',
        basePricePerHour: 1200.0,
        status: 'AVAILABLE',
        city: 'Raipur',
        address: 'VIP Road, Raipur',
      );

      final activePickle =
          pickleCourts.isNotEmpty ? pickleCourts : defaultPickle;
      final activePadel = padelCourts.isNotEmpty ? padelCourts : [defaultPadel];

      for (final c in activePickle) {
        items.add({'sport': 'Pickle', 'court': c});
      }
      for (final c in activePadel) {
        items.add({'sport': 'Padel', 'court': c});
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final double cardWidth = (constraints.maxWidth - 12) / 2;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((item) {
              final sport = item['sport'] as String;
              final court = item['court'] as CourtModel;
              return SizedBox(
                width: cardWidth,
                child: _buildCourtGridCard(
                  context,
                  controller,
                  sport: sport,
                  court: court,
                ),
              );
            }).toList(),
          );
        },
      );
    });
  }

  Widget _buildCourtGridCard(
    BuildContext context,
    CreateGameController controller, {
    required String sport,
    required CourtModel court,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cStatus = court.status.toUpperCase();
    final isAvailable = cStatus == 'AVAILABLE';
    final priceStr = '₹ ${court.basePricePerHour.toStringAsFixed(0)} onwards';

    final surfaceLabel = court.surfaceType.contains('Turf')
        ? 'Turf'
        : (court.surfaceType.contains('Standard')
            ? 'Standard'
            : court.surfaceType);

    final title = '${court.name} ($surfaceLabel)';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top White / Dark Card Portion
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  priceStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Teal / Primary Green Button Portion
          InkWell(
            onTap: isAvailable
                ? () {
                    controller.selectedGameTitle.value = sport;
                    controller.selectCourt(court);
                    Get.toNamed(
                      Routes.createGame,
                      arguments: {
                        'sport': sport,
                        'courtId': court.id,
                        'courtName': court.name,
                      },
                    );
                  }
                : null,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isAvailable ? AppColors.primary : Colors.grey.shade600,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Center(
                child: Text(
                  isAvailable ? 'BOOK' : 'UNAVAILABLE',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
