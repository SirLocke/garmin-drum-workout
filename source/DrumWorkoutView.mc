import Toybox.Graphics;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class DrumWorkoutView extends WatchUi.View {
    private var _session;
    private var _metrics;
    private var _input;
    private var _timer;
    private var _page = 0;
    private var _topHint;
    private var _bottomHint;

    function initialize(session, metrics, input) {
        View.initialize();
        _session = session;
        _metrics = metrics;
        _input = input;
        _timer = new Timer.Timer();
    }

    function onShow() {
        _timer.start(method(:refresh), 1000, true);
    }

    function onHide() {
        _timer.stop();
    }

    function refresh() {
        WatchUi.requestUpdate();
    }

    function nextPage() {
        _page = (_page + 1) % 4;
        WatchUi.requestUpdate();
    }

    function previousPage() {
        _page = (_page + 3) % 4;
        WatchUi.requestUpdate();
    }

    function isMetronomePage() { return _page == 3; }

    function onUpdate(dc) {
        render(dc);
    }

    function onLayout(dc) {
        _topHint = WatchUi.loadResource(Rez.Drawables.RightTopHint);
        _bottomHint = WatchUi.loadResource(Rez.Drawables.RightBottomHint);
    }

    function render(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var now = System.getTimer();
        var state = _session.state();
        var status = "Ready";
        if (state == :recording) { status = "Recording"; }
        else if (state == :paused) { status = "Paused"; }
        else if (state == :saved) { status = "Saved"; }
        else if (state == :saveError) { status = "Save needed"; }
        var seconds = _session.elapsedMs(now) / 1000;
        var elapsed = (seconds / 60).format("%02d") + ":" + (seconds % 60).format("%02d");
        var header = state == :recording ? "REC  " + elapsed : status + "  " + elapsed;
        if (state == :ready) { header = "Ready"; }
        else if (state == :saved) { header = "Saved"; }
        if (_input.hadDataGap()) {
            if (state == :saved) { header = "SAVED SENSOR GAP"; }
            else { header = "SENSOR GAP"; }
        }
        var lines;
        var positions = null;
        var fonts = null;
        if (_page == 0) {
            lines = [header,
                "Song " + _session.lapNumber(),
                "Strokes: " + _metrics.lapHits(),
                "Avg: " + (state == :ready ? "--" : valueText(_metrics.averageSpm(_session.metricTime(now)))) + " SPM",
                "Beat~/2: " + valueText(state == :recording && !_input.hasRecentHit(now) ? null : _session.beatEstimate()) + " BPM"];
            positions = [24, 50, 77, 104, 131];
            fonts = [Graphics.FONT_TINY, Graphics.FONT_TINY, Graphics.FONT_SMALL, Graphics.FONT_SMALL, Graphics.FONT_SMALL];
        } else if (_page == 1) {
            lines = [header,
                "Total: " + _metrics.totalHits(),
                "Song avg: " + (state == :ready ? "--" : valueText(_metrics.averageSpm(_session.metricTime(now)))) + " SPM",
                "Evenness: " + valueText(_metrics.regularityPercent()) + "%",
                _session.metronomeBpm() == null ? "Metro: off" : "Metro: " + _session.metronomeBpm() + " BPM"];
        } else if (_page == 2) {
            var last = _session.lastLap();
            lines = [header,
                last == null ? "No completed song" :
                    "Last: " + last[:hits] + "  Evenness: " + valueText(last[:regularity]) + "%",
                last == null ? "Avg: -- SPM" : "Avg: " + valueText(last[:averageSpm]) + " SPM",
                last == null ? "Beat~/2: -- BPM" : "Beat~/2: " + valueText(last[:beat]) + " BPM"];
        } else {
            lines = [header, "Metronome",
                _session.metronomeBpm() == null ? "Off" : "On: " + _session.metronomeBpm() + " BPM",
                state == :saved ? "" : "START: settings"];
        }
        if (state == :saveError) {
            lines = errorLines("Save required", _session.lastError(), "START: save menu");
            positions = null;
            fonts = null;
        } else if (_session.lastError() != null) {
            var instruction = "PAGES: metronome";
            var action = _session.lastErrorAction();
            if (action == :lap) {
                instruction = state == :paused ? "START: resume" : "NEXT: retry song";
            }
            else if (action == :start) { instruction = "START: retry"; }
            else if (action == :pause) { instruction = "START: retry pause"; }
            else if (action == :resume) { instruction = "START: resume"; }
            else if (action == :metronome) {
                instruction = isMetronomePage() ? "START: settings" : "PAGES: metronome";
            }
            lines = errorLines("Action failed", _session.lastError(), instruction);
            positions = null;
            fonts = null;
        }
        for (var i = 0; i < lines.size(); i += 1) {
            var font = i == 0 ? Graphics.FONT_XTINY : (fonts == null ? Graphics.FONT_TINY : fonts[i]);
            if (font == Graphics.FONT_SMALL && dc.getTextWidthInPixels(lines[i], font) > dc.getWidth() - 70) {
                font = Graphics.FONT_TINY;
            }
            var x = dc.getWidth() / 2;
            if (i == 0 && state != :saved && state != :saveError && _session.lastError() == null) {
                x -= 16;
            }
            dc.drawText(x, positions == null ? 35 + i * 27 : positions[i],
                font, lines[i], Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (_session.lastError() == null && state != :saveError) {
            var center = dc.getWidth() / 2;
            dc.drawLine(center - 4, dc.getHeight() - 23, center, dc.getHeight() - 19);
            dc.drawLine(center, dc.getHeight() - 19, center + 4, dc.getHeight() - 23);
            if (_page == 0 && state != :saved) {
                dc.drawText(16, 65, Graphics.FONT_XTINY, "UP", Graphics.TEXT_JUSTIFY_LEFT);
                dc.drawText(16, 82, Graphics.FONT_XTINY, "METRO", Graphics.TEXT_JUSTIFY_LEFT);
            }
        }
        var topLabel = state == :ready ? "START" :
            (state == :recording ? "PAUSE" : (state == :paused ? "RESUME" : null));
        if (isMetronomePage() && (state == :ready || state == :recording || state == :paused)) {
            topLabel = "SET";
        }
        var bottomLabel = state == :recording ? "NEXT" :
            ((state == :paused || state == :saveError) ? "SAVE" :
                ((state == :ready || state == :saved) ? "BACK" : null));
        if (topLabel != null) {
            dc.drawText(dc.getWidth() - 37, 43, Graphics.FONT_XTINY, topLabel, Graphics.TEXT_JUSTIFY_RIGHT);
        }
        if (bottomLabel != null) {
            dc.drawText(dc.getWidth() - 37, 172, Graphics.FONT_XTINY, bottomLabel, Graphics.TEXT_JUSTIFY_RIGHT);
        }
        if (_topHint != null && state != :saved) {
            dc.drawBitmap(dc.getWidth() - 36, 50, _topHint);
        }
        if (_bottomHint != null && bottomLabel != null) {
            dc.drawBitmap(dc.getWidth() - 36, 172, _bottomHint);
        }
    }

    private function valueText(value) {
        return value == null ? "--" : value.format("%.0f");
    }

    private function errorLines(title, message, instruction) {
        var lines = [title, "", "", "", "", instruction];
        if (message != null) {
            for (var i = 0; i < 4 && i * 19 < message.length(); i += 1) {
                var end = (i + 1) * 19;
                if (end > message.length()) { end = message.length(); }
                lines[i + 1] = message.substring(i * 19, end);
            }
        }
        return lines;
    }
}
