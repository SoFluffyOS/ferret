/**
 * The extension's manifest for each browser. One codebase, two manifests:
 * Chromium runs the background as a service worker, Firefox as a background
 * script with its own add-on id.
 */
export const firefoxId = 'browser@ferret.sofluffy.io';

/** @param {'chromium' | 'firefox'} target @param {string} version */
export function manifestFor(target, version) {
  const base = {
    manifest_version: 3,
    name: 'Ferret',
    short_name: 'Ferret',
    version,
    description:
      'Send tabs to your devices with Ferret, and open the pages they send here. Local network only, no account.',
    icons: icons(),
    action: {
      default_title: 'Ferret',
      default_popup: 'popup.html',
      default_icon: icons(),
    },
    options_ui: { page: 'options.html', open_in_tab: true },
    permissions: [
      'activeTab',
      'alarms',
      'contextMenus',
      'notifications',
      'scripting',
      'storage',
    ],
    optional_permissions: ['tabs'],
    optional_host_permissions: ['<all_urls>'],
    commands: {
      'send-tab': {
        suggested_key: { default: 'Alt+Shift+S' },
        description: 'Send this tab to your last device',
      },
      _execute_action: {
        suggested_key: { default: 'Alt+Shift+F' },
      },
    },
    content_security_policy: {
      extension_pages: "script-src 'self'; object-src 'self'",
    },
  };

  if (target === 'firefox') {
    return {
      ...base,
      background: { scripts: ['background.js'] },
      browser_specific_settings: {
        gecko: {
          id: firefoxId,
          strict_min_version: '128.0',
          data_collection_permissions: { required: ['none'] },
        },
      },
    };
  }

  return {
    ...base,
    minimum_chrome_version: '116',
    background: { service_worker: 'background.js' },
  };
}

function icons() {
  return {
    16: 'icons/icon-16.png',
    32: 'icons/icon-32.png',
    64: 'icons/icon-64.png',
    128: 'icons/icon-128.png',
  };
}
