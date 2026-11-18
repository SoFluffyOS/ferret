import Foundation

/// A player app that answers AppleScript, such as Music or Spotify.
struct ScriptablePlayer {
  let bundleId: String
  let name: String
  /// Posted by the app on every play, pause or track change.
  let changeNotification: String
  /// Whether the app reports duration in milliseconds instead of seconds.
  let durationInMilliseconds: Bool
  /// The AppleScript property that holds a link to the track, if any.
  let linkProperty: String?
  /// Whether `data of artwork 1` returns the image bytes.
  let hasArtworkData: Bool

  static let music = ScriptablePlayer(
    bundleId: "com.apple.Music",
    name: "Music",
    changeNotification: "com.apple.Music.playerInfo",
    durationInMilliseconds: false,
    linkProperty: nil,
    hasArtworkData: true
  )

  // Spotify only offers an artwork URL; fetching it would be a network call
  // to a third party, which Ferret never makes.
  static let spotify = ScriptablePlayer(
    bundleId: "com.spotify.client",
    name: "Spotify",
    changeNotification: "com.spotify.client.PlaybackStateChanged",
    durationInMilliseconds: true,
    linkProperty: "spotify url",
    hasArtworkData: false
  )

  static let all = [music, spotify]

  /// Returns state, title, artist, album, duration, position, volume, track
  /// id and link, or just the state when nothing is loaded.
  var stateScript: String {
    let link = linkProperty.map { "\($0) of t" } ?? "\"\""
    return """
      with timeout of 3 seconds
        tell application id "\(bundleId)"
          set playerState to player state as string
          if playerState is "stopped" then return {playerState}
          set t to current track
          return {playerState, name of t, artist of t, album of t, duration of t, player position, sound volume, (id of t) as string, \(link)}
        end tell
      end timeout
      """
  }

  var artworkScript: String {
    return """
      with timeout of 3 seconds
        tell application id "\(bundleId)"
          if (count of artworks of current track) is 0 then return ""
          return data of artwork 1 of current track
        end tell
      end timeout
      """
  }

  func commandScript(_ action: PlayerAction, positionMs: Int64, volume: Double) -> String {
    let verb: String
    switch action {
    case .play: verb = "play"
    case .pause: verb = "pause"
    case .toggle: verb = "playpause"
    case .next: verb = "next track"
    case .previous: verb = "previous track"
    case .seek: verb = "set player position to \(Double(positionMs) / 1000.0)"
    case .setVolume: verb = "set sound volume to \(Int((max(0, min(1, volume)) * 100).rounded()))"
    }
    return """
      with timeout of 3 seconds
        tell application id "\(bundleId)" to \(verb)
      end timeout
      """
  }
}
