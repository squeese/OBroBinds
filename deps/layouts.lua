local scope = select(2, ...)
local LAYOUT, poolAcquire = scope.LAYOUT, scope.poolAcquire

scope.DEFAULT_KEYBOARD_LAYOUT = poolAcquire(LAYOUT,
  LAYOUT.keys, 1, 0, "F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12", LAYOUT.col, 0,    LAYOUT.row, 1,
  LAYOUT.keys, 1, 0, "1 2 3 4 5 6 7 8 9 0 - =",                LAYOUT.col, 0.3,  LAYOUT.row, 2,
  LAYOUT.keys, 1, 0, "q w e r t y u i o p [ ]",                LAYOUT.col, 0.6,  LAYOUT.row, 3,
  LAYOUT.keys, 1, 0, "a s d f g h j k l ; '",                  LAYOUT.col, 0,    LAYOUT.row, 4,
  LAYOUT.keys, 1, 0, "\\ z x c v b n m , . /",                 LAYOUT.col, 12.5, LAYOUT.row, 0,
  LAYOUT.keys, 0, 1, "MOUSEWHEELUP BUTTON3 MOUSEWHEELDOWN")()
