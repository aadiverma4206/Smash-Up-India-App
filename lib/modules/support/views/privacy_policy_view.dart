import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
                  const Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('All Stars Arena Privacy Notice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Your Privacy & Data Protection Commitment', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              _buildSection(
                context,
                title: '1. Information We Collect',
                content:
                    'We collect essential personal information required for service operation, including your name, mobile number, email address, profile avatar, and device location (to show nearby turf courts and match finder results).',
              ),
              _buildSection(
                context,
                title: '2. Payment & Financial Data Security',
                content:
                    'All credit card, debit card, UPI, and net banking transactions are processed through end-to-end encrypted Razorpay payment gateways. All Stars Arena does not store raw credit card numbers or banking passwords on its servers.',
              ),
              _buildSection(
                context,
                title: '3. How We Use Your Information',
                content:
                    'Your data is exclusively used to fulfill turf bookings, calculate player match ratings (OVR/ELO), process wallet top-ups, send booking notifications, and provide CCTV video playback features.',
              ),
              _buildSection(
                context,
                title: '4. Data Storage & Encryption',
                content:
                    'We employ industry-standard SSL/TLS encryption for all REST and WebSocket communication. User profile photos and CCTV recordings are securely stored using Amazon Web Services (AWS S3) with restricted access policies.',
              ),
              _buildSection(
                context,
                title: '5. Account Deletion & Rights',
                content:
                    'You retain full rights to inspect, update, or request the deletion of your personal data and account details by contacting privacy@allstarsarena.com or reaching out through Chat Support.',
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'ALL STARS ARENA • PRIVACY & DATA SAFETY',
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
