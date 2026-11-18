// Firefox names the promise-based API `browser`, Chromium `chrome`. Both
// return promises in Manifest V3, so one set of calls works in each.
declare const browser: typeof chrome | undefined;

export const ext: typeof chrome = typeof browser !== 'undefined' ? browser : chrome;
