import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.FitContributor;

class ActivityRecorder {
    const FIT_UINT16_INVALID = 65535;
    private var _session;
    private var _recording = false;
    private var _lastError = null;
    private var _lapCountField = null;
    private var _totalCountField = null;
    private var _sessionStrokeRateField = null;
    private var _sessionBeatField = null;
    private var _lapStrokeRateField = null;
    private var _lapBeatField = null;

    function initialize(session) {
        _session = session;
    }

    function start() {
        if (_session == null || _recording) {
            _lastError = "Recording cannot start";
            return false;
        }
        if (!_session.start()) {
            _lastError = "Recording failed to start";
            return false;
        }
        _recording = true;
        _lastError = null;
        return true;
    }

    function addLap() {
        if (!_recording || !_session.addLap()) {
            _lastError = "Lap could not be recorded";
            return false;
        }
        _lastError = null;
        return true;
    }

    function pause() {
        if (!_recording || !_session.stop()) {
            _lastError = "Recording could not be paused";
            return false;
        }
        _recording = false;
        _lastError = null;
        return true;
    }

    function finish() {
        if (_session == null) {
            _lastError = "Recording is already closed";
            return false;
        }
        if (_recording) {
            if (!_session.stop()) {
                _lastError = "Recording could not be stopped";
                return false;
            }
            _recording = false;
        }
        if (!_session.save()) {
            _lastError = "Recording could not be saved";
            return false;
        }
        _session = null;
        _lastError = null;
        return true;
    }

    function isOpen() { return _session != null; }
    function lastError() { return _lastError; }
    function configureFields() {
        if (_session == null) {
            _session = ActivityRecording.createSession({
                :name => "Drum Workout",
                :sport => Activity.SPORT_TRAINING,
                :subSport => Activity.SUB_SPORT_CARDIO_TRAINING
            });
        }
        if (_lapCountField == null) {
            _lapCountField = _session.createField("Lap strokes", 0,
                FitContributor.DATA_TYPE_UINT32,
                {:mesgType => FitContributor.MESG_TYPE_LAP, :units => "strokes"});
        }
        if (_totalCountField == null) {
            _totalCountField = _session.createField("Total strokes", 1,
                FitContributor.DATA_TYPE_UINT32,
                {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "strokes"});
        }
        if (_sessionStrokeRateField == null) {
            _sessionStrokeRateField = _session.createField("Average stroke rate", 2,
                FitContributor.DATA_TYPE_FLOAT,
                {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "spm"});
        }
        if (_sessionBeatField == null) {
            _sessionBeatField = _session.createField("Beat estimate", 3,
                FitContributor.DATA_TYPE_FLOAT,
                {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "bpm"});
        }
        if (_lapStrokeRateField == null) {
            _lapStrokeRateField = _session.createField("Song average stroke rate", 4,
                FitContributor.DATA_TYPE_UINT16,
                {:mesgType => FitContributor.MESG_TYPE_LAP, :units => "spm"});
        }
        if (_lapBeatField == null) {
            _lapBeatField = _session.createField("Song beat estimate", 5,
                FitContributor.DATA_TYPE_UINT16,
                {:mesgType => FitContributor.MESG_TYPE_LAP, :units => "bpm"});
        }
    }

    function setLapCount(count) {
        _lapCountField.setData(count);
    }

    function setTotalCount(count) {
        _totalCountField.setData(count);
    }

    function setSessionEstimates(strokeRate, beat) {
        if (strokeRate != null) { _sessionStrokeRateField.setData(strokeRate.toFloat()); }
        if (beat != null) { _sessionBeatField.setData(beat.toFloat()); }
    }

    function setLapEstimates(strokeRate, beat) {
        _lapStrokeRateField.setData(strokeRate == null || strokeRate >= FIT_UINT16_INVALID - 0.5 ?
            FIT_UINT16_INVALID : (strokeRate + 0.5).toNumber());
        _lapBeatField.setData(beat == null ? FIT_UINT16_INVALID : (beat + 0.5).toNumber());
    }
}
