import Toybox.Test;
import Toybox.Lang;

(:test)
class FakeSensorInput {
    var started = false;
    var failStart = false;
    var gap = false;
    var recentHit = true;
    function start() {
        if (failStart) { throw new Lang.Exception(); }
        started = true;
    }
    function stop() { started = false; }
    function lastError() { return null; }
    function hadDataGap() { return gap; }
    function hasRecentHit(now) { return recentHit; }
}

(:test)
class FakeSessionMetronome {
    var stopped = false;
    var startedBpm = null;
    var failStart = false;
    function start(bpm) {
        if (failStart) { throw new Lang.Exception(); }
        stopped = false;
        startedBpm = bpm;
        return true;
    }
    function stop() { stopped = true; }
}

(:test)
class CountingDrumMetrics extends DrumMetrics {
    var beatCalculations = 0;
    var tempoCalculations = 0;
    function estimatedBeatBpm() {
        beatCalculations += 1;
        return DrumMetrics.estimatedBeatBpm();
    }
    function estimatedTempoBpm() {
        tempoCalculations += 1;
        return DrumMetrics.estimatedTempoBpm();
    }
}

(:test)
function lapStartsImmediatelyAndPreservesTotals(logger) {
    var fitSession = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(fitSession), input, new FakeSessionMetronome(), metrics);
    Test.assert(session.start(0));
    metrics.registerHit(500);
    metrics.registerHit(1000);
    Test.assert(session.lap(2000));
    Test.assertEqual(2, session.lastLap()[:hits]);
    Test.assertEqual(60.0, session.lastLap()[:averageSpm]);
    Test.assertEqual(2, metrics.totalHits());
    Test.assertEqual(0, metrics.lapHits());
    Test.assert(input.started);
    return true;
}

(:test)
function failedLapDoesNotResetCounts(logger) {
    var fitSession = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fitSession), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(0));
    metrics.registerHit(500);
    fitSession.failLap = true;
    Test.assert(!session.lap(1000));
    Test.assertEqual(1, metrics.lapHits());
    Test.assert(session.lastError() != null);
    Test.assertEqual(:lap, session.lastErrorAction());
    fitSession.failLap = false;
    Test.assert(session.lap(1200));
    Test.assert(session.lastErrorAction() == null);
    return true;
}

(:test)
function laterMetronomeFailureReplacesLapRecoveryAction(logger) {
    var fit = new FakeRecordingSession();
    var metro = new FakeSessionMetronome();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), metro, new DrumMetrics());
    Test.assert(session.start(0));
    fit.failLap = true;
    Test.assert(!session.lap(1000));
    metro.failStart = true;
    Test.assert(!session.setMetronome(120));
    Test.assertEqual(:metronome, session.lastErrorAction());
    return true;
}

(:test)
function pauseResumeAndFinishKeepOneSession(logger) {
    var fitSession = new FakeRecordingSession();
    var input = new FakeSensorInput();
    var metronome = new FakeSessionMetronome();
    var session = new DrumSession(new ActivityRecorder(fitSession), input, metronome, new DrumMetrics());
    Test.assert(session.start(0));
    Test.assert(session.pause());
    Test.assert(!input.started);
    Test.assert(metronome.stopped);
    Test.assert(!fitSession.started);
    Test.assert(!session.lap(1000));
    Test.assert(session.resume());
    Test.assert(input.started);
    Test.assert(session.finish());
    Test.assert(fitSession.saved);
    Test.assertEqual(:saved, session.state());
    return true;
}

(:test)
function pauseFailureKeepsRecordingAndCanBeRetried(logger) {
    var fit = new FakeRecordingSession();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(fit), input, new FakeSessionMetronome(), new DrumMetrics());
    Test.assert(session.start(Toybox.System.getTimer()));
    fit.failStop = true;
    Test.assert(!session.pause());
    Test.assertEqual(:recording, session.state());
    Test.assert(input.started);
    Test.assert(session.lastError() != null);
    fit.failStop = false;
    Test.assert(session.pause());
    Test.assertEqual(:paused, session.state());
    Test.assert(!fit.started);
    Test.assert(session.finish());
    return true;
}

