import Toybox.Lang;

class Metronome {
    private var _timer;
    private var _output;
    private var _timing;
    private var _enabled = false;
    private var _lastError = null;

    function initialize(timer, output) {
        _timer = timer;
        _output = output;
        _timing = new MetronomeTiming();
    }

    function start(bpm) {
        var period = _timing.periodMs(bpm);
        if (period == null) {
            _lastError = "Tempo must be between 40 and 180 BPM";
            return false;
        }
        if (_enabled) { _timer.stop(); }
        _enabled = false;
        _timer.start(method(:onTick), period, true);
        _enabled = true;
        _lastError = null;
        return true;
    }

    function stop() {
        if (_enabled) {
            _enabled = false;
            _timer.stop();
        }
    }

    function onTick() as Void {
        if (_enabled) { _output.pulse(); }
    }

    function isEnabled() { return _enabled; }
    function lastError() { return _lastError; }
}
