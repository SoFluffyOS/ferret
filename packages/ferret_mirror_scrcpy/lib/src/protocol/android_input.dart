/// The numbers Android's input events use (`KeyEvent`, `MotionEvent`).
abstract final class AndroidKeyAction {
  static const int down = 0;
  static const int up = 1;
}

abstract final class AndroidMotionAction {
  static const int down = 0;
  static const int up = 1;
  static const int move = 2;
  static const int cancel = 3;
  static const int hoverMove = 7;
}

abstract final class AndroidMetaState {
  static const int shift = 0x1;
  static const int alt = 0x2;
  static const int control = 0x1000;
  static const int meta = 0x10000;
}

abstract final class AndroidKeycode {
  static const int home = 3;
  static const int back = 4;
  static const int volumeUp = 24;
  static const int volumeDown = 25;
  static const int power = 26;
  static const int appSwitch = 187;
}
