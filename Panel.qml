import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// Popup panel for deebosh.hotkeys: hotkeys of the currently focused app.
//
// Data comes from shortcuts/*.json (one file per app, official sources).
// The panel tracks ToplevelManager.activeToplevel itself, so an open panel
// follows focus changes — BarWidget.qml only anchors and owns bar identity.
Panel {
  id: root
  moduleName: "deebosh.hotkeys"
  ipcTarget: "deebosh.hotkeys"
  manageIpc: false

  property var anchorItem: null

  // The bar tracks the widget mounted in its slot — BarWidget.qml — not this
  // nested panel (same contract as omarchy.clock / omarchy.weather).
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  // ---- Active application (same source as the bar widget).
  readonly property var toplevel: ToplevelManager.activeToplevel
  readonly property string rawAppId: toplevel ? String(toplevel.appId || "") : ""
  readonly property string appKey: Model.normalizeAppId(rawAppId)
  // Inner-app refinement from the host widget (tmux/nvim/lazygit inside
  // foot); falls back to the plain app-id mapping when unreported.
  readonly property string detectedKey: (hostWidget && hostWidget.detectedKey !== undefined) ? String(hostWidget.detectedKey) : ""
  readonly property string effectiveKey: (detectedKey !== "" && Model.GLYPHS[detectedKey] !== undefined) ? detectedKey : appKey
  // UI language follows the system locale (Russian for ru_*, English otherwise).
  readonly property string localeName: Qt.locale().name
  readonly property string appName: Model.dataDisplayName(appData, effectiveKey, localeName)
  readonly property string appGlyph: Model.glyphFor(effectiveKey)

  // ---- Settings (schema in manifest.json).
  readonly property bool showGlobals: setting("showGlobals", "Off") === "On"
  readonly property bool compact: setting("compact", "On") === "On"
  readonly property int maxItems: Math.max(0, Math.round(Number(setting("maxItems", 0)) || 0))

  // ---- Search.
  property string query: ""

  // ---- Shortcut data: key -> { displayName, source, groups }.
  // Loaded lazily: only the current app + globals, never all 100 files.
  property var dataMap: ({})

  function filePath(name) {
    var url = String(Qt.resolvedUrl("shortcuts/" + name + ".json"))
    if (url.indexOf("file://") === 0) url = url.substring(7)
    return decodeURIComponent(url)
  }

  function ingest(raw) {
    var parsed = null
    try { parsed = JSON.parse(String(raw || "")) } catch (e) { return }
    if (!parsed || !parsed.appId || !Array.isArray(parsed.groups)) return
    var next = {}
    for (var k in root.dataMap) next[k] = root.dataMap[k]
    next[parsed.appId] = parsed
    root.dataMap = next
  }

  readonly property var appData: dataMap[effectiveKey] || null
  readonly property var globalsData: dataMap[Model.FALLBACK_APP] || null

  // Groups to render: current app (+ globals when enabled and not already
  // shown). Search filters the current view only.
  readonly property var visibleGroups: {
    var groups = (appData && appData.groups) ? appData.groups : []
    if (showGlobals && effectiveKey !== Model.FALLBACK_APP && globalsData && globalsData.groups)
      groups = groups.concat(globalsData.groups)
    var filtered = Model.filterItems(groups, query)
    return Model.limitGroups(filtered, maxItems)
  }
  readonly property int totalShown: Model.countItems(visibleGroups)
  readonly property bool unknownApp: effectiveKey === Model.FALLBACK_APP && rawAppId !== ""

  readonly property color contentForeground: bar ? bar.foreground : Commons.Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  function open() {
    root.query = ""
    if (searchField) searchField.text = ""
    root.controller.show()
    Qt.callLater(function() { if (searchField) searchField.forceActiveFocus() })
  }

  function openFromHotkey() {
    root.open()
    Qt.callLater(function() {
      if (root.opened) setCenterHoverRevealSuppressed(true)
    })
  }

  function close() {
    setCenterHoverRevealSuppressed(false)
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.openFromHotkey()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && typeof root.bar.setCenterHoverRevealSuppressed === "function")
      root.bar.setCenterHoverRevealSuppressed(value)
    else if (root.bar && "centerHoverRevealSuppressed" in root.bar)
      root.bar.centerHoverRevealSuppressed = value
  }

  // Current app file follows focus; globals loads once and stays cached.
  // Missing app file (no data yet) simply yields no app groups.
  FileView {
    id: appFile
    path: root.filePath(root.effectiveKey)
    watchChanges: true
    printErrors: false
    onLoaded: root.ingest(text())
    onFileChanged: reload()
    onLoadFailed: {}
  }

  FileView {
    id: globalsFile
    path: root.filePath("globals")
    watchChanges: true
    printErrors: false
    onLoaded: root.ingest(text())
    onFileChanged: reload()
    onLoadFailed: {}
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(600))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      // While the search field is focused, keys belong to it (caret,
      // backspace); the field handles Esc/Tab itself.
      blocked: searchField.activeFocus
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        anchors.fill: parent
        contentWidth: contentColumn.width
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height || contentWidth > width

        Column {
          id: contentColumn
          // Fixed width (no parent.width reference): the Flickable's
          // contentWidth binds to this column, so reading back would loop.
          width: Style.space(560)
          spacing: root.compact ? Style.space(4) : Style.space(8)

          // ---- Hero: glyph + app name.
          Row {
            width: parent.width
            spacing: Style.space(14)

            Text {
              textFormat: Text.PlainText
              anchors.verticalCenter: parent.verticalCenter
              text: root.appGlyph
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: 40
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - 54
              spacing: Style.space(2)

              Text {
                textFormat: Text.PlainText
                width: parent.width
                text: root.appName
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: 24
                font.bold: true
                elide: Text.ElideRight
              }

              Text {
                textFormat: Text.PlainText
                width: parent.width
                text: root.unknownApp
                  ? Model.tr("unknownAppNote", root.localeName).replace("{app}", root.rawAppId)
                  : root.totalShown + " " + Model.tr("shortcutsCount", root.localeName)
                color: Qt.darker(root.contentForeground, 1.5)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }
            }
          }

          // ---- Search.
          TextField {
            id: searchField
            width: parent.width
            placeholderText: Model.tr("searchPlaceholder", root.localeName)
            foreground: root.contentForeground
            font.family: root.contentFontFamily
            verticalPadding: Style.space(6)

            onTextChanged: root.query = text

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                root.close()
                event.accepted = true
              } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                root.switchPanel((event.modifiers & Qt.ShiftModifier) || event.key === Qt.Key_Backtab ? -1 : 1)
                event.accepted = true
              }
            }
          }

          // ---- Groups.
          Repeater {
            model: root.visibleGroups

            Column {
              required property var modelData
              width: contentColumn.width
              spacing: root.compact ? Style.space(2) : Style.space(4)
              visible: (modelData.items || []).length > 0

              PanelSectionHeader {
                width: parent.width
                visible: !root.compact
                text: Model.groupTitle(modelData, root.localeName)
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
              }

              Repeater {
                model: modelData.items

                Row {
                  required property var modelData
                  width: parent.width
                  spacing: Style.space(12)

                  Text {
                    textFormat: Text.PlainText
                    width: Math.round(parent.width * 0.38)
                    text: (modelData.keys || []).join("  ·  ")
                    color: Style.selectedStateColor(root.contentForeground, Commons.Color.accent)
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                    wrapMode: Text.Wrap
                  }

                  Text {
                    textFormat: Text.PlainText
                    width: parent.width - x - parent.spacing
                    text: Model.itemAction(modelData, root.localeName)
                    color: root.contentForeground
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.body
                    wrapMode: Text.WordWrap
                  }
                }
              }
            }
          }

          Text {
            visible: root.totalShown === 0
            textFormat: Text.PlainText
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.query !== "" ? Model.tr("nothingFound", root.localeName) : (root.appData ? Model.tr("noEntries", root.localeName) : Model.tr("noData", root.localeName))
            color: Qt.darker(root.contentForeground, 1.5)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.body
          }
        }
      }
    }
  }
}
