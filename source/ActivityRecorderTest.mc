import Toybox.Test;
import Toybox.Activity;
import Toybox.ActivityRecording;

(:test)
class FakeFitField {
    var value = null;
    var failWrite = false;
    function setData(data) {
        if (failWrite) { throw new Lang.Exception(); }
        value = data;
    }
}

(:test)
class FakeRecordingSession {
    var started = false;
    var saved = false;
    var failSave = false;
    var failStart = false;
    var failFields = false;
    var failLap = false;
    var failStop = false;
    var stopCount = 0;
    var fields = {};
    var lapValues = [];
    var finalLapValue = null;
    var finalTotalValue = null;
    var fieldCreations = 0;

    function createField(name, id, type, options) {
        if (failFields) { throw new Lang.Exception(); }
        fieldCreations += 1;
        var field = new FakeFitField();
        fields[id] = field;
        return field;
    }
    function start() {
        if (failStart) { return false; }
        started = true;
        return true;
    }
    function stop() {
        stopCount += 1;
        if (failStop) { return false; }
        if (fields.hasKey(0)) { finalLapValue = fields[0].value; }
        if (fields.hasKey(1)) { finalTotalValue = fields[1].value; }
        started = false;
        return true;
    }
    function save() {
        if (failSave) { return false; }
        if (fields.hasKey(0)) { finalLapValue = fields[0].value; }
        if (fields.hasKey(1)) { finalTotalValue = fields[1].value; }
        saved = true;
        return true;
    }
    function addLap() {
        if (failLap) { return false; }
        if (fields.hasKey(0)) { lapValues.add(fields[0].value); }
        return true;
    }
}

(:test)
function recordingSavesAndCloses(logger) {
    var session = new FakeRecordingSession();
    var recorder = new ActivityRecorder(session);
    Test.assert(recorder.start());
    Test.assert(recorder.addLap());
    Test.assert(recorder.finish());
    Test.assert(session.saved);
    Test.assert(!recorder.isOpen());
    return true;
}

(:test)
function failedSaveRetainsSessionForRetry(logger) {
    var session = new FakeRecordingSession();
    session.failSave = true;
    var recorder = new ActivityRecorder(session);
    Test.assert(recorder.start());
    Test.assert(!recorder.finish());
    Test.assert(recorder.isOpen());
    Test.assert(recorder.lastError() != null);
    session.failSave = false;
    Test.assert(recorder.finish());
    Test.assertEqual(1, session.stopCount);
    Test.assert(!recorder.isOpen());
    return true;
}

(:test)
function failedLapReportsFailure(logger) {
    var session = new FakeRecordingSession();
    session.failLap = true;
    var recorder = new ActivityRecorder(session);
    Test.assert(recorder.start());
    Test.assert(!recorder.addLap());
    Test.assert(recorder.lastError() != null);
    return true;
}

(:test)
function failedStopPreservesUnsavedSession(logger) {
    var session = new FakeRecordingSession();
    session.failStop = true;
    var recorder = new ActivityRecorder(session);
    Test.assert(recorder.start());
    Test.assert(!recorder.finish());
    Test.assert(recorder.isOpen());
    Test.assert(!session.saved);
    Test.assert(recorder.lastError() != null);
    session.failStop = false;
    Test.assert(recorder.finish());
    Test.assert(session.saved);
    return true;
}

(:test)
function storesStrokeCountsInFitFields(logger) {
    var session = new FakeRecordingSession();
    var recorder = new ActivityRecorder(session);
    recorder.configureFields();
    Test.assert(recorder.start());
    recorder.setLapCount(12);
    Test.assert(recorder.addLap());
    recorder.setTotalCount(23);
    Test.assert(recorder.finish());
    Test.assertEqual(12, session.fields[0].value);
    Test.assertEqual(23, session.fields[1].value);
    return true;
}

(:test)
function unrepresentableLapAverageIsRecordedAsMissing(logger) {
    var session = new FakeRecordingSession();
    var recorder = new ActivityRecorder(session);
    recorder.configureFields();
    recorder.setLapEstimates(100000.0, null);
    Test.assertEqual(65535, session.fields[4].value);
    return true;
}

(:test)
function simulatorCanRecordAndSaveLap(logger) {
    var recorder = new ActivityRecorder(null);
    Test.assert(!recorder.isOpen());
    recorder.configureFields();
    Test.assert(recorder.isOpen());
    Test.assert(recorder.start());
    recorder.setLapCount(12);
    Test.assert(recorder.addLap());
    recorder.setTotalCount(23);
    recorder.setSessionEstimates(120.0, 60.0);
    Test.assert(recorder.finish());
    return true;
}

(:test)
function simulatorCanPauseResumeAndSaveRecording(logger) {
    var recorder = new ActivityRecorder(null);
    recorder.configureFields();
    Test.assert(recorder.start());
    Test.assert(recorder.pause());
    Test.assert(recorder.start());
    recorder.setLapCount(12);
    recorder.setTotalCount(12);
    Test.assert(recorder.pause());
    Test.assert(recorder.finish());
    return true;
}
