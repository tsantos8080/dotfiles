/* Claude Code sessions on the top bar, for GNOME 42.
 * The Claude Code hooks (~/.claude/hooks/tmux-status.sh) end the tmux window
 * name with ◌ while Claude works and ? while it waits for an answer. This reads
 * those marks every few seconds, so a waiting session shows up even when the
 * terminal is not in front. Hidden when no window has a mark. */

const { Gio, GLib, Shell, St, Clutter } = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;

const POLL_SECONDS = 2;
const WORKING = '◌';
const WAITING = '?';
const WAITING_COLOR = '#c4b28a'; // Kanagawa Dragon, same accent as tmux
// Nerd Font icons (JetBrains Mono Nerd Font): robot while working, question mark while waiting.
const WORKING_ICON = '\u{f06a9}';
const WAITING_ICON = '\uf128';

function run(argv) {
    return new Promise(resolve => {
        try {
            const proc = Gio.Subprocess.new(argv,
                Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_SILENCE);
            proc.communicate_utf8_async(null, null, (p, result) => {
                try {
                    const [, stdout] = p.communicate_utf8_finish(result);
                    resolve(p.get_successful() ? stdout : '');
                } catch (e) {
                    resolve('');
                }
            });
        } catch (e) {
            resolve(''); // tmux not running
        }
    });
}

function focusKitty() {
    const app = Shell.AppSystem.get_default().lookup_app('kitty.desktop');
    const window = app ? app.get_windows()[0] : null;
    if (window)
        Main.activateWindow(window);
    else if (app)
        app.activate();
}

class ClaudeStatus {
    enable() {
        this._button = new PanelMenu.Button(0.0, 'Claude Status', false);
        this._label = new St.Label({ y_align: Clutter.ActorAlign.CENTER, style: "font-family: 'JetBrainsMono Nerd Font';" });
        this._button.add_child(this._label);
        this._button.visible = false;
        // First item on the right side of the top bar; pr-review places itself
        // right after it.
        Main.panel.addToStatusArea('claude-status', this._button, 0, 'right');

        this._last = null;
        this._busy = false;
        this._refresh();
        this._timer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, POLL_SECONDS, () => {
            this._refresh();
            return GLib.SOURCE_CONTINUE;
        });
    }

    disable() {
        GLib.source_remove(this._timer);
        this._timer = null;
        this._button.destroy();
        this._button = null;
        this._label = null;
    }

    async _refresh() {
        if (this._busy)
            return;
        this._busy = true;
        const out = await run(['tmux', 'list-windows', '-a', '-F', '#{window_id}\t#{window_name}']);
        this._busy = false;
        if (!this._button || out === this._last)
            return;
        this._last = out;

        const windows = out.split('\n').filter(Boolean).map(line => {
            const [id, name] = line.split('\t');
            return { id, name };
        });
        const waiting = windows.filter(w => w.name.endsWith(` ${WAITING}`));
        const working = windows.filter(w => w.name.endsWith(` ${WORKING}`));

        this._button.visible = waiting.length + working.length > 0;
        const parts = [];
        if (waiting.length)
            parts.push(`<span foreground="${WAITING_COLOR}">${WAITING_ICON} ${waiting.length}</span>`);
        if (working.length)
            parts.push(`${WORKING_ICON} ${working.length}`);
        this._label.clutter_text.set_markup(parts.join('  '));

        this._button.menu.removeAll();
        for (const w of [...waiting, ...working]) {
            const state = w.name.endsWith(` ${WAITING}`) ? 'waiting for you' : 'working';
            const name = GLib.markup_escape_text(w.name.slice(0, -2), -1);
            const item = new PopupMenu.PopupMenuItem(`${name}  ·  ${state}`);
            item.connect('activate', async () => {
                await run(['tmux', 'select-window', '-t', w.id]);
                focusKitty();
            });
            this._button.menu.addMenuItem(item);
        }
    }
}

function init() {
    return new ClaudeStatus();
}
