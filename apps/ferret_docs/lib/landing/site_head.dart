import 'package:ferret_docs/landing/site_links.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The `<head>` tags every hand-built page on the site shares: icons, the
/// stylesheet, the font, and what a link preview shows.
List<Component> siteHead({
  required String title,
  required String description,
  required String path,
}) => [
  meta(name: 'description', content: description),
  const meta(name: 'color-scheme', content: 'light dark'),
  const meta(
    name: 'theme-color',
    content: '#F5EBDC',
    attributes: {'media': '(prefers-color-scheme: light)'},
  ),
  const meta(
    name: 'theme-color',
    content: '#1C1715',
    attributes: {'media': '(prefers-color-scheme: dark)'},
  ),
  link(rel: 'canonical', href: '${SiteLinks.origin}$path'),
  const link(rel: 'icon', type: 'image/svg+xml', href: SiteLinks.logo),
  const link(rel: 'icon', href: '/favicon.ico', attributes: {'sizes': '48x48'}),
  const link(rel: 'apple-touch-icon', href: '/images/apple-touch-icon.png'),
  const link(
    rel: 'preload',
    href: '/fonts/nunito-latin.woff2',
    attributes: {'as': 'font', 'type': 'font/woff2', 'crossorigin': ''},
  ),
  const link(rel: 'stylesheet', href: SiteLinks.stylesheet),
  const meta(attributes: {'property': 'og:type'}, content: 'website'),
  const meta(attributes: {'property': 'og:site_name'}, content: 'Ferret'),
  meta(attributes: {'property': 'og:title'}, content: title),
  meta(attributes: {'property': 'og:description'}, content: description),
  meta(attributes: {'property': 'og:url'}, content: '${SiteLinks.origin}$path'),
  const meta(
    attributes: {'property': 'og:image'},
    content: SiteLinks.socialImage,
  ),
  const meta(attributes: {'property': 'og:image:width'}, content: '1200'),
  const meta(attributes: {'property': 'og:image:height'}, content: '630'),
  const meta(
    attributes: {'property': 'og:image:alt'},
    content: 'The Ferret icon next to the Ferret window on a Mac',
  ),
  const meta(name: 'twitter:card', content: 'summary_large_image'),
  meta(name: 'twitter:title', content: title),
  meta(name: 'twitter:description', content: description),
  const meta(name: 'twitter:image', content: SiteLinks.socialImage),
];
