/* Audio output submenu under the volume slider, for GNOME 42 (GNOME 43+ has
 * this built in). Uses the same Gvc mixer as the volume indicator, so it shows
 * the outputs of Settings > Sound and switches them the same way. */

const { Gvc } = imports.gi;
const Main = imports.ui.main;
const PopupMenu = imports.ui.popupMenu;
const Volume = imports.ui.status.volume;

// Built-in cards have long names ("Tiger Lake-LP Smart Sound Technology Audio
// Controller"), so they show only the port; short ones ("Fuxi-H3") show both.
const MAX_ORIGIN_LENGTH = 20;
// Gvc has no list call for outputs; their ids are small integers, so look them up.
const MAX_OUTPUT_ID = 500;

function labelFor(device) {
    const description = device.get_description();
    const origin = (device.get_origin() || '').trim();
    return origin && origin.length <= MAX_ORIGIN_LENGTH
        ? `${origin} · ${description}`
        : description;
}

class AudioOutputMenu {
    enable() {
        this._control = Volume.getMixerControl();
        this._item = new PopupMenu.PopupSubMenuMenuItem('', true);
        this._item.icon.icon_name = 'audio-card-symbolic';
        // In the system menu, right above Bluetooth (below the separator after
        // volume and brightness). Without Bluetooth, right after the separator.
        const aggregate = Main.panel.statusArea.aggregateMenu;
        const items = aggregate.menu._getMenuItems();
        let position = aggregate._bluetooth ? items.indexOf(aggregate._bluetooth.menu) : -1;
        if (position < 0)
            position = items.indexOf(aggregate._brightness.menu) + 2;
        aggregate.menu.addMenuItem(this._item, position);

        this._signals = ['state-changed', 'output-added', 'output-removed', 'active-output-update']
            .map(signal => this._control.connect(signal, () => this._rebuild()));
        this._rebuild();
    }

    disable() {
        this._signals.forEach(id => this._control.disconnect(id));
        this._signals = null;
        this._item.destroy();
        this._item = null;
        this._control = null;
    }

    _rebuild() {
        if (this._control.get_state() !== Gvc.MixerControlState.READY)
            return;

        const sink = this._control.get_default_sink();
        const active = sink ? this._control.lookup_device_from_stream(sink) : null;

        this._item.menu.removeAll();
        for (let id = 0; id <= MAX_OUTPUT_ID; id++) {
            const device = this._control.lookup_output_id(id);
            // Unplugged ports (HDMI with no monitor, empty headphone jack) are hidden.
            if (!device || !device.port_available)
                continue;

            const entry = new PopupMenu.PopupMenuItem(labelFor(device));
            const isActive = active !== null && active.get_id() === device.get_id();
            entry.setOrnament(isActive ? PopupMenu.Ornament.DOT : PopupMenu.Ornament.NONE);
            entry.connect('activate', () => this._control.change_output(device));
            this._item.menu.addMenuItem(entry);
        }

        this._item.label.text = active ? labelFor(active) : 'Audio output';
    }
}

function init() {
    return new AudioOutputMenu();
}
