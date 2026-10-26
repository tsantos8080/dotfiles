/* Pull requests waiting for my review, on the top bar, for GNOME 42.
 * user-review-requested only counts requests made to me by name; team
 * requests (review-requested) would add many PRs that someone else on the
 * team will take. Hidden when there is nothing to review. */

const { Gio, GLib, Shell, St, Clutter } = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;

const POLL_SECONDS = 10 * 60;
const QUERY = 'is:pr is:open archived:false user-review-requested:@me';
const MAX_TITLE = 70;
const PR_ICON = '\uf407'; // Nerd Font git-pull-request (JetBrains Mono Nerd Font)
// gh and gh-dash come from mise, whose shims are not in GNOME Shell's PATH.
const SHIMS = `${GLib.get_home_dir()}/.local/share/mise/shims`;

function run(argv) {
    return new Promise(resolve => {
        try {
            const proc = Gio.Subprocess.new(argv,
                Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_SILENCE);
            proc.communicate_utf8_async(null, null, (p, result) => {
                try {
                    const [, stdout] = p.communicate_utf8_finish(result);
                    resolve(p.get_successful() ? stdout : null);
                } catch (e) {
                    resolve(null);
                }
            });
        } catch (e) {
            resolve(null);
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

class PrReview {
    enable() {
        this._button = new PanelMenu.Button(0.0, 'PR Review', false);
        this._label = new St.Label({ y_align: Clutter.ActorAlign.CENTER, style: "font-family: 'JetBrainsMono Nerd Font';" });
        this._button.add_child(this._label);
        this._button.visible = false;
        Main.panel.addToStatusArea('pr-review', this._button, 0, 'right');
        // Keep it right after the Claude Status indicator. Tray icons (e.g. the
        // ADP app) are added later and can land between the two, so move it
        // again whenever something is added to the right side of the panel.
        this._placeNextToClaude();
        this._rightBoxSignal = Main.panel._rightBox.connect('actor-added', () => this._placeNextToClaude());

        this._refresh();
        this._timer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, POLL_SECONDS, () => {
            this._refresh();
            return GLib.SOURCE_CONTINUE;
        });
    }

    _placeNextToClaude() {
        const claude = Main.panel.statusArea['claude-status'];
        const box = Main.panel._rightBox;
        const mine = this._button.container;
        if (!claude || claude.container.get_parent() !== box || mine.get_parent() !== box)
            return;
        const children = box.get_children();
        if (children.indexOf(mine) !== children.indexOf(claude.container) + 1)
            box.set_child_above_sibling(mine, claude.container);
    }

    disable() {
        Main.panel._rightBox.disconnect(this._rightBoxSignal);
        this._rightBoxSignal = null;
        GLib.source_remove(this._timer);
        this._timer = null;
        this._button.destroy();
        this._button = null;
        this._label = null;
    }

    async _refresh() {
        const out = await run([`${SHIMS}/gh`, 'api', '-X', 'GET', 'search/issues',
            '-f', `q=${QUERY}`, '-f', 'per_page=30',
            '--jq', '.items[] | [.html_url, (.repository_url | split("/") | .[-1]), (.number | tostring), .title] | join("\\t")']);
        // Keep the last state when gh fails (offline, token expired).
        if (!this._button || out === null)
            return;

        const prs = out.split('\n').filter(Boolean).map(line => {
            const [url, repo, number, title] = line.split('\t');
            return { url, repo, number, title };
        });

        this._button.visible = prs.length > 0;
        this._label.text = `${PR_ICON} ${prs.length}`;

        const menu = this._button.menu;
        menu.removeAll();
        for (const pr of prs) {
            const title = pr.title.length > MAX_TITLE ? `${pr.title.slice(0, MAX_TITLE - 1)}…` : pr.title;
            const item = new PopupMenu.PopupMenuItem(`${pr.repo} #${pr.number}  ${title}`);
            item.connect('activate', () => Gio.AppInfo.launch_default_for_uri(pr.url, null));
            menu.addMenuItem(item);
        }
        menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        const dash = new PopupMenu.PopupMenuItem('Open gh-dash');
        dash.connect('activate', async () => {
            await run(['tmux', 'new-window', '-n', 'review', `${SHIMS}/gh-dash`]);
            focusKitty();
        });
        menu.addMenuItem(dash);
        const refresh = new PopupMenu.PopupMenuItem('Refresh');
        refresh.connect('activate', () => this._refresh());
        menu.addMenuItem(refresh);
    }
}

function init() {
    return new PrReview();
}
