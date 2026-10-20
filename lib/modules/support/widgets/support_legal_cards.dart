import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';

class SupportAndLegalSection extends StatelessWidget {
  const SupportAndLegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final dividerColor =
        isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9);
    final textColor =
        isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              _buildSupportTile(
                context,
                icon: Icons.help_outline_rounded,
                title: 'FAQ',
                onTap: () => Get.toNamed(Routes.faq),
                dividerColor: dividerColor,
              ),
              _buildSupportTile(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Chat Support',
                onTap: () => Get.toNamed(Routes.chatSupport),
                dividerColor: dividerColor,
              ),
              _buildSupportTile(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Call Support',
                trailingText: '1800-XXX-XXXX',
                onTap: () => Get.toNamed(Routes.callSupport),
                dividerColor: Colors.transparent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Legal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              _buildSupportTile(
                context,
                icon: Icons.article_outlined,
                title: 'Terms & Conditions',
                onTap: () => Get.toNamed(Routes.termsConditions),
                dividerColor: dividerColor,
              ),
              _buildSupportTile(
                context,
                icon: Icons.article_outlined,
                title: 'Privacy Policy',
                onTap: () => Get.toNamed(Routes.privacyPolicy),
                dividerColor: dividerColor,
              ),
              _buildSupportTile(
                context,
                icon: Icons.article_outlined,
                title: 'Risk Disclosure',
                onTap: () => Get.toNamed(Routes.riskDisclosure),
                dividerColor: Colors.transparent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
    required Color dividerColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color:
                      isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (trailingText != null) ...[
                  Text(
                    trailingText,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color:
                      isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
        if (dividerColor != Colors.transparent)
          Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
