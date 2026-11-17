import Cocoa
import FlutterMacOS
import ferret_menubar

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let engine = FlutterEngine(name: "ferret", project: nil)
    engine.run(withEntrypoint: nil)
    RegisterGeneratedPlugins(registry: engine)

    let flutterViewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)

    super.awakeFromNib()

    FerretMenubarPlugin.install(flutterViewController: flutterViewController, hiding: self)
  }
}
