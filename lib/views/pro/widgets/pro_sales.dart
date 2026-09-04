import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/base/button.dart';
import '../../../shared/general/base/constrained_box.dart';
import '../../../stores/pro_store.dart';
import '../../../utils/styling_helper.dart';
import '../../settings/privacy_policy/privacy_policy.dart';
import 'pro_benefits.dart';
import 'pro_hero.dart';
import 'pro_pricing.dart';

/// Apple's standard EULA (the app ships no custom terms document)
final Uri _kTermsUri = Uri.parse(
  'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
);

/// The not-Pro side of the paywall: hero, browsable benefits, pricing,
/// restore, legal link-outs. Phone and tablet compositions differ via the
/// design-system seams ([ResponsiveWidgetWrapper] inside the benefit and
/// pricing widgets, 640 content column here).
class ProSalesView extends StatelessWidget {
  final ProStore store;

  const ProSalesView({super.key, required this.store});

  Future<void> _openTerms(BuildContext context) async {
    try {
      await launchUrl(_kTermsUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Couldn\'t open the link.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: StylingHelper.platformAwareScrollPhysics,
      child: Center(
        child: BaseConstrainedBox(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              StaggeredEntrance(index: 0, child: ProHero(store: this.store)),
              const SizedBox(height: AppSpacing.lg),
              StaggeredEntrance(
                index: 1,
                child: Text(
                  'Everything you already use — OBS control, stats, '
                  'WebView chat — stays free. Forever.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const StaggeredEntrance(index: 2, child: ProBenefitsBrowser()),
              const SizedBox(height: AppSpacing.xl),
              StaggeredEntrance(
                index: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        'CHOOSE YOUR PRO',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    ProPricing(store: this.store),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              StaggeredEntrance(
                index: 4,
                child: Column(
                  children: [
                    Observer(
                      builder: (context) => BaseButton(
                        text: 'Restore purchases',
                        secondary: true,
                        onPressed: this.store.pending
                            ? null
                            : () => this.store.restore(explicit: true),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegalLink(
                          text: 'Terms of Use',
                          onTap: () => this._openTerms(context),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Text(
                            '·',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        _LegalLink(
                          text: 'Privacy Policy',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const PrivacyPolicyView(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _LegalLink({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: this.onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Text(
          this.text,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).buttonTheme.colorScheme!.secondary,
              ),
        ),
      ),
    );
  }
}
