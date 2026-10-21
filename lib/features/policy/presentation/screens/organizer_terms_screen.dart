import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/policy_scaffold.dart';

/// Screen displaying the official Organizer Terms & Conditions.
class OrganizerTermsScreen extends StatelessWidget {
  const OrganizerTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PolicyScaffold(
      title: 'Organizer Terms & Conditions',
      version: AppConfig.organizerTermsVersion,
      subtitle:
          'By applying to become a tournament organizer or managing tournaments on this platform, you agree to comply with these policies.',
      children: [
        // Commercial & Regulatory Notice Box
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.fieryOrangeDim,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: AppColors.fieryOrangeBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.gavel_rounded,
                color: AppColors.fieryOrange,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Regulatory Notice: The proposed 10% commission and payment rules are provisional business terms. Paid tournament transactions remain strictly disabled until the payment gateway integration and applicable Indian regulatory requirements are fully reviewed.',
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
          title: 'Account Suspension and Ban Policy',
        ),
        const PolicyParagraph(
          leadIn: 'Tournament Scams and Fraud',
          text:
              'Organizers who use tournaments to scam players, publish fake tournaments, collect fees dishonestly, or misrepresent prizes may face suspension or permanent termination.',
        ),
        const PolicyParagraph(
          leadIn: 'Failure to Act Against Cheating',
          text:
              'Organizers must reasonably enforce fair-play rules. Knowingly ignoring verified hacking, unauthorized panels, or cheating may result in a warning, loss of tournament privileges, or a suspension of 2–30 days. Serious or repeated violations may result in a permanent ban.',
        ),
        const PolicyParagraph(
          leadIn: 'Misleading Tournament Information',
          text:
              'Organizers must provide accurate information about tournament rules, schedules, entry fees, prizes, and eligibility.',
        ),
        const PolicyParagraph(
          leadIn: 'Prize and Payment Misconduct',
          text:
              'Deliberately withholding legitimate prizes, misrepresenting prize amounts, or using fraudulent payment evidence may result in suspension or termination.',
        ),
        const PolicyParagraph(
          leadIn: 'Unfair Tournament Management',
          text:
              'Falsifying results, manipulating matches, secretly changing rules to disadvantage players, or providing unfair advantages to selected participants is prohibited.',
        ),
        const PolicyParagraph(
          leadIn: 'Misbehavior and Abuse',
          text:
              'Harassment, threats, discrimination, and abusive conduct may result in suspension or termination.',
        ),
        const PolicyParagraph(
          leadIn: 'Unauthorized Activities',
          text:
              'Organizers must not bypass platform restrictions, misuse player information, or manipulate platform systems.',
        ),
        const PolicyParagraph(
          leadIn: 'Repeated Violations',
          text:
              'Repeated or serious violations may lead to tournament removal, loss of organizer privileges, or a permanent ban.',
        ),
        const PolicyParagraph(
          leadIn: 'Investigation and Appeals',
          text:
              'The platform may review relevant evidence and complaints. Organizers may submit appeals through the designated support channel.',
        ),

        const PolicySectionHeader(
          number: '2',
          title: 'Commission Policy',
        ),
        const PolicyParagraph(
          leadIn: 'Standard Platform Commission',
          text:
              'The proposed standard commission is 10% of the applicable tournament amount, calculated according to the platform\'s disclosed commission rules.',
        ),
        const PolicyParagraph(
          leadIn: 'Commission Changes',
          text:
              'The platform may revise its commission rate. Revised rates must be communicated before they apply, with the effective date and calculation clearly disclosed.',
        ),
        const PolicyParagraph(
          leadIn: 'Commission Disclosure',
          text:
              'Organizers must be able to view the commission rate and applicable amount before publishing or confirming the relevant tournament arrangement.',
        ),
        const PolicyParagraph(
          leadIn: 'Calculation and Settlement',
          text:
              'The calculation basis, payment collection method, settlement schedule, taxes, and applicable processing charges must be disclosed in the relevant payment settings.',
        ),
        const PolicyParagraph(
          leadIn: 'Outstanding Amounts',
          text:
              'Where permitted by applicable law and disclosed terms, unresolved commission obligations may lead to restrictions on publishing new tournaments.',
        ),
        const PolicyParagraph(
          leadIn: 'No Unauthorized Collection',
          text:
              'Organizers must not misrepresent platform commission or collect undisclosed additional charges.',
        ),

        const PolicySectionHeader(
          number: '3',
          title: 'Tournament Management Responsibilities',
        ),
        const PolicyBulletPoint(
          text:
              'Publish accurate tournament rules, schedules, eligibility requirements, and prize details.',
        ),
        const PolicyBulletPoint(
          text: 'Make tournament rules available before registration.',
        ),
        const PolicyBulletPoint(
          text:
              'Provide valid match-room details and communicate schedule changes promptly.',
        ),
        const PolicyBulletPoint(
          text: 'Verify results fairly and retain relevant evidence.',
        ),
        const PolicyBulletPoint(
          text:
              'Respond to legitimate player complaints within a reasonable timeframe.',
        ),
        const PolicyBulletPoint(
          text:
              'Communicate cancellations and applicable refund arrangements clearly.',
        ),
        const PolicyBulletPoint(
          text:
              'Do not change published rules to unfairly disadvantage registered participants.',
        ),

        const PolicySectionHeader(
          number: '4',
          title: 'Anti-Cheating and Fair-Play Enforcement',
        ),
        const PolicyParagraph(
          text:
              'Organizers must take reasonable steps to detect and address cheating, hacking, unauthorized panels, collusion, and match fixing.\n\nCredible reports must be reviewed and handled according to the tournament rules. Knowingly ignoring verified violations may result in suspension or termination of organizer privileges.',
        ),

        const PolicySectionHeader(
          number: '5',
          title: 'Prize Distribution and Disputes',
        ),
        const PolicyParagraph(
          text:
              'Organizers must follow published prize amounts, eligibility requirements, and distribution timelines. Disputes must be reviewed fairly and may be escalated to platform administration.',
        ),

        const PolicySectionHeader(
          number: '6',
          title: 'Player Data and Privacy',
        ),
        const PolicyParagraph(
          text:
              'Organizers may use player information only for legitimate tournament-related purposes. They must not sell, misuse, or disclose personal information without appropriate authorization or a lawful basis.',
        ),

        const PolicySectionHeader(
          number: '7',
          title: 'Organizer Approval',
        ),
        const PolicyParagraph(
          text:
              'Submitting an organizer application does not grant permission to publish or manage tournaments.\n\nOnly an authorized administrator can approve an application. Approval must be verified by the trusted backend before organizer privileges are granted.',
        ),

        const PolicySectionHeader(
          number: '8',
          title: 'Policy Updates',
        ),
        const PolicyParagraph(
          text:
              'Material policy changes must be communicated through the app or another appropriate channel. Revised commission rates and other commercial changes must have clearly disclosed effective dates.',
        ),

        const PolicySectionHeader(
          number: '9',
          title: 'Acceptance',
        ),
        const PolicyParagraph(
          text:
              'By explicitly accepting these terms, you confirm that you have read and understood the Organizer Terms & Conditions and the applicable Privacy Policy.\n\nApplication submission does not guarantee approval.',
        ),
      ],
    );
  }
}

