import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// About: this computer — its name, Omarchy and kernel versions, processor,
// graphics, memory, disks — with a copy button. The credits sit next to it.
NotchModule {
  id: ab
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Этот компьютер", "This computer")
  icon: "\u{f0aab}"
  description: t("Сведения о системе", "System information")
  inRail: false
  core: true
  settingsSection: "about"
  sectionOrder: 1
  settingsPage: Component { AboutPage { mod: ab } }
  property var info: ({})
  Process {
    id: proc
    command: ["bash", "-c",
      "printf 'host=%s\\n' \"$(hostnamectl hostname 2>/dev/null || hostname)\"; " +
      "printf 'os=%s\\n' \"$(. /etc/os-release; echo \"$PRETTY_NAME\")\"; " +
      "printf 'omarchy=%s\\n' \"$(omarchy version 2>/dev/null | head -1)\"; " +
      "printf 'kernel=%s\\n' \"$(uname -r)\"; " +
      "printf 'hyprland=%s\\n' \"$(hyprctl version -j 2>/dev/null | jq -r .tag)\"; " +
      "printf 'cpu=%s\\n' \"$(lscpu | sed -n 's/^Model name:\\s*//p' | head -1) · $(nproc) потоков\"; " +
      "printf 'gpu=%s\\n' \"$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || lspci | grep -i vga | sed 's/.*: //' | head -1)\"; " +
      "printf 'ram=%s\\n' \"$(awk '/MemTotal/ {printf \"%.0f ГБ\", $2/1048576}' /proc/meminfo)\"; " +
      "printf 'disk=%s\\n' \"$(df -h --output=size,used / | tail -1 | awk '{print $2\" из \"$1}')\"; " +
      "printf 'board=%s\\n' \"$(cat /sys/class/dmi/id/board_vendor /sys/class/dmi/id/board_name 2>/dev/null | tr '\\n' ' ')\""]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var o = {}, l = text.split("\n")
        for (var i = 0; i < l.length; i++) { var k = l[i].indexOf("="); if (k > 0) o[l[i].slice(0, k)] = l[i].slice(k + 1).trim() }
        ab.info = o
      }
    }
  }
  function load() { if (!proc.running) proc.running = true }
}
