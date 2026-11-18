// Puts a video's position into its link, so the other device resumes at the
// same spot even without the extension (the YouTube app reads `t` too).

const directMedia = /\.(mp4|m4v|webm|ogv|ogg|mov|mp3|m4a|wav|flac)$/i;

/** Links that carry their own time, such as YouTube's `t=`. */
export function withVideoTime(url: string, seconds: number | undefined): string {
  if (seconds === undefined || !Number.isFinite(seconds) || seconds < 1) return url;

  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return url;
  }

  const whole = Math.floor(seconds);
  const host = parsed.hostname.replace(/^(www\.|m\.|music\.)/, '');

  if (host === 'youtube.com' && (parsed.pathname === '/watch' || parsed.pathname.startsWith('/live/'))) {
    parsed.searchParams.set('t', `${whole}s`);
    return parsed.toString();
  }

  if (host === 'youtu.be') {
    parsed.searchParams.set('t', `${whole}s`);
    return parsed.toString();
  }

  if (host === 'vimeo.com') {
    parsed.hash = `t=${whole}s`;
    return parsed.toString();
  }

  if (directMedia.test(parsed.pathname)) {
    parsed.hash = `t=${whole}`;
    return parsed.toString();
  }

  return url;
}

/** Whether [url]'s link already resumes the video, so seeking isn't needed. */
export function linkCarriesTime(url: string): boolean {
  return withVideoTime(url, 60) !== url;
}
