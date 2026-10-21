import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../widgets/policy_scaffold.dart';

/// Screen displaying the official Player Terms & Conditions.
class PlayerTermsScreen extends StatelessWidget {
  const PlayerTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PolicyScaffold(
      title: 'Player Terms & Conditions',
      version: AppConfig.playerTermsVersion,
      subtitle:
          'By creating an account, booking a tournament slot, or participating in a tournament on the platform, you agree to follow these rules.',
      children: const [
        PolicySectionHeader(
          number: '1',
          title: 'Account Suspension and Termination Policy',
        ),
        PolicyParagraph(
          leadIn: 'Hacking, Cheats, and Unauthorized Panels',
          text:
              'Players found using hacks, cheats, unauthorized panels, scripts, exploits, or other prohibited tools may be disqualified, temporarily suspended, or permanently banned.',
        ),
        PolicyParagraph(
          leadIn: 'Misbehavior and Harassment',
          text:
              'Abusive language, threats, bullying, harassment, discrimination, or inappropriate conduct toward players, organizers, administrators, or support staff may result in a warning, a suspension of 3–30 days, or permanent termination in serious or repeated cases.',
        ),
        PolicyParagraph(
          leadIn: 'Match Fixing and Unfair Play',
          text:
              'Match fixing, unauthorized teaming, deliberate result manipulation, and exploiting game bugs to obtain an unfair advantage are prohibited.',
        ),
        PolicyParagraph(
          leadIn: 'Fake Identity and Account Abuse',
          text:
              'Providing false information, impersonating another player, intentionally submitting fraudulent game IDs, or creating duplicate accounts to bypass restrictions may result in account restrictions or termination.',
        ),
        PolicyParagraph(
          leadIn: 'Fraudulent Activities',
          text:
              'Fake payment screenshots, payment fraud, fraudulent refund claims, and attempts to manipulate tournament results may result in account restrictions and further action where appropriate.',
        ),
        PolicyParagraph(
          leadIn: 'Repeated Violations',
          text:
              'Repeated violations may lead to progressively stricter penalties, including permanent suspension.',
        ),
        PolicyParagraph(
          leadIn: 'Investigation and Appeals',
          text:
              'The platform may review available evidence before taking action. Players may submit an appeal through the designated support channel.',
        ),

        PolicySectionHeader(
          number: '2',
          title: 'Refund Policy',
        ),
        PolicyParagraph(
          leadIn: 'Confirmed Tournament Slots',
          text:
              'Confirmed tournament bookings are generally non-refundable, except where required by applicable law or expressly provided under this policy.',
        ),
        PolicyParagraph(
          leadIn: 'Cheating and Disqualification',
          text:
              'Players verified to have cheated, hacked, or used unauthorized panels may be disqualified and may be ineligible for a refund, subject to applicable law.',
        ),
        PolicyParagraph(
          leadIn: 'Tournament Cancellation',
          text:
              'If a tournament is cancelled by the organizer or platform, eligible players will be informed of the applicable refund or alternative resolution process.',
        ),
        PolicyParagraph(
          leadIn: 'Technical Issues',
          text:
              'Payment failures, duplicate transactions, server outages, and platform-side errors will be reviewed according to the applicable refund procedure.',
        ),
        PolicyParagraph(
          leadIn: 'Duplicate Payments',
          text:
              'Verified duplicate payments for the same booking may be reviewed for a refund.',
        ),
        PolicyParagraph(
          leadIn: 'Incorrect Player Information',
          text:
              'Players must provide accurate game IDs and registration details. Refund eligibility for bookings affected by incorrect information will depend on the circumstances and applicable law.',
        ),
        PolicyParagraph(
          leadIn: 'Refund Processing',
          text:
              'Approved refunds will be processed within the timeframe communicated by the platform. Bank or payment-provider processing may take additional time.',
        ),
        PolicyParagraph(
          leadIn: 'Fraudulent Refund Requests',
          text:
              'False payment evidence or intentionally fraudulent claims may lead to account restrictions.',
        ),

        PolicySectionHeader(
          number: '3',
          title: 'Tournament Participation Rules',
        ),
        PolicyBulletPoint(
          text:
              'Players must provide accurate registration details, including their in-game name and UID.',
        ),
        PolicyBulletPoint(
          text:
              'Players must follow published schedules, match instructions, and game-specific rules.',
        ),
        PolicyBulletPoint(
          text:
              'Players must join matches on time and comply with valid tournament instructions.',
        ),
        PolicyBulletPoint(
          text: 'Sharing private room credentials without authorization is prohibited.',
        ),
        PolicyBulletPoint(
          text: 'Players must not intentionally disrupt tournament operations.',
        ),
        PolicyBulletPoint(
          text:
              'Published tournament rules must be followed unless they conflict with platform policies or applicable law.',
        ),

        PolicySectionHeader(
          number: '4',
          title: 'Fair Play and Sportsmanship',
        ),
        PolicyParagraph(
          text:
              'Players must compete fairly and respectfully. Cheating, collusion, match manipulation, harassment, and attempts to obtain unauthorized advantages are prohibited.\n\nThe platform may review reports and relevant evidence when investigating alleged violations.',
        ),

        PolicySectionHeader(
          number: '5',
          title: 'Account Security',
        ),
        PolicyParagraph(
          text:
              'Players are responsible for protecting their credentials and reporting suspicious account activity. Account sharing or unauthorized transfers may be restricted under platform rules.',
        ),

        PolicySectionHeader(
          number: '6',
          title: 'Policy Updates',
        ),
        PolicyParagraph(
          text:
              'Material policy changes will be communicated through the app or another appropriate channel. Where required, users must accept updated policy versions before accessing affected features.',
        ),

        PolicySectionHeader(
          number: '7',
          title: 'Acceptance',
        ),
        PolicyParagraph(
          text:
              'By explicitly accepting these terms, you confirm that you have read and understood the Player Terms & Conditions and the applicable Privacy Policy.\n\nNote: Applicable consumer protection and statutory legal rights remain preserved and are not overridden by this policy.',
        ),
      ],
    );
  }
}

