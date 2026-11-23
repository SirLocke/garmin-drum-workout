import Toybox.System;

class DrumSession {
    private var _recorder;
    private var _input;
    private var _metronome;
    private var _metrics;
    private var _state = :ready;
    private var _lastError = null;
    private var _lastErrorAction = null;
    private var _lastLap = null;
    private var _countsSetForFinish = false;
    private var _finishSummary = null;
    private var _metronomeBpm = null;
    private var _lapNumber = 1;
    private var _startMs = null;
    private var _endMs = null;
    private var _pauseStartMs = null;
    private var _pausedMs = 0;

    function initialize(recorder, input, metronome, metrics) {
        _recorder = recorder;
        _input = input;
        _metronome = metronome;
        _metrics = metrics;
    }

    function start(nowMs) {
        if (_state != :ready) { return false; }
        try {
            _recorder.configureFields();
        } catch (error) {
            setError("FIT setup failed: " + error.getErrorMessage(), :start);
            return false;
        }
        if (!_recorder.start()) {
            setError(_recorder.lastError(), :start);
            return false;
        }
        _metrics.begin(nowMs);
        _startMs = nowMs;
        try {
            _input.start();
        } catch (error) {
            setError("Sensor start failed: " + error.getErrorMessage(), :save);
            _state = :saveError;
            return false;
        }
        _state = :recording;
        clearError();
        if (_metronomeBpm != null) { startMetronome(_metronomeBpm); }
        return true;
    }

    function pause() {
        if (_state != :recording) { return false; }
        if (!_recorder.pause()) {
            setError(_recorder.lastError(), :pause);
            return false;
        }
        _pauseStartMs = System.getTimer();
        _input.stop();
        _metronome.stop();
        _state = :paused;
        if (_lastErrorAction != :lap) { clearError(); }
        return true;
    }

    function resume() {
        if (_state != :paused) { return false; }
        try {
            _input.start();
        } catch (error) {
            setError("Sensor resume failed: " + error.getErrorMessage(), :resume);
            return false;
        }
        if (!_recorder.start()) {
            _input.stop();
            setError(_recorder.lastError(), :resume);
            return false;
        }
        _pausedMs += System.getTimer() - _pauseStartMs;
        _pauseStartMs = null;
        _state = :recording;
        if (_lastErrorAction != :lap) { clearError(); }
        if (_metronomeBpm != null) { startMetronome(_metronomeBpm); }
        return true;
    }

    function lap(nowMs) {
        if (_state != :recording) { return false; }
        var summary = songSummary(nowMs);
        try {
            _recorder.setLapCount(summary[:hits]);
            _recorder.setLapEstimates(summary[:averageSpm], summary[:beat]);
        } catch (error) {
            setError("Lap data failed: " + error.getErrorMessage(), :lap);
            return false;
        }
        if (!_recorder.addLap()) {
            setError(_recorder.lastError(), :lap);
            return false;
        }
        _lastLap = summary;
        _lapNumber += 1;
        _metrics.beginLap(metricTime(nowMs));
        clearError();
        return true;
    }

    function finish() {
        if (_state != :recording && _state != :paused && _state != :saveError) {
            return false;
        }
        if (_endMs == null) { _endMs = System.getTimer(); }
        _input.stop();
        _metronome.stop();
        if (!_countsSetForFinish) {
            try {
                if (_finishSummary == null) { _finishSummary = songSummary(_endMs); }
                _recorder.setLapCount(_finishSummary[:hits]);
                _recorder.setLapEstimates(_finishSummary[:averageSpm], _finishSummary[:beat]);
                _recorder.setTotalCount(_metrics.totalHits());
                var elapsed = elapsedMs(_endMs);
                var rate = elapsed > 0 ? 60000.0 * _metrics.totalHits() / elapsed : null;
                _recorder.setSessionEstimates(rate, _lapNumber == 1 ? _finishSummary[:beat] : null);
            } catch (error) {
                setError("FIT data failed: " + error.getErrorMessage(), :save);
                _state = :saveError;
                return false;
            }
            _countsSetForFinish = true;
        }
        if (!_recorder.finish()) {
            setError(_recorder.lastError(), :save);
            _state = :saveError;
            return false;
        }
        _lastLap = _finishSummary;
        _state = :saved;
        clearError();
        return true;
    }

    function state() { return _state; }
    function lastError() { return _lastError; }
    function lastErrorAction() { return _lastErrorAction; }
    function lastLap() { return _lastLap; }
    function setMetronome(bpm) {
        if (_state == :saveError || _state == :saved) { return false; }
        if (bpm != null && new MetronomeTiming().periodMs(bpm) == null) {
            setError("Tempo must be between 40 and 180 BPM", :metronome);
            return false;
        }
        if (bpm == null) {
            _metronome.stop();
        } else if (_state == :recording && !startMetronome(bpm)) {
            return false;
        }
        _metronomeBpm = bpm;
        clearError();
        return true;
    }

    private function startMetronome(bpm) {
        try {
            if (!_metronome.start(bpm)) {
                setError(_metronome.lastError(), :metronome);
                _metronomeBpm = null;
                return false;
            }
        } catch (error) {
            setError("Metronome failed: " + error.getErrorMessage(), :metronome);
            _metronomeBpm = null;
            return false;
        }
        return true;
    }

    function metronomeBpm() { return _metronomeBpm; }
    function lapNumber() { return _lapNumber; }
    function elapsedMs(nowMs) {
        if (_startMs == null) { return 0; }
        return metricTime(nowMs) - _startMs;
    }
    function metricTime(nowMs) {
        var end = _endMs == null ? nowMs : _endMs;
        if (_pauseStartMs != null && end > _pauseStartMs) { end = _pauseStartMs; }
        return end - _pausedMs;
    }
    function beatEstimate() {
        return _metrics.estimatedBeatBpm();
    }

    private function songSummary(nowMs) {
        return {
            :hits => _metrics.lapHits(),
            :averageSpm => _metrics.averageSpm(metricTime(nowMs)),
            :beat => beatEstimate(),
            :regularity => _metrics.regularityPercent()
        };
    }

    private function setError(message, action) {
        _lastError = message;
        _lastErrorAction = action;
    }

    private function clearError() {
        _lastError = null;
        _lastErrorAction = null;
    }
}
