class HitDetector {
    private var _thresholdSquared;
    private var _refractoryMs;
    private var _previous = null;
    private var _lastHit = null;
    private var _armed = true;

    function initialize(thresholdMg, refractoryMs) {
        _thresholdSquared = thresholdMg * thresholdMg;
        _refractoryMs = refractoryMs;
    }

    function reset() {
        _previous = null;
        _lastHit = null;
        _armed = true;
    }

    function processSample(x, y, z, timestampMs) {
        if (_previous == null) {
            _previous = [x, y, z];
            return false;
        }
        var dx = x.toFloat() - _previous[0];
        var dy = y.toFloat() - _previous[1];
        var dz = z.toFloat() - _previous[2];
        _previous = [x, y, z];
        var above = dx * dx + dy * dy + dz * dz >= _thresholdSquared;
        if (!above) {
            _armed = true;
            return false;
        }
        if (!_armed) { return false; }
        _armed = false;
        if (_lastHit != null && timestampMs - _lastHit < _refractoryMs) {
            return false;
        }
        _lastHit = timestampMs;
        return true;
    }
}