(:test)
function pausedTimeDoesNotAdvanceAndFailedResumeStaysPaused(logger) {
    var fit = new FakeRecordingSession();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(fit), input, new FakeSessionMetronome(), new DrumMetrics());
    Test.assert(session.start(Toybox.System.getTimer()));
    Test.assert(session.pause());
    var frozen = session.metricTime(Toybox.System.getTimer());
    Test.assertEqual(frozen, session.metricTime(Toybox.System.getTimer() + 60000));
    fit.failStart = true;
    Test.assert(!session.resume());
    Test.assert(!input.started);
    Test.assertEqual(:paused, session.state());
    Test.assertEqual(frozen, session.metricTime(Toybox.System.getTimer() + 60000));
    fit.failStart = false;
    Test.assert(session.resume());
    Test.assert(fit.started);
    Test.assert(session.finish());
    return true;
}

(:test)
function storesLapAndFinalTotalsInFit(logger) {
    var fitSession = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fitSession), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(0));
    metrics.registerHit(500);
    metrics.registerHit(1000);
    Test.assert(session.lap(2000));
    Test.assertEqual(2, fitSession.lapValues[0]);
    metrics.registerHit(2500);
    Test.assert(session.finish());
    Test.assertEqual(1, fitSession.finalLapValue);
    Test.assertEqual(3, fitSession.finalTotalValue);
    return true;
}

(:test)
function lapFitStrokeRateIsSongAverage(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(0));
    for (var i = 0; i < 60; i += 1) { metrics.registerHit(i * 200); }
    Test.assert(session.lap(60000));
    Test.assertEqual(60, fit.fields[4].value);
    Test.assertEqual(60.0, session.lastLap()[:averageSpm]);
    return true;
}

(:test)
function sessionFitStrokeRateIncludesAllActiveTime(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(Toybox.System.getTimer() - 60000));
    for (var i = 0; i < 60; i += 1) { metrics.registerHit(i * 200); }
    Test.assert(session.pause());
    Test.assert(session.finish());
    Test.assert(fit.fields[2].value >= 59.9 && fit.fields[2].value <= 60.0);
    return true;
}

(:test)
function successfulSaveShowsFinalSongRatherThanPreviousSong(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(Toybox.System.getTimer()));
    metrics.registerHit(500);
    Test.assert(session.lap(Toybox.System.getTimer()));
    metrics.registerHit(1000);
    metrics.registerHit(1500);
    fit.failSave = true;
    Test.assert(!session.finish());
    Test.assertEqual(1, session.lastLap()[:hits]);
    fit.failSave = false;
    Test.assert(session.finish());
    Test.assertEqual(2, session.lastLap()[:hits]);
    return true;
}

(:test)
function savesFullIrregularSong(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(Toybox.System.getTimer()));
    var timestamp = 0;
    metrics.registerHit(timestamp);
    for (var i = 0; i < 64; i += 1) {
        timestamp += 1000 - 10 * i;
        metrics.registerHit(timestamp);
    }
    Test.assert(session.finish());
    Test.assertEqual(65, fit.finalTotalValue);
    Test.assertEqual(65, session.lastLap()[:hits]);
    return true;
}

(:test)
function finishCalculatesSongEstimatesOnlyOnce(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new CountingDrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(Toybox.System.getTimer()));
    var timestamp = 0;
    metrics.registerHit(timestamp);
    for (var i = 0; i < 64; i += 1) {
        timestamp += 1000 - 10 * i;
        metrics.registerHit(timestamp);
    }
    Test.assert(session.finish());
    Test.assertEqual(1, metrics.beatCalculations);
    Test.assertEqual(0, metrics.tempoCalculations);
    return true;
}

