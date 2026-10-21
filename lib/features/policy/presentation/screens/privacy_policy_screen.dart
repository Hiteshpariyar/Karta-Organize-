import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/policy_scaffold.dart';

/// Screen displaying the official Draft Privacy Policy.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PolicyScaffold(
      title: 'Privacy Policy',
      version: AppConfig.privacyPolicyVersion,
      isDraft: true,
      subtitle:
          'This Privacy Policy outlines how your personal and gaming data is collected, handled, and protected on ${AppConfig.appName}.',
      children: [
        // Notice banner identifying draft status
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.warningDim,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: AppColors.warning),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.edit_document,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'DRAFT NOTICE: This policy document is currently in draft status pending final legal and corporate review by ${AppConfig.legalEntityPlaceholder}. Placeholders indicated in brackets are subject to final platform publication.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const PolicySectionHeader(
          number: '1',
          title: 'Information Collected',
        ),
        const PolicyParagraph(
          text:
              'We collect information necessary to provide tournament matchmaking, anti-cheat validation, and identity verification services. This includes personal information provided during account creation and organizer application submission.',
        ),

        const PolicySectionHeader(
          number: '2',
          title: 'Account and Game Profile Information',
        ),
        const PolicyParagraph(
          leadIn: 'Player Account Information',
          text:
              'Includes your full name, email address, password hash (salted and encrypted), in-game usernames, and game-specific UIDs (e.g., BGMI Character ID, Free Fire UID, Riot ID).',
        ),
        const PolicyParagraph(
          leadIn: 'Organizer Profile Information',
          text:
              'Includes applicant name, organization name, registered email address, contact phone number, in-game administrator UID, supported game titles, and tournament operations preferences.',
        ),
        const PolicyParagraph(
          leadIn: 'Device and Diagnostic Data',
          text:
              'Technical data such as device brand/model, operating system version, and general network logs required for tournament security and anti-cheat fraud prevention.',
        ),

        const PolicySectionHeader(
          number: '3',
          title: 'How Information Is Used',
        ),
        const PolicyBulletPoint(
          text: 'To register, authenticate, and administer your account on the platform.',
        ),
        const PolicyBulletPoint(
          text:
              'To verify match participation, validate slot eligibility, and accurately record leaderboard results.',
        ),
        const PolicyBulletPoint(
          text:
              'To facilitate communication between tournament organizers, players, and platform administrators.',
        ),
        const PolicyBulletPoint(
          text:
              'To investigate cheating reports, match-fixing allegations, unauthorized panels, or abusive conduct.',
        ),
        const PolicyBulletPoint(
          text:
              'To evaluate and process tournament organizer credential applications and compliance.',
        ),

        const PolicySectionHeader(
          number: '4',
          title: 'Data Sharing and Service Providers',
        ),
        const PolicyParagraph(
          text:
              'We do not sell user data. Information is shared strictly under lawful bases, including:\n• Authorized Tournament Organizers: Sharing registered player in-game names and UIDs exclusively for match room setup and roster verification.\n• Infrastructure Partners: Cloud hosting (e.g., Google Cloud Platform / Firebase) operating under strict data processing agreements.\n• Legal Compliance: In response to verified statutory requests or court orders under applicable jurisdiction.',
        ),

        const PolicySectionHeader(
          number: '5',
          title: 'Security and Retention',
        ),
        const PolicyParagraph(
          text:
              'We apply industry-standard security protocols to protect account data against unauthorized access, loss, or disclosure. Data is retained for as long as your account remains active or as required by applicable dispute resolution, anti-fraud, and statutory record-keeping obligations.',
        ),

        const PolicySectionHeader(
          number: '6',
          title: 'User Rights and Contact Information',
        ),
        PolicyParagraph(
          text:
              'Under applicable data protection laws, you may request access to, correction of, or deletion of your personal account data.\n\nFor privacy inquiries, grievance redressal, or data requests, contact:\n• Data Controller: ${AppConfig.legalEntityPlaceholder}\n• Support Email: ${AppConfig.supportEmailPlaceholder}\n• Grievance Officer: ${AppConfig.grievanceOfficerPlaceholder}',
        ),
      ],
    );
  }
}

