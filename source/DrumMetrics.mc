import Toybox.Math;

class DrumMetrics {
    private var _totalHits = 0;
    private var _lapHits = 0;
    private var _lapStart = 0;
    private var _lastHit = null;
    private var _intervals = [];
    private var _nextInterval = 0;
    private var _sessionIntervals = [];
    private var _nextSessionInterval = 0;
    private var _beatIntervals = [];

    function initialize() {}
    function begin(startMs) {
        _totalHits = 0;
        _sessionIntervals = [];
        _nextSessionInterval = 0;
        beginLap(startMs);
    }

    function registerHit(timestampMs) {
        if (_lastHit != null && timestampMs > _lastHit) {
            var interval = timestampMs - _lastHit;
            if (interval > 2000) {
                _beatIntervals = [];
            } else if (_beatIntervals.size() == 64) {
                for (var i = 1; i < _beatIntervals.size(); i += 1) {
                    _beatIntervals[i - 1] = _beatIntervals[i];
                }
                _beatIntervals[63] = interval;
            } else {
                _beatIntervals.add(interval);
            }
            if (_intervals.size() < 64) {
                _intervals.add(interval);
            } else {
                _intervals[_nextInterval] = interval;
                _nextInterval = (_nextInterval + 1) % 64;
            }
            if (_sessionIntervals.size() < 64) {
                _sessionIntervals.add(interval);
            } else {
                _sessionIntervals[_nextSessionInterval] = interval;
                _nextSessionInterval = (_nextSessionInterval + 1) % 64;
            }
        }
        _lastHit = timestampMs;
        _totalHits += 1;
        _lapHits += 1;
    }

    function totalHits() { return _totalHits; }
    function lapHits() { return _lapHits; }
    function sessionTempoBpm() { return tempoFor(_sessionIntervals); }

    function breakSequence() {
        _lastHit = null;
        _beatIntervals = [];
    }

    function beginLap(startMs) {
        _lapStart = startMs;
        _lapHits = 0;
        _lastHit = null;
        _beatIntervals = [];
        _intervals = [];
        _nextInterval = 0;
    }

    function averageSpm(nowMs) {
        var elapsed = nowMs - _lapStart;
        return elapsed > 0 ? 60000.0 * _lapHits / elapsed : null;
    }

    function estimatedTempoBpm() {
        return tempoFor(_intervals);
    }

    function estimatedBeatBpm() {
        var count = _beatIntervals.size();
        if (count < 3) { return null; }
        var candidates = {};
        var requiredMatches = (count + 3) / 4;
        if (requiredMatches < 3) { requiredMatches = 3; }
        for (var candidate = 0; count >= 9 && candidate < count; candidate += 1) {
            var beat = _beatIntervals[candidate];
            if (beat < 333 || beat > 1500 || candidates.hasKey(beat)) { continue; }
            candidates[beat] = true;
            var matches = 0;
            var sum = 0.0;
            for (var i = 0; i + 2 < count;) {
                if (matches + (count - i) / 3 < requiredMatches) { break; }
                var first = _beatIntervals[i];
                var second = _beatIntervals[i + 1];
                var third = _beatIntervals[i + 2];
                if (first * 2 >= beat * 0.85 && first * 2 <= beat * 1.15 &&
                    second * 2 >= beat * 0.85 && second * 2 <= beat * 1.15 &&
                    third >= beat * 0.85 && third <= beat * 1.15) {
                    matches += 1;
                    sum += third;
                    i += 3;
                } else {
                    i += 1;
                }
            }
            if (matches >= requiredMatches) {
                return 60000.0 * matches / sum;
            }
        }
        var strokeRate = tempoFor(_beatIntervals);
        var beatRate = strokeRate / 2.0;
        if (beatRate < 40.0 || beatRate > 180.0) { return null; }
        var expected = 60000.0 / strokeRate;
        var consistent = 0;
        for (var i = 0; i < count; i += 1) {
            if (_beatIntervals[i] >= expected * 0.85 && _beatIntervals[i] <= expected * 1.15) {
                consistent += 1;
            }
        }
        if (consistent * 4 >= count * 3) { return beatRate; }
        return null;
    }

    private function tempoFor(intervals) {
        var count = intervals.size();
        if (count < 3) { return null; }
        var sorted = intervals.slice(0, null);
        sorted.sort(null);
        var mid = count / 2;
        var median = count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2.0 : sorted[mid];
        return 60000.0 / median;
    }

    function regularityPercent() {
        var count = _intervals.size();
        if (count < 3) { return null; }
        var sum = 0.0;
        for (var i = 0; i < count; i += 1) { sum += _intervals[i]; }
        var mean = sum / count;
        var squared = 0.0;
        for (var i = 0; i < count; i += 1) {
            var diff = _intervals[i] - mean;
            squared += diff * diff;
        }
        var score = 1.0 - Math.sqrt(squared / count) / mean;
        return score > 0 ? score * 100.0 : 0.0;
    }
}
