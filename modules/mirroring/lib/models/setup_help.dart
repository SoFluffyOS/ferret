/// What Ferret can do about a route's setup step, besides explaining it.
enum SetupHelp {
  /// Nothing: the owner follows the steps.
  none,

  /// The route can download the tool it is missing, once the owner asks.
  download,

  /// The tool is on this computer, but only the owner can start it.
  startTool,
}
