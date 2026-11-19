import 'package:ferret_docs/landing/download_section.dart';
import 'package:ferret_docs/landing/faq_section.dart';
import 'package:ferret_docs/landing/features_section.dart';
import 'package:ferret_docs/landing/hero_section.dart';
import 'package:ferret_docs/landing/landing_content.dart';
import 'package:ferret_docs/landing/open_source_section.dart';
import 'package:ferret_docs/landing/privacy_section.dart';
import 'package:ferret_docs/landing/site_footer.dart';
import 'package:ferret_docs/landing/site_head.dart';
import 'package:ferret_docs/landing/site_nav.dart';
import 'package:ferret_docs/landing/together_section.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

/// ferret.sofluffy.io: what Ferret is, what it does, and where to get it.
/// Static HTML and one stylesheet; no script.
class LandingPage extends StatelessComponent {
  const LandingPage();

  @override
  Component build(BuildContext context) => Document(
    title: LandingContent.title,
    lang: 'en',
    head: siteHead(
      title: LandingContent.title,
      description: LandingContent.description,
      path: '/',
    ),
    body: const Component.fragment([
      a(classes: 'skip', href: '#main', [Component.text('Skip to content')]),
      SiteNav(),
      main_(id: 'main', [
        HeroSection(),
        TogetherSection(),
        FeaturesSection(),
        PrivacySection(),
        DownloadSection(),
        OpenSourceSection(),
        FaqSection(),
      ]),
      SiteFooter(),
    ]),
  );
}