(:test)
function sensorStartFailureKeepsRecordingAvailableToSave(logger) {
    var fitSession = new FakeRecordingSession();
    var input = new FakeSensorInput();
    input.failStart = true;
    var session = new DrumSession(new ActivityRecorder(fitSession), input, new FakeSessionMetronome(), new DrumMetrics());
    Test.assert(!session.start(0));
    Test.assertEqual(:saveError, session.state());
    Test.assert(session.lastError() != null);
    Test.assert(fitSession.started);
    Test.assert(session.finish());
    Test.assert(fitSession.saved);
    return true;
}

(:test)
function sensorResumeFailureKeepsSessionPaused(logger) {
    var fitSession = new FakeRecordingSession();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(fitSession), input, new FakeSessionMetronome(), new DrumMetrics());
    Test.assert(session.start(0));
    Test.assert(session.pause());
    input.failStart = true;
    Test.assert(!session.resume());
    Test.assertEqual(:paused, session.state());
    Test.assert(session.lastError() != null);
    Test.assert(session.finish());
    return true;
}

(:test)
function retryAfterRecordingStartFailureDoesNotRecreateFields(logger) {
    var fitSession = new FakeRecordingSession();
    fitSession.failStart = true;
    var session = new DrumSession(new ActivityRecorder(fitSession), new FakeSensorInput(), new FakeSessionMetronome(), new DrumMetrics());
    Test.assert(!session.start(0));
    fitSession.failStart = false;
    Test.assert(session.start(1000));
    Test.assertEqual(6, fitSession.fieldCreations);
    Test.assert(session.finish());
    return true;
}

(:test)
function failedSaveCanBeRetriedWithFinalCounts(logger) {
    var fitSession = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fitSession), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(0));
    metrics.registerHit(500);
    fitSession.failSave = true;
    Test.assert(!session.finish());
    Test.assertEqual(:saveError, session.state());
    fitSession.failSave = false;
    Test.assert(session.finish());
    Test.assertEqual(1, fitSession.finalLapValue);
    Test.assertEqual(1, fitSession.finalTotalValue);
    Test.assertEqual(1, fitSession.stopCount);
    return true;
}

(:test)
function metronomeSettingsSurvivePauseAndCanBeDisabled(logger) {
    var metronome = new FakeSessionMetronome();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), new FakeSensorInput(), metronome, new DrumMetrics());
    Test.assert(session.setMetronome(120));
    Test.assert(metronome.startedBpm == null);
    Test.assert(session.start(0));
    Test.assertEqual(120, metronome.startedBpm);
    Test.assert(session.pause());
    Test.assert(metronome.stopped);
    metronome.startedBpm = null;
    Test.assert(session.resume());
    Test.assertEqual(120, metronome.startedBpm);
    Test.assert(session.setMetronome(null));
    Test.assert(metronome.stopped);
    Test.assert(session.finish());
    return true;
}

(:test)
function rejectsInvalidMetronomeTempoWithoutChangingSetting(logger) {
    var metronome = new FakeSessionMetronome();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), new FakeSensorInput(), metronome, new DrumMetrics());
    Test.assert(session.setMetronome(120));
    Test.assert(!session.setMetronome(181));
    Test.assertEqual(120, session.metronomeBpm());
    Test.assert(session.lastError() != null);
    return true;
}

(:test)
function lapNumbersAdvanceOnlyAfterSuccessfulLap(logger) {
    var fit = new FakeRecordingSession();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), new DrumMetrics());
    Test.assert(session.start(0));
    Test.assertEqual(1, session.lapNumber());
    fit.failLap = true;
    Test.assert(!session.lap(1000));
    Test.assertEqual(1, session.lapNumber());
    fit.failLap = false;
    Test.assert(session.lap(2000));
    Test.assertEqual(2, session.lapNumber());
    return true;
}

(:test)
function fieldCreationFailureIsShownAndCanBeRetried(logger) {
    var fit = new FakeRecordingSession();
    fit.failFields = true;
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), new DrumMetrics());
    Test.assert(!session.start(0));
    Test.assertEqual(:ready, session.state());
    Test.assert(session.lastError() != null);
    fit.failFields = false;
    Test.assert(session.start(1000));
    Test.assert(session.finish());
    return true;
}

