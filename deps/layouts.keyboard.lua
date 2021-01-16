local _, addon = ...
local colSet, colAdd, rowSet, rowAdd, _, buttonRow = select(14, unpack(addon))

addon.DEFAULT_KEYBOARD_LAYOUT = {
  colSet, 1,              buttonRow, colAdd, 1, "F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12 PRINT PAUSE DEL",
  colSet, 0,   rowAdd, 1, buttonRow, colAdd, 1, "` 1 2 3 4 5 6 7 8 9 0 - =",
  colSet, 1.3, rowAdd, 1, buttonRow, colAdd, 1, "q w e r t y u i o p [ ]",
  colSet, 1.6, rowAdd, 1, buttonRow, colAdd, 1, "a s d f g h j k l ; ' \\",
  colSet, 1,   rowAdd, 1, buttonRow, colAdd, 1, "\\ z x c v b n m , . /",
  rowAdd, 1
}
