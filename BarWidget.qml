import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Bar icon for deebosh.hotkeys: shows a per-application glyph for the
// currently focused window, and hosts the hotkeys popup.
//
// Shape contract for shell.summon/hide/toggle routing (Bar.findPanelWidget
// requires open/close/opened on the bar-widget root).
BarWidget {
  id: root
  moduleName: "deebosh.hotkeys"

  // Active application, tracked live. Panel.qml tracks the same source so
  // an open panel follows focus changes without extra wiring.
  readonly property var toplevel: ToplevelManager.activeToplevel
  readonly property string rawAppId: toplevel ? String(toplevel.appId || "") : ""
  readonly property string appKey: Model.normalizeAppId(rawAppId)

  // Inner-app detection (tmux / nvim / lazygit inside foot): the Wayland
  // app-id only says "foot", so scripts/detect-app.sh walks the client's
  // process tree (plus tmux pane commands) to refine it.
  readonly property string pluginDir: {
    var url = String(Qt.resolvedUrl("."))
    if (url.indexOf("file://") === 0) url = url.substring(7)
    url = decodeURIComponent(url).replace(/\/+$/, "")
    if (url === "") url = Quickshell.env("HOME") + "/.config/omarchy/plugins/deebosh.hotkeys"
    return url
  }
  property string detectedKey: ""
  readonly property string effectiveKey: detectedKey !== "" ? detectedKey : appKey
  readonly property string localeName: Qt.locale().name
  readonly property string appName: Model.displayNameForKey(effectiveKey, localeName)
  readonly property string appGlyph: Model.glyphFor(effectiveKey)

  function runDetect() {
    if (!detectProc.running) detectProc.running = true
  }

  onRawAppIdChanged: runDetect()
  Component.onCompleted: runDetect()

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.runDetect()
  }

  Process {
    id: detectProc
    running: false
    command: ["sh", root.pluginDir + "/scripts/detect-app.sh"]
    stdout: StdioCollector {
      onStreamFinished: {
        var k = String(text || "").replace(/^\s+|\s+$/g, "")
        root.detectedKey = (k !== "" && Model.GLYPHS[k] !== undefined) ? k : ""
      }
    }
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.openFromHotkey) panelLoader.item.openFromHotkey()
    else if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  // Forwarded so this widget can stand in for the panel as the bar's popout
  // identity: Bar.requestPopout prefers closeForPopoutSwitch over close, and
  // KeyboardPanel reads popoutSwitchClosing back off its owner.
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.appGlyph
    slotSize: Style.bar.statusSlot
    tooltipText: root.appName + " · " + Model.tr("tooltipSuffix", root.localeName)

    onPressed: function(b) {
      root.togglePanel()
    }
  }
}