(:test)
function fitFieldWriteFailureDoesNotLoseCountsAndCanBeRetried(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(0));
    metrics.registerHit(500);
    fit.fields[0].failWrite = true;
    Test.assert(!session.lap(1000));
    Test.assertEqual(1, metrics.lapHits());
    Test.assert(session.lastError() != null);
    Test.assert(!session.finish());
    Test.assertEqual(:saveError, session.state());
    fit.fields[0].failWrite = false;
    Test.assert(session.finish());
    Test.assertEqual(1, fit.finalTotalValue);
    return true;
}

(:test)
function metricTimeStopsAdvancingAfterSave(logger) {
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), new FakeSensorInput(), new FakeSessionMetronome(), new DrumMetrics());
    Test.assert(session.start(Toybox.System.getTimer()));
    Test.assertEqual(123, session.metricTime(123));
    Test.assert(session.finish());
    var saved = session.metricTime(Toybox.System.getTimer());
    Test.assertEqual(saved, session.metricTime(saved + 60000));
    return true;
}

(:test)
function failedMetronomeStartIsReportedAsDisabled(logger) {
    var metro = new FakeSessionMetronome();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), new FakeSensorInput(), metro, new DrumMetrics());
    Test.assert(session.setMetronome(120));
    metro.failStart = true;
    Test.assert(session.start(0));
    Test.assert(session.metronomeBpm() == null);
    Test.assert(session.lastError() != null);
    Test.assert(session.finish());
    return true;
}

(:test)
function beatEstimateSupportsUniformAndMixedRhythms(logger) {
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(0));
    Test.assert(session.beatEstimate() == null);
    metrics.registerHit(500);
    metrics.registerHit(1000);
    metrics.registerHit(1500);
    metrics.registerHit(2000);
    Test.assertEqual(120.0, metrics.estimatedTempoBpm());
    Test.assertEqual(60.0, session.beatEstimate());
    metrics.beginLap(3000);
    metrics.registerHit(3000);
    for (var i = 0; i < 3; i += 1) {
        metrics.registerHit(3250 + i * 1000);
        metrics.registerHit(3500 + i * 1000);
        metrics.registerHit(4000 + i * 1000);
    }
    Test.assertEqual(120.0, session.beatEstimate());
    Test.assert(session.lap(7000));
    Test.assertEqual(120.0, session.lastLap()[:beat]);
    Test.assert(session.beatEstimate() == null);
    return true;
}

(:test)
function beatEstimateDoesNotBridgeSensorGaps(logger) {
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(0));
    metrics.registerHit(0);
    for (var i = 0; i < 3; i += 1) {
        metrics.registerHit(250 + i * 1000);
        metrics.registerHit(500 + i * 1000);
        metrics.registerHit(1000 + i * 1000);
    }
    Test.assertEqual(120.0, session.beatEstimate());
    metrics.breakSequence();
    Test.assert(session.beatEstimate() == null);
    metrics.registerHit(10000);
    metrics.registerHit(10250);
    Test.assert(session.beatEstimate() == null);
    return true;
}

(:test)
function beatEstimateDoesNotBridgeLongRest(logger) {
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(0));
    metrics.registerHit(0);
    for (var i = 0; i < 3; i += 1) {
        metrics.registerHit(250 + i * 1000);
        metrics.registerHit(500 + i * 1000);
        metrics.registerHit(1000 + i * 1000);
    }
    Test.assertEqual(120.0, session.beatEstimate());
    metrics.registerHit(10000);
    Test.assert(session.beatEstimate() == null);
    return true;
}

(:test)
function uniformEighthNotesAreSavedAsAssumedBeatTempo(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(0));
    metrics.registerHit(0);
    metrics.registerHit(250);
    metrics.registerHit(500);
    metrics.registerHit(750);
    Test.assertEqual(120.0, session.beatEstimate());
    Test.assert(session.lap(1000));
    Test.assertEqual(120, fit.fields[5].value);
    Test.assertEqual(120.0, session.lastLap()[:beat]);
    return true;
}

