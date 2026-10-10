import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class TermsConditionsView extends StatelessWidget {
  const TermsConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.article_outlined, color: AppColors.primary, size: 28),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('All Stars Arena Terms of Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Last updated: May 2024 • Version 1.2', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              _buildSection(
                context,
                title: '1. Acceptance of Terms',
                content:
                    'By downloading, installing, or using the All Stars Arena application and booking services, you agree to be bound by these Terms and Conditions. If you do not agree to all terms, please refrain from using our services.',
              ),
              _buildSection(
                context,
                title: '2. Turf Booking & Slot Confirmation',
                content:
                    'All court bookings made via the app are subject to slot availability and instant payment verification. A booking is considered final only when a booking confirmation pass is generated and displayed under "My Requests".',
              ),
              _buildSection(
                context,
                title: '3. Cancellation & Refund Policy',
                content:
                    'Bookings canceled at least 4 hours prior to the slot time are eligible for a full refund into your Arena Wallet. Cancellations within 4 hours of the reserved slot time may incur a partial retention fee as mandated by individual turf club policies.',
              ),
              _buildSection(
                context,
                title: '4. On-Field Conduct & Safety Protocol',
                content:
                    'Players and spectators must strictly abide by pitch rules. Appropriate turf footwear (TF studs or sports shoes) is mandatory. Damaging turf netting, floodlights, or ground equipment will result in financial liability and account suspension.',
              ),
              _buildSection(
                context,
                title: '5. Account Security',
                content:
                    'You are responsible for safeguarding your login credentials and Arena Wallet PIN. Any activity performed from your authenticated user session will be attributed to your registered account.',
              ),
              _buildSection(
                context,
                title: '6. Live Streaming & Media Rights',
                content:
                    'Match highlights and CCTV streams recorded on All Stars Arena pitches may be processed for leaderboard analytics, MVP highlight clips, and tournament playback features within the app.',
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'ALL STARS ARENA • LEGAL DEPARTMENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String content}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
