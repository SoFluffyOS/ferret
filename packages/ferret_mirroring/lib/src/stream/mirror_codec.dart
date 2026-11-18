/// How a mirrored screen is encoded.
enum MirrorCodec {
  /// H.264 video, one Annex-B access unit per frame.
  h264,

  /// One JPEG picture per frame: the fallback without a video decoder.
  jpeg,
}
