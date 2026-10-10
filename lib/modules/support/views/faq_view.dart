import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';

class FaqView extends StatefulWidget {
  const FaqView({super.key});

  @override
  State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<Map<String, String>> _categories = [
    {'name': 'All', 'icon': 'apps'},
    {'name': 'Bookings', 'icon': 'stadium'},
    {'name': 'Payments', 'icon': 'wallet'},
    {'name': 'Rules', 'icon': 'sports_soccer'},
    {'name': 'Account', 'icon': 'person'},
  ];

  final List<Map<String, String>> _faqs = [
    {
      'category': 'Bookings',
      'question': 'How do I book a turf slot on All Stars Arena?',
      'answer': 'Navigate to the Courts tab or Game Finder, select your desired turf pitch, choose a date and time slot, and proceed to payment. Once confirmed, you will receive an instant booking pass.',
    },
    {
      'category': 'Bookings',
      'question': 'Can I cancel or reschedule my turf booking?',
      'answer': 'Bookings can be canceled up to 4 hours before the slot time from "My Requests". Refunds will be credited to your Arena Wallet automatically as per club policy.',
    },
    {
      'category': 'Payments',
      'question': 'What payment methods are supported?',
      'answer': 'We support UPI (GPay, PhonePe, Paytm), Credit/Debit Cards, Net Banking, and Arena Wallet balances secured with Razorpay payment processing.',
    },
    {
      'category': 'Payments',
      'question': 'How does the Arena Wallet balance work?',
      'answer': 'You can add funds to your wallet for instant checkout without needing OTPs for every game. Wallet refunds are processed instantly.',
    },
    {
      'category': 'Rules',
      'question': 'What footwear is allowed on artificial turf courts?',
      'answer': 'Only rubber studs (TF/Turf shoes) or standard non-marking sports sneakers are allowed. Metal studs and spiked shoes are strictly prohibited to prevent field damage and injury.',
    },
    {
      'category': 'Rules',
      'question': 'Are CCTV live streams available for all matches?',
      'answer': 'Live CCTV feeds and match highlights are available for registered tournament matches and selected booked grounds through the CCTV tab.',
    },
    {
      'category': 'Account',
      'question': 'How is my player OVR and ELO rating calculated?',
      'answer': 'Your OVR rating increases based on match attendance, goal contributions, match MVP awards, and win ratios updated after verified match score submissions.',
    },
    {
      'category': 'Account',
      'question': 'How can I update my profile picture or account details?',
      'answer': 'Go to your Profile tab, tap the camera icon overlay on your avatar to upload a photo, or edit your personal credentials from the Edit Profile section.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredFaqs = _faqs.where((faq) {
      final matchesCategory = _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      final matchesSearch = faq['question']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'FAQ & Help Center',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SEARCH & CATEGORY HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE),
                  ),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search questions, rules, payments...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1035) : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat['name'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(cat['name']!),
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            backgroundColor: isDark ? const Color(0xFF1E1035) : Colors.grey.shade200,
                            onSelected: (_) => setState(() => _selectedCategory = cat['name']!),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // FAQ ITEMS LIST
            Expanded(
              child: filteredFaqs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 54, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'No matching questions found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try searching with different keywords or contact our live support.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredFaqs.length,
                      itemBuilder: (context, index) {
                        final item = filteredFaqs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                            ),
                          ),
                          color: Theme.of(context).cardColor,
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 20),
                            ),
                            title: Text(
                              item['question']!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Text(
                                  item['answer']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // BOTTOM ACTION BAR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.headset_mic_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Still have questions?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Our support team is online 24/7', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.toNamed(Routes.chatSupport),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Chat Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
