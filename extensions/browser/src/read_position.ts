// These run inside the page through scripting.executeScript, only when the
// user sends a tab or opens one with a saved position. They must stay
// self-contained: no imports, no helpers from outside the function.

/** The main video's time and the scroll offset of the page. */
export function readPosition(): { videoTime?: number; scrollY?: number } {
  const videos = Array.from(document.querySelectorAll('video'));
  let best: HTMLVideoElement | undefined;
  let bestArea = 0;
  for (const video of videos) {
    if (!(video.duration > 0) || !(video.currentTime > 0)) continue;
    const rect = video.getBoundingClientRect();
    const area = rect.width * rect.height;
    if (area > bestArea) {
      best = video;
      bestArea = area;
    }
  }

  const result: { videoTime?: number; scrollY?: number } = {};
  if (best) result.videoTime = Math.round(best.currentTime * 10) / 10;
  if (window.scrollY > 0) result.scrollY = Math.round(window.scrollY);
  return result;
}

/** Puts the page back where it was on the other device. */
export function restorePosition(videoTime: number | null, scrollY: number | null): void {
  if (scrollY !== null) window.scrollTo({ top: scrollY });
  if (videoTime === null) return;

  const seek = (): boolean => {
    const video = document.querySelector('video');
    if (!video) return false;
    video.currentTime = videoTime;
    return true;
  };
  if (seek()) return;

  let tries = 0;
  const timer = setInterval(() => {
    tries += 1;
    if (seek() || tries > 20) clearInterval(timer);
  }, 500);
}
