# AGENTS.md — deebosh.hotkeys (Omarchy shell plugin)

Git-источник плагина `deebosh.hotkeys`. Корень репо = корень плагина (`manifest.json` лежит в корне — этого требует `omarchy plugin add <git-url>`).

## Структура

- `manifest.json` — id `deebosh.hotkeys`, kinds `["bar-widget"]`, entry `barWidget: BarWidget.qml`, `defaultSection: center`. В схеме только проверенные типы: `enum`, `integer` (других shell settings UI может не понять — сверяйся с `rem-aster.amnezia/manifest.json`).
- `BarWidget.qml` — иконка в баре (паттерн `omarchy.weather/BarWidget.qml`). Корень обязан иметь `open()/close()/opened` — иначе `shell summon/hide/toggle` не найдёт виджет (`Bar.findPanelWidget`).
- `Panel.qml` — попап (паттерн `panels/clock`, `panels/weather/Panel.qml`): `Panel + KeyboardPanel + PanelKeyCatcher`, `hostWidget/barIdentity`, `injectPanel`, `closeForPopoutSwitch`.
- `Model.js` — чистая логика без Qt (глифы, `normalizeAppId`, фильтр). Тест: `node -e "require('./Model.js')"...` (см. README). Глифы — только из покрытия `JetBrainsMono Nerd Font` (проверять через `fc-query --format='%{charset}' ... | grep`).
- `scripts/detect-app.sh` — уточнение активного приложения: класс окна + обход дерева процессов (tmux-клиент → `tmux list-clients/list-panes`, иначе BFS по `ps`). Тест: `scripts/detect-app.sh [pid]` (без args — фокусное окно).
- `shortcuts/<appId>.json` — данные `{appId, displayName, source, groups[]}`. Имя файла = appId (проверяет `node scripts/check-data.js`). Пустые `groups` — только честная заглушка + `note`.
- `Panel.qml` грузит лениво: два FileView (текущее приложение по `effectiveKey` + `globals`), никогда все файлы сразу.
- `bindings/` — пустой рудимент, в плагин не используется. Не удалять без спроса.

## Эталоны (читать перед правками QML)

- `/usr/share/omarchy/shell/plugins/panels/{clock,weather}/` — виджет+панель
- `/usr/share/omarchy/shell/plugins/bar/widgets/ActiveWindow.qml` — `ToplevelManager.activeToplevel`
- `/usr/share/omarchy/shell/Ui/{BarWidget,BarIconButton,Panel,KeyboardPanel,PanelKeyCatcher,WidgetButton,TextField}.qml`
- Контракт саммона: `shell.qml` `summon/hide/toggle` → `Bar.findPanelWidget` (только `open/close/opened`, без IpcHandler).

## Проверка и установка

```bash
./scripts/test.sh                                      # всё разом: данные + Model + validate + qmllint
node scripts/check-data.js                            # только схема данных
node scripts/test-model.js                            # только юнит Model.js
rm -rf ~/.config/omarchy/plugins/deebosh.hotkeys && cp -r . ~/.config/omarchy/plugins/deebosh.hotkeys && rm -rf ~/.config/omarchy/plugins/deebosh.hotkeys/.git
# (копия, НЕ симлинк: валидатор запрещает симлинки внутри плагина)
omarchy-shell shell rescanPlugins   # хот-релоад; либо правится сам при сохранении
omarchy plugin enable deebosh.hotkeys --section center
omarchy bar move deebosh.hotkeys --section center --index 2   # сразу после clock
```

- Логи шелла: `journalctl --user --since "1 min ago" -t omarchy-shell | grep -i hotkeys` (игнорировать чужие `IpcHandler ... will not be used`).
- Панель вручную: `omarchy-shell shell summon|toggle|hide deebosh.hotkeys` (возврата нет, `rc=0` = ок).
- Скриншот без интерактива: `grim /tmp/opencode/x.png` (`omarchy capture` висит в неинтерактивной сессии).
- Хоткей `SUPER+SHIFT+K` живёт в `~/.config/hypr/bindings.lua`, проверка: `hyprctl reload && hyprctl configerrors && omarchy menu keybindings --print | grep Hotkeys`.
- Внимание: `hyprctl dispatch <args>` в этой системе едет через lua-обёртку (`hl.dispatch`) и с обычными аргументами падает — для фокуса окон ищи обходной путь, не чини обёртку.

## После изменений

Синхронизировать installed-копию (см. выше), затем **restart shell** (не rescan!): `rescanPlugins` не пересоздаёт живые инстансы виджетов бара (Loader со старым source не перезагружается), структурные правки QML вступают только после `omarchy restart shell`. `diff -r . ~/.config/omarchy/plugins/deebosh.hotkeys` должен быть пуст.

## Грабли (проверено болью)

- `FileView.text` — это ФУНКЦИЯ: `onLoaded: ingest(text())`, не `text`. Иначе JSON.parse падает молча в try/catch и панель пустая без единой ошибки в логах.
- Пустая панель без ошибок = сначала проверь `text()` и перезапуск шелла, а не данные.
- Отладка живого виджета: временный `IpcHandler` в BarWidget (`target: deebosh.hotkeys.debug`, методы `status()`/`dbgOpen()`), запрос `omarchy-shell deebosh.hotkeys.debug status`. Удалить щуп перед коммитом! IPC отвечает первый зарегистрированный инстанс (может быть не фокусный монитор) — учитывай при трактовке.
- Скриншоты: панель открывается на фокусном мониторе (`hyprctl monitors -j` → focused, x/y/width), кропить `grim -g` по его геометрии; `omarchy capture` висит в неинтерактивной сессии.
