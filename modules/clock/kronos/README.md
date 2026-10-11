# Kronos (fork)

Rendering files of [MASH2RAFI/omarchy-kronos](https://github.com/MASH2RAFI/omarchy-kronos)
(MIT, see LICENSE), at upstream commit 21643569798791a7537072b3845ce3af1ae9b55b.

Changes in this fork:
- ClockFace.qml: the ring timer updates inline, so a shell reload no longer
  logs "refreshTime is not a function".
- The windows, placement and settings are TheNotch's own (../Module.qml):
  one placement timer per screen (upstream shared one, so every monitor but
  the last kept the clock at the top-left corner), click-through windows,
  settings under Settings → Widgets.
