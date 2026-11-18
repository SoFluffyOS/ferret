/// The screen this receiver tells phones it has. Phones size and pace
/// their picture to fit it.
class AirPlayDisplay {
  const AirPlayDisplay({
    this.width = 1920,
    this.height = 1080,
    this.refreshRate = 60,
    this.maxFps = 30,
  });

  final int width;
  final int height;
  final int refreshRate;
  final int maxFps;
}
