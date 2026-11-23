import Toybox.Sensor;
import Toybox.System;

class AccelerometerInput {
    const SAMPLE_RATE_HZ = 25;
    const SAMPLE_INTERVAL_MS = 1000 / SAMPLE_RATE_HZ;
    private var _detector;
    private var _metrics;
    private var _lastTimestamp = null;
    private var _lastError = null;
    private var _hadDataGap = false;
    private var _listening = false;
    private var _lastHitReceivedMs = null;

    function initialize(detector, metrics) {
        _detector = detector;
        _metrics = metrics;
    }

    function lastError() { return _lastError; }
    function hadDataGap() { return _hadDataGap; }
    function hasRecentHit(nowMs) {
        return _lastHitReceivedMs != null && nowMs - _lastHitReceivedMs <= 3000;
    }
    function reset() {
        _lastTimestamp = null;
        _lastHitReceivedMs = null;
        _lastError = null;
        _detector.reset();
        _metrics.breakSequence();
    }

    function start() {
        reset();
        Sensor.registerSensorDataListener(method(:onSensorData), {
            :period => 1,
            :accelerometer => {
                :enabled => true,
                :sampleRate => SAMPLE_RATE_HZ,
                :includeTimestamps => true
            }
        });
        _listening = true;
    }

    function stop() {
        if (_listening) {
            Sensor.unregisterSensorDataListener();
            _listening = false;
        }
    }

    function onSensorData(data as Sensor.SensorData) as Void {
        var acceleration = data.accelerometerData;
        if (acceleration == null) {
            setDataError("Accelerometer data unavailable");
            System.println(_lastError);
            return;
        }
        if (!processBatch(acceleration.timestamp, acceleration.x, acceleration.y, acceleration.z)) {
            System.println(_lastError);
        }
    }

    function processBatch(timestamps, x, y, z) {
        if (timestamps == null || x == null || y == null || z == null) {
            setDataError("Accelerometer samples or timestamps unavailable");
            return false;
        }
        var count = timestamps.size();
        if (count == 0) {
            setDataError("Accelerometer samples unavailable");
            return false;
        }
        if (x.size() != count || y.size() != count || z.size() != count) {
            setDataError("Accelerometer sample arrays differ in length");
            return false;
        }
        var sameTimestamp = count > 1;
        for (var i = 1; i < count; i += 1) {
            if (timestamps[i] != timestamps[0]) {
                sameTimestamp = false;
                break;
            }
        }
        var previous = _lastTimestamp;
        for (var i = 0; i < count; i += 1) {
            var sampleTime = sameTimestamp ? timestamps[0] + i * SAMPLE_INTERVAL_MS : timestamps[i];
            if (previous != null && sampleTime <= previous) {
                setDataError("Accelerometer timestamps are not increasing");
                return false;
            }
            previous = sampleTime;
        }
        previous = _lastTimestamp;
        for (var i = 0; i < count; i += 1) {
            var sampleTime = sameTimestamp ? timestamps[0] + i * SAMPLE_INTERVAL_MS : timestamps[i];
            if (previous != null && sampleTime - previous > 1000) {
                _detector.reset();
                _metrics.breakSequence();
                _lastHitReceivedMs = null;
                _hadDataGap = true;
            }
            if (_detector.processSample(x[i], y[i], z[i], sampleTime)) {
                _metrics.registerHit(sampleTime);
                _lastHitReceivedMs = System.getTimer();
            }
            previous = sampleTime;
        }
        _lastTimestamp = previous;
        _lastError = null;
        return true;
    }

    private function setDataError(message) {
        reset();
        _lastError = message;
        _hadDataGap = true;
    }
}
