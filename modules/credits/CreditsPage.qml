import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH

// Everything not written for this project, grouped: code we forked or
// adapted, bundled sounds and fonts, and services and programs we call.
// Licences that ask for attribution (MIT notices, CC BY, OFL) are met by
// this page together with the LICENSE / attribution files in the repos.
Column {
  id: page
  property bool ru: true
  spacing: SH.HubStyle.gap

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Style.font.family
  function l10n(ruText, enText) { return ru ? ruText : enText }

  readonly property var groups: [
    { title: l10n("Код, взятый за основу", "Code we build on"), icon: "\u{f0169}", items: [
      { name: "Kronos", who: "MASH2RAFI", license: "MIT", url: "https://github.com/MASH2RAFI/omarchy-kronos",
        use: l10n("Часы на рабочем столе: отрисовка колец и цифр (форк, исправлена расстановка по мониторам)",
               "Desktop clock: the ring and digit rendering (a fork; per-monitor placement fixed)") },
      { name: "Quran Motivation", who: "Rayen Iben Romdhane (r4y-br)", license: "MIT", url: "https://github.com/r4y-br/omarchy-quran-motivation",
        use: l10n("Основа надписи «Цитата дня» на рабочем столе и её панели", "The base of the desktop quote overlay and its panel") },
      { name: "OmaFocus", who: "Shubham Giri (xshubhamg)", license: "MIT", url: "https://github.com/xshubhamg/omafocus",
        use: l10n("Движок фоновых звуков вкладки «Фокус»", "The ambient sound engine behind Focus") },
      { name: "Omanotch", who: "skuthus", license: "MIT", url: "https://github.com/skuthus/omanotch",
        use: l10n("Форма вогнутых уголков чёлки", "The concave corner shape of the notch") },
      { name: "Omarchy AI Usage", who: "Bappoz", license: "MIT", url: "https://github.com/Bappoz/omarchy-ai-usage",
        use: l10n("Идея «Агентов»: лимиты из официальных данных omarchy.agents, кольца лимитов, честно — только там, где лимиты известны",
                  "The idea behind Agents: limits from omarchy.agents' official data, limit rings, an honest list of what reports limits") },
      { name: "Whimsy", who: "Rover (rover-001)", license: "MIT", url: "https://github.com/rover-001/whimsy",
        use: l10n("Идеи (код не взят): «Система», «Погода», визуализатор на рабочем столе, стили часов, кассета, поворот и замок виджетов",
                  "Ideas (no code taken): System, Weather, the desktop visualizer, clock styles, the cassette, rotating and locking widgets") },
      { name: "OmaRecorder", who: "Corey Tyhurst (huey-holdings-llc)", license: "MIT", url: "https://github.com/huey-holdings-llc/omarecorder",
        use: l10n("Идея «Диктофона» (код не взят): запись голоса и созвонов, библиотека записей, расшифровка через voxtype на этом компьютере",
                  "The idea behind Recorder (no code taken): voice and call recording, a library, transcription with voxtype on this machine") },
      { name: "Control Center", who: "404Prabhat", license: "MIT", url: "https://github.com/404Prabhat/omarchy-control-center",
        use: l10n("Идея быстрых переключателей на «Главной» (код не взят)", "The idea of Home's quick toggles (no code taken)") },
      { name: "caelestia shell", who: "caelestia-dots", license: "GPL-3.0", url: "https://github.com/caelestia-dots/shell",
        use: l10n("Компоновка чёлки: вкладки с иконкой над подписью, «Главная» (погода, профиль, дата, календарь, ресурсы, плеер), большие кольца «Системы», «Центр». Только идеи — код GPL не используется",
                  "The notch's layout: icon-over-label tabs, Home (weather, profile, date, calendar, resources, player), System's big rings, Centre. Ideas only — no GPL code is used") },
      { name: "Display Settings (omarchy-display)", who: "Amin Marashi", license: "MIT", url: "https://plugins.omarchy.org",
        use: l10n("«Дисплеи» вызывают его программу display-settings: разрешение, частота, масштаб, расположение, яркость DDC",
                  "Displays calls its display-settings program: resolution, refresh rate, scale, arrangement, DDC brightness") },
      { name: "Network+", who: "das6ng", license: l10n("см. репозиторий", "see repository"), url: "https://github.com/das6ng/omarchy-network-plus",
        use: l10n("Идея раздела «Сеть»: список Wi-Fi, адреса, DNS, скорость, задержка (код не взят)", "The idea of Network: Wi-Fi list, addresses, DNS, throughput, latency (no code taken)") },
      { name: "Visual Keybindings, Shortkeyz", who: "dai199, schmunk42", license: "MIT", url: "https://github.com/dai199/omarchy-visual-keybindings",
        use: l10n("Идея списка горячих клавиш в «Вводе» (код не взят)", "The idea of the key bindings list in Input (no code taken)") },
      { name: "Omagic, Omalogimouse, Sony Headphones", who: "betnbd, Ormus Solutions, gabamnml", license: "MIT, MIT, AGPL-3.0", url: "https://github.com/betnbd/Omagic",
        use: l10n("Идея «Устройств» и виджета «Батареи»: заряд мышей, клавиатур и наушников (код не взят)", "The idea of Devices and the Batteries widget: mouse, keyboard and headphone charge (no code taken)") },
      { name: "Serpantinum", who: "ilyamiro", license: "AGPL-3.0", url: "https://github.com/ilyamiro/serpantinum",
        use: l10n("Виды погоды «Полный», «Круглый», «Плитка» и цвет по погоде. Только внешний вид — код AGPL не используется",
                  "The Full, Round and Tile weather looks and the weather tint. The look only — no AGPL code is used") },
      { name: "Speaker Calibrator", who: "Michael de By (thefreshoffice)", license: "MIT", url: "https://github.com/thefreshoffice/omarchy-speaker-calibrator",
        use: l10n("Подход к обработке звука через фильтры PipeWire и LSP-плагины — для «Микрофона» (код не взят)",
                  "The PipeWire filter-chain + LSP plugins approach, used for Microphone (no code taken)") },
      { name: "Daily Verse", who: "maurice (nautilusmare)", license: "MIT", url: "https://github.com/nautilusmare/omarchy-daily-verse",
        use: l10n("Источник «Библия» в «Цитатах»: список стихов и толкования через bible.helloao.org",
                  "The Bible source in Quotes: the verse list and commentary via bible.helloao.org") }
    ]},
    { title: l10n("Звуки и шрифты", "Sounds and fonts"), icon: "\u{f0387}", items: [
      { name: "Blanket — " + l10n("звуки", "sounds"), who: "Rafael Mardojai CM " + l10n("и авторы звуков", "and the sound authors"),
        license: "CC0 / CC BY / CC BY-SA / Public Domain", url: "https://github.com/rafaelmardojai/blanket",
        use: l10n("14 звуков «Фокуса». Авторы по каждому: kvgarlic, Falcet, gezortenplotz, stephan, ezwa, Omegatron, alex36917, Lisa Redfern, Digifish music, gluckose, SDLx, Luftrum, Jorge Stolfi, felix.blume (правки — Porrumentzio). Полный список с лицензиями и ссылками — focus/SOUNDS_ATTRIBUTION.md в SoundHub.",
               "The 14 Focus sounds. Per-track authors: kvgarlic, Falcet, gezortenplotz, stephan, ezwa, Omegatron, alex36917, Lisa Redfern, Digifish music, gluckose, SDLx, Luftrum, Jorge Stolfi, felix.blume (edits by Porrumentzio). Full list with licences and links: focus/SOUNDS_ATTRIBUTION.md in SoundHub.") },
      { name: "UnifrakturMaguntia", who: "j. 'mach' wust, Peter Wiegel", license: "SIL OFL 1.1", url: "https://github.com/google/fonts/tree/main/ofl/unifrakturmaguntia",
        use: l10n("Готический шрифт цитат", "The blackletter font of the quotes") },
      { name: "Noto Serif, Noto Serif CJK", who: "Google", license: "SIL OFL 1.1", url: "https://fonts.google.com/noto",
        use: l10n("Перевод цитат и цитаты на японском, китайском, корейском (шрифты системы)", "Quote translations and Japanese/Chinese/Korean quotes (system fonts)") }
    ]},
    { title: l10n("Сервисы и программы", "Services and programs"), icon: "\u{f059f}", items: [
      { name: "ZenQuotes", who: "zenquotes.io", license: l10n("условия сервиса", "terms of service"), url: "https://zenquotes.io",
        use: l10n("Цитаты дня и случайные цитаты (Inspirational quotes provided by ZenQuotes API)", "Quote of the day and random quotes (Inspirational quotes provided by ZenQuotes API)") },
      { name: "Free Use Bible API", who: "bible.helloao.org (AO Lab)", license: l10n("свободное использование", "free use"), url: "https://bible.helloao.org",
        use: l10n("Тексты стихов (Berean Standard Bible и Синодальный перевод — общественное достояние) и толкования Мэтью Генри",
                  "Verse texts (Berean Standard Bible and the Russian Synodal — public domain) and Matthew Henry's commentary") },
      { name: "voxtype, whisper.cpp", who: l10n("их авторы", "their authors"), license: "MIT", url: "https://voxtype.io",
        use: l10n("Расшифровка записей «Диктофона» (вызываются как программы)", "Transcribing Recorder's recordings (run as programs)") },
      { name: "LSP Plugins", who: "Vladimir Sadovnikov", license: "LGPL-3.0", url: "https://lsp-plug.in",
        use: l10n("Гейт, компрессор и лимитер «Микрофона» (системный пакет)", "Microphone's gate, compressor and limiter (system package)") },
      { name: "WebRTC Audio Processing, DeepFilterNet", who: l10n("Google и проект WebRTC; Hendrik Schröter", "Google and the WebRTC project; Hendrik Schröter"),
        license: "BSD-3-Clause; MIT / Apache-2.0", url: "https://github.com/Rikorose/DeepFilterNet",
        use: l10n("Шумоподавление «Микрофона»: встроенное в PipeWire и ИИ-плагин (ставится по желанию)", "Microphone's noise suppression: PipeWire's built-in and the optional AI plugin") },
      { name: "libmdr (SonyHeadphonesClient), mdrctl/mdrctld", who: "mos9527; delarosa1312", license: "MIT", url: "https://github.com/mos9527/SonyHeadphonesClient",
        use: l10n("«Наушники»: протокол Sony MDR v2 и демон сессии; собираются для пользователя скриптом install-sony", "Headphones: the Sony MDR v2 protocol and the session daemon; built for the user by install-sony") },
      { name: "UxPlay", who: "F. Duncanh (FDH2) и авторы RPiPlay", license: "GPL-3.0", url: "https://github.com/FDH2/UxPlay",
        use: l10n("«Телефон»: приёмник AirPlay для экрана iPhone (отдельная программа, собирается скриптом install-uxplay)", "Phone: the AirPlay receiver for an iPhone's screen (a separate program, built by install-uxplay)") },
      { name: "Solaar", who: l10n("авторы Solaar", "the Solaar authors"), license: "GPL-2.0", url: "https://github.com/pwr-Solaar/Solaar",
        use: l10n("«Мышь Logitech»: DPI, SmartShift, колёса, заряд (системная программа)", "Logitech mouse: DPI, SmartShift, wheels, battery (system program)") },
      { name: "Open-Meteo", who: "open-meteo.com", license: "CC BY 4.0", url: "https://open-meteo.com",
        use: l10n("Погода и поиск городов (Weather data by Open-Meteo.com)", "Weather and city search (Weather data by Open-Meteo.com)") },
      { name: "DummyJSON", who: "dummyjson.com", license: "MIT", url: "https://dummyjson.com",
        use: l10n("Случайные цитаты", "Random quotes") },
      { name: "MyMemory, Google Translate", who: "Translated srl, Google", license: l10n("условия сервисов", "terms of service"), url: "https://mymemory.translated.net",
        use: l10n("Машинный перевод цитат с сайтов", "Machine translation of fetched quotes") },
      { name: "LRCLIB", who: "lrclib.net", license: l10n("открытая база", "open database"), url: "https://lrclib.net",
        use: l10n("Тексты песен", "Song lyrics") },
      { name: "cava", who: "Karl Stavestrand", license: "MIT", url: "https://github.com/karlstav/cava",
        use: l10n("Спектр звука", "The audio spectrum") },
      { name: "yt-dlp, FFmpeg", who: l10n("сообщества yt-dlp и FFmpeg", "the yt-dlp and FFmpeg projects"), license: "Unlicense, LGPL/GPL", url: "https://github.com/yt-dlp/yt-dlp",
        use: l10n("Загрузки (вызываются как программы, не встроены)", "Downloads (run as programs, not bundled)") },
      { name: "mpv, PipeWire, Quickshell", who: l10n("их авторы", "their authors"), license: "GPL/LGPL, MIT, LGPL-3.0", url: "https://quickshell.org",
        use: l10n("Звуки «Фокуса», звук и эквалайзер, сама оболочка (системные программы)", "Focus playback, audio and EQ, the shell itself (system programs)") }
    ]}
  ]

  Text {
    width: parent.width
    wrapMode: Text.Wrap
    leftPadding: Style.space(4)
    text: page.l10n("Всё, что сделано не нами: чей код, звуки, шрифты и сервисы используются, под какой лицензией и где взяты. Остальное в TheNotch, SoundHub и других модулях — наше (MIT).",
                 "Everything we didn't write: whose code, sounds, fonts and services are used, under which licence and where from. The rest of TheNotch, SoundHub and the other modules is ours (MIT).")
    color: Qt.darker(page.fg, 1.5)
    font.family: page.ff; font.pixelSize: Style.font.caption
  }

  Repeater {
    model: page.groups
    delegate: Column {
      id: grp
      required property var modelData
      width: page.width
      spacing: Style.space(6)
      SH.HubCaption { text: grp.modelData.title; icon: grp.modelData.icon; fg: page.fg; fontFamily: page.ff }
      Repeater {
        model: grp.modelData.items
        delegate: SH.HubCard {
          id: card
          required property var modelData
          width: grp.width
          height: info.implicitHeight + SH.HubStyle.pad * 2
          fg: page.fg; accent: page.accent
          hoverable: true
          Column {
            id: info
            x: SH.HubStyle.pad; y: SH.HubStyle.pad
            width: parent.width - SH.HubStyle.pad * 2 - link.width - Style.space(8)
            spacing: Style.space(3)
            Row {
              spacing: Style.space(8)
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: card.modelData.name
                color: page.fg
                font.family: page.ff; font.pixelSize: Style.font.body; font.bold: true
              }
              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: lic.implicitWidth + Style.space(12); height: lic.implicitHeight + Style.space(4)
                radius: height / 2
                color: SH.HubStyle.tint(page.accent, 0.16)
                Text { id: lic; anchors.centerIn: parent; text: card.modelData.license; color: page.accent; font.family: page.ff; font.pixelSize: Style.font.caption - 1 }
              }
            }
            Text {
              width: parent.width
              text: card.modelData.who
              color: Qt.darker(page.fg, 1.6)
              font.family: page.ff; font.pixelSize: Style.font.caption - 1
              elide: Text.ElideRight
            }
            Text {
              width: parent.width
              text: card.modelData.use
              color: Qt.darker(page.fg, 1.25)
              wrapMode: Text.Wrap
              font.family: page.ff; font.pixelSize: Style.font.caption
            }
          }
          SH.HubChip {
            id: link
            anchors.right: parent.right; anchors.rightMargin: SH.HubStyle.pad
            anchors.top: parent.top; anchors.topMargin: SH.HubStyle.pad
            iconOnly: true
            icon: "\u{f03cc}"
            label: card.modelData.url
            h: Style.space(26)
            fg: page.fg; accent: page.accent; fontFamily: page.ff
            onClicked: Qt.openUrlExternally(card.modelData.url)
          }
        }
      }
    }
  }
}
