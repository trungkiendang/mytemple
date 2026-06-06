import 'dart:js_interop';
import 'dart:js_interop_unsafe';

typedef BellTapCallback = void Function();

void setupBellTap(BellTapCallback callback) {
  globalContext['_onBellTap'] = callback.toJS;
}

void teardownBellTap() {
  globalContext['_onBellTap'] = null;
}
