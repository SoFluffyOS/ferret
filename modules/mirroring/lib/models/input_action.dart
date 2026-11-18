import 'package:ferret_mirroring/ferret_mirroring.dart';

/// What a click, a scroll or a key press on the mirrored picture means
/// for the device being shown.
sealed class InputAction {
  const InputAction();
}

class SendPointer extends InputAction {
  const SendPointer(this.pointer);

  final MirrorPointer pointer;
}

class SendKey extends InputAction {
  const SendKey(this.key);

  final MirrorKey key;
}

/// Characters the device's own key map can type.
class SendText extends InputAction {
  const SendText(this.text);

  final String text;
}

/// Characters that only get through by way of the device's clipboard,
/// such as accents and emoji.
class PasteText extends InputAction {
  const PasteText(this.text);

  final String text;
}

/// Pastes this computer's clipboard on the device.
class PasteClipboard extends InputAction {
  const PasteClipboard();
}

class PressButton extends InputAction {
  const PressButton(this.button);

  final DeviceButton button;
}

/// Opens the field for composed text.
class OpenTextField extends InputAction {
  const OpenTextField();
}

/// Saves a picture of the screen being shown.
class TakeScreenshot extends InputAction {
  const TakeScreenshot();
}

/// Taken, with nothing to send: the other half of a press that already
/// did its work.
class NoInput extends InputAction {
  const NoInput();
}
