cask "ferret" do
  version "{{VERSION}}"
  sha256 "{{SHA256_DMG}}"

  url "https://github.com/SoFluffyOS/ferret/releases/download/v#{version}/Ferret-#{version}.dmg"
  name "Ferret"
  desc "Continue what you were doing on any of your devices"
  homepage "https://github.com/SoFluffyOS/ferret"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :monterey"

  app "Ferret.app"
  # ferret-cli is built for Apple silicon only: dart can't cross-compile it for Intel.
  on_arm do
    binary "#{appdir}/Ferret.app/Contents/Helpers/ferret-cli"
  end

  uninstall quit: "io.sofluffy.ferret"

  zap trash: [
    "~/.sofluffy/ferret",
    "~/Library/Containers/io.sofluffy.ferret.Share",
    "~/Library/Group Containers/66UZUS2MST.io.sofluffy.ferret",
    "~/Library/Preferences/io.sofluffy.ferret.plist",
  ]
end
