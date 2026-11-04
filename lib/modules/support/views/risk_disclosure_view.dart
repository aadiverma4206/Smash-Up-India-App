import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class RiskDisclosureView extends StatelessWidget {
  const RiskDisclosureView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Risk Disclosure',
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
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.amber, size: 30),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Sports & Physical Activity Risk Disclosure',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Safety Guidelines & Liability Awareness',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _buildSection(
                context,
                title: '1. Assumption of Athletic Risk',
                content:
                    'Participating in pickle, cricket, padel, or other turf sports involves inherent physical risks, including but not limited to sprains, fractures, muscle tears, or accidental collisions with other players or pitch netting.',
              ),
              _buildSection(
                context,
                title: '2. Personal Physical Fitness',
                content:
                    'Players are strongly advised to ensure they are in suitable physical condition before engaging in high-intensity match play. Warm-up stretches and hydration are recommended before entering the pitch.',
              ),
              _buildSection(
                context,
                title: '3. Mandatory Equipment & Footwear',
                content:
                    'To reduce injury risk and protect turf grass fibers, players must wear proper turf shoes or sports sneakers. Shin guards are strongly encouraged during competitive tournament games.',
              ),
              _buildSection(
                context,
                title: '4. Weather Conditions & Field Safety',
                content:
                    'In cases of extreme rain, lightning, or severe weather conditions, ground managers reserve the right to temporarily pause or reschedule match slots to guarantee player safety.',
              ),
              _buildSection(
                context,
                title: '5. Limitation of Liability',
                content:
                    'Smash Up India and affiliated turf club managers shall not be held liable for personal injuries, physical accidents, or loss of personal belongings occurring on ground premises beyond gross negligence.',
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'SMASH UP INDIA • ATHLETIC SAFETY & DISCLOSURE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.grey.shade600,
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

  Widget _buildSection(BuildContext context,
      {required String title, required String content}) {
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
              color:
                  isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