(:test)
function inconsistentIntervalsDoNotInventBeatTempo(logger) {
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(0));
    metrics.registerHit(0);
    metrics.registerHit(200);
    metrics.registerHit(550);
    metrics.registerHit(1200);
    metrics.registerHit(1450);
    metrics.registerHit(2000);
    Test.assert(session.beatEstimate() == null);
    return true;
}

(:test)
function beatEstimateToleratesTimingVariationAndUniformRhythm(logger) {
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(0));
    var now = 0;
    metrics.registerHit(now);
    for (var i = 0; i < 4; i += 1) {
        now += 240; metrics.registerHit(now);
        now += 260; metrics.registerHit(now);
        now += 500; metrics.registerHit(now);
    }
    Test.assert(session.beatEstimate() >= 118.0 && session.beatEstimate() <= 122.0);
    for (var i = 0; i < 64; i += 1) {
        now += 500; metrics.registerHit(now);
    }
    Test.assertEqual(60.0, session.beatEstimate());
    return true;
}

(:test)
function sessionFitDoesNotInventBeatFromUniformStrokes(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    var now = Toybox.System.getTimer();
    Test.assert(session.start(now - 60000));
    metrics.registerHit(500);
    metrics.registerHit(1000);
    metrics.registerHit(1500);
    metrics.registerHit(2000);
    Test.assert(session.lap(now - 30000));
    Test.assert(session.pause());
    Test.assert(session.finish());
    Test.assert(fit.fields[2].value >= 3.99 && fit.fields[2].value <= 4.0);
    Test.assert(fit.fields[3].value == null);
    return true;
}

(:test)
function sessionFitBeatRemainsUnsetWhenNotEnoughIntervals(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(Toybox.System.getTimer() - 60000));
    metrics.registerHit(500);
    Test.assert(session.pause());
    Test.assert(session.finish());
    Test.assert(fit.fields[2].value >= 0.99 && fit.fields[2].value <= 1.0);
    Test.assert(fit.fields[3].value == null);
    return true;
}

(:test)
function lapFitBeatIsClearedWhenNextSongHasTooFewIntervals(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    var start = Toybox.System.getTimer() - 60000;
    Test.assert(session.start(start));
    metrics.registerHit(0);
    for (var i = 0; i < 3; i += 1) {
        metrics.registerHit(250 + i * 1000);
        metrics.registerHit(500 + i * 1000);
        metrics.registerHit(1000 + i * 1000);
    }
    Test.assert(session.lap(start + 3200));
    Test.assertEqual(188, fit.fields[4].value);
    Test.assertEqual(120, fit.fields[5].value);
    metrics.registerHit(3500);
    Test.assert(session.pause());
    Test.assert(session.finish());
    Test.assertEqual(1, fit.fields[4].value);
    Test.assertEqual(65535, fit.fields[5].value);
    Test.assert(fit.fields[2].value >= 10.99 && fit.fields[2].value <= 11.0);
    Test.assert(fit.fields[3].value == null);
    return true;
}

(:test)
function lapEstimateWriteFailureKeepsTheSongForRetry(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(0));
    metrics.registerHit(500);
    fit.fields[4].failWrite = true;
    Test.assert(!session.lap(1000));
    Test.assertEqual(1, metrics.lapHits());
    Test.assert(session.lastError() != null);
    fit.fields[4].failWrite = false;
    Test.assert(session.lap(1200));
    Test.assertEqual(1, session.lastLap()[:hits]);
    return true;
}

(:test)
function failedSaveFreezesMetricsAtFirstFinishAttempt(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    Test.assert(session.start(Toybox.System.getTimer()));
    metrics.registerHit(500);
    fit.failSave = true;
    Test.assert(!session.finish());
    var frozen = session.metricTime(Toybox.System.getTimer());
    Test.assertEqual(frozen, session.metricTime(frozen + 60000));
    fit.failSave = false;
    Test.assert(session.finish());
    Test.assertEqual(frozen, session.metricTime(frozen + 60000));
    return true;
}
