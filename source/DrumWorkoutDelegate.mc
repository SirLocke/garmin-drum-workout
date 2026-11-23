import Toybox.Graphics;
import Toybox.System;
import Toybox.WatchUi;

class DrumWorkoutDelegate extends WatchUi.BehaviorDelegate {
    private var _session;
    private var _view;
    function initialize(session) {
        BehaviorDelegate.initialize();
        _session = session;
    }

    function setView(view) { _view = view; }

    function onKey(event) {
        var handled = handleKey(event.getKey(), System.getTimer());
        if (handled) { WatchUi.requestUpdate(); }
        return handled;
    }

    function onSelect() {
        if (_session.state() == :saveError) {
            return onMenu();
        }
        if (_view != null && _view.isMetronomePage() && _session.state() != :saved) {
            return onMetronomeMenu();
        }
        handleKey(WatchUi.KEY_START, System.getTimer());
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() {
        if (_session.state() == :ready || _session.state() == :saved) { return false; }
        if (_session.state() == :paused || _session.state() == :saveError) { return onMenu(); }
        handleKey(WatchUi.KEY_LAP, System.getTimer());
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() { _view.nextPage(); return true; }
    function onPreviousPage() { _view.previousPage(); return true; }

    function onMetronomeMenu() {
        var menu = new WatchUi.Menu2({:title => "Metronome"});
        addMetronomeItems(menu);
        WatchUi.pushView(menu, new DrumMenuDelegate(_session, self), WatchUi.SLIDE_UP);
        return true;
    }

    private function addMetronomeItems(menu) {
        menu.addItem(new WatchUi.MenuItem(_session.metronomeBpm() == null ? "Metronome on" : "Metronome off", null, :metronome, null));
        if (_session.metronomeBpm() != null) {
            menu.addItem(new WatchUi.MenuItem("Set tempo", _session.metronomeBpm() + " BPM", :tempo, null));
        }
    }

    function onMenu() {
        var menu = new WatchUi.Menu2({:title => "Drum Workout"});
        var state = _session.state();
        if (state == :paused) {
            menu.addItem(new WatchUi.MenuItem("Resume", null, :resume, null));
        }
        if (state == :paused || state == :saveError) {
            menu.addItem(new WatchUi.MenuItem(state == :saveError ? "Retry save" : "Stop and save", null, :save, null));
        }
        if (state == :recording) {
            menu.addItem(new WatchUi.MenuItem("Pause", null, :pause, null));
            menu.addItem(new WatchUi.MenuItem("Stop and save", null, :save, null));
        }
        if (state == :ready || state == :recording || state == :paused) {
            addMetronomeItems(menu);
        }
        if (state == :ready || state == :saved) {
            menu.addItem(new WatchUi.MenuItem("Exit", null, :exit, null));
        }
        WatchUi.pushView(menu, new DrumMenuDelegate(_session, self), WatchUi.SLIDE_UP);
        return true;
    }

    function handleKey(key, nowMs) {
        if (key == WatchUi.KEY_LAP) {
            if (_session.state() == :ready || _session.state() == :saved) { return false; }
            if (_session.state() == :paused || _session.state() == :saveError) { return onMenu(); }
            if (_session.state() == :recording) { _session.lap(nowMs); }
            return true;
        }
        if (key == WatchUi.KEY_START) {
            if (_session.state() == :ready) { _session.start(nowMs); }
            else if (_session.state() == :recording) { _session.pause(); }
            else if (_session.state() == :paused) { _session.resume(); }
            return true;
        }
        return false;
    }

    function handleAction(action) {
        if (action == :pause) { _session.pause(); return true; }
        if (action == :resume) { _session.resume(); return true; }
        if (action == :save) { _session.finish(); return true; }
        return false;
    }
}

class DrumMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _session;
    private var _controls;
    function initialize(session, controls) {
        Menu2InputDelegate.initialize();
        _session = session;
        _controls = controls;
    }

    function onSelect(item) {
        var action = item.getId();
        if (action == :tempo) {
            if (_session.metronomeBpm() == null) {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                WatchUi.requestUpdate();
                return;
            }
            var title = new WatchUi.Text({:text => "Tempo BPM", :locX => WatchUi.LAYOUT_HALIGN_CENTER,
                :locY => WatchUi.LAYOUT_VALIGN_BOTTOM, :color => Graphics.COLOR_BLACK});
            var picker = new DrumTempoPicker({:title => title, :pattern => [new DrumTempoFactory()],
                :defaults => [_session.metronomeBpm() - 40]});
            WatchUi.pushView(picker, new DrumTempoDelegate(_session, item), WatchUi.SLIDE_UP);
            return;
        }
        if (action == :metronome) {
            _session.setMetronome(_session.metronomeBpm() == null ? 120 : null);
        } else if (action == :exit) {
            System.exit();
            return;
        } else {
            _controls.handleAction(action);
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
    }

    function onBack() { WatchUi.popView(WatchUi.SLIDE_DOWN); }
}

class DrumTempoPicker extends WatchUi.Picker {
    function initialize(options) { Picker.initialize(options); }
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }
}

class DrumTempoFactory extends WatchUi.PickerFactory {
    function initialize() { PickerFactory.initialize(); }
    function getSize() { return 141; }
    function getValue(index) { return 40 + index; }
    function getDrawable(index, selected) {
        return new WatchUi.Text({:text => getValue(index).toString(), :color => Graphics.COLOR_BLACK,
            :font => Graphics.FONT_NUMBER_HOT, :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER});
    }
}

class DrumTempoDelegate extends WatchUi.PickerDelegate {
    private var _session;
    private var _menuItem;
    function initialize(session, menuItem) {
        PickerDelegate.initialize();
        _session = session;
        _menuItem = menuItem;
    }
    function applyTempo(value) {
        if (!_session.setMetronome(value)) { return false; }
        _menuItem.setSubLabel(_session.metronomeBpm() + " BPM");
        return true;
    }

    function onAccept(values) {
        if (applyTempo(values[0])) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        WatchUi.requestUpdate();
        return true;
    }
    function onCancel() { WatchUi.popView(WatchUi.SLIDE_DOWN); return true; }
}
