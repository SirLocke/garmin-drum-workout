import Toybox.Test;
import Toybox.Graphics;

(:test)
class FakeDisplay {
    var lines = [];
    var positions = [];
    var fonts = [];
    var xs = [];
    var linesDrawn = 0;
    function setColor(foreground, background) {}
    function clear() { lines = []; positions = []; fonts = []; xs = []; linesDrawn = 0; }
    function getWidth() { return 218; }
    function getHeight() { return 218; }
    function getTextWidthInPixels(text, font) { return text.length() * 7; }
    function drawText(x, y, font, text, justification) { lines.add(text); positions.add(y); fonts.add(font); xs.add(x); }
    function drawLine(x1, y1, x2, y2) { linesDrawn += 1; }
}

(:test)
function liveViewShowsAverageStrokesPerMinute(logger) {
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), input, new FakeSessionMetronome(), metrics);
    var view = new DrumWorkoutView(session, metrics, input);
    var display = new FakeDisplay();
    Test.assert(session.start(Toybox.System.getTimer() - 60000));
    for (var i = 0; i < 60; i += 1) { metrics.registerHit(i * 200); }
    Test.assert(session.pause());
    view.render(display);
    Test.assert(display.lines.indexOf("Strokes: 60") >= 0);
    Test.assert(display.lines.indexOf("Avg: 60 SPM") >= 0);
    return true;
}

(:test)
function liveRowsHaveBreathingRoomAndSavedViewShowsExit(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(fit), input, new FakeSessionMetronome(), metrics);
    var view = new DrumWorkoutView(session, metrics, input);
    var display = new FakeDisplay();
    Test.assert(session.start(0));
    view.render(display);
    for (var i = 1; i < 5; i += 1) {
        Test.assert(display.positions[i] - display.positions[i - 1] >= 26);
    }
    Test.assert(session.finish());
    view.render(display);
    Test.assert(display.lines.indexOf("BACK") >= 0);
    return true;
}

(:test)
function liveViewShowsCountsAndUnavailableEstimate(logger) {
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), input, new FakeSessionMetronome(), metrics);
    var view = new DrumWorkoutView(session, metrics, input);
    var display = new FakeDisplay();
    Test.assert(session.start(Toybox.System.getTimer() - 60000));
    metrics.registerHit(500);
    view.render(display);
    var song = display.lines.indexOf("Song 1");
    var strokes = display.lines.indexOf("Strokes: 1");
    Test.assert(song >= 0 && strokes == song + 1);
    Test.assert(display.positions[strokes] > display.positions[song]);
    Test.assert(display.lines.indexOf("Avg: 1 SPM") >= 0);
    Test.assert(display.lines.indexOf("Beat~/2: -- BPM") >= 0);
    Test.assert(display.lines.indexOf("NEXT") >= 0);
    Test.assert(display.fonts[1] != display.fonts[0]);
    Test.assertEqual(Graphics.FONT_XTINY, display.fonts[0]);
    Test.assert(display.xs[0] < display.getWidth() / 2);
    return true;
}

(:test)
function liveViewSeparatesStrokeAndBeatEstimates(logger) {
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), input, new FakeSessionMetronome(), metrics);
    var view = new DrumWorkoutView(session, metrics, input);
    var display = new FakeDisplay();
    Test.assert(session.start(Toybox.System.getTimer() - 10000));
    metrics.registerHit(0);
    for (var i = 0; i < 3; i += 1) {
        metrics.registerHit(250 + i * 1000);
        metrics.registerHit(500 + i * 1000);
        metrics.registerHit(1000 + i * 1000);
    }
    view.render(display);
    Test.assert(display.lines.indexOf("Avg: 60 SPM") >= 0);
    Test.assert(display.lines.indexOf("Beat~/2: 120 BPM") >= 0);
    return true;
}

(:test)
function liveBeatDisappearsAfterPlayingStopsWithoutLosingSongEstimate(logger) {
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), input, new FakeSessionMetronome(), metrics);
    var view = new DrumWorkoutView(session, metrics, input);
    var display = new FakeDisplay();
    Test.assert(session.start(0));
    metrics.registerHit(0);
    metrics.registerHit(250);
    metrics.registerHit(500);
    metrics.registerHit(750);
    view.render(display);
    Test.assert(display.lines.indexOf("Beat~/2: 120 BPM") >= 0);
    input.recentHit = false;
    view.render(display);
    Test.assert(display.lines.indexOf("Beat~/2: -- BPM") >= 0);
    Test.assertEqual(120.0, session.beatEstimate());
    return true;
}

(:test)
function detailsShowCurrentMetronomeAndPreviousSong(logger) {
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), input, new FakeSessionMetronome(), metrics);
    var view = new DrumWorkoutView(session, metrics, input);
    var display = new FakeDisplay();
    Test.assert(session.setMetronome(120));
    Test.assert(session.start(0));
    metrics.registerHit(500);
    Test.assert(session.lap(1000));
    view.nextPage();
    view.render(display);
    Test.assert(display.lines.indexOf("Metro: 120 BPM") >= 0);
    Test.assert(display.lines.indexOf("Total: 1") >= 0);
    view.nextPage();
    view.render(display);
    Test.assert(display.lines.indexOf("Last: 1  Evenness: --%") >= 0);
    Test.assert(display.lines.indexOf("Beat~/2: -- BPM") >= 0);
    return true;
}

(:test)
function readyViewDoesNotShowAnAverageBeforeStart(logger) {
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), input, new FakeSessionMetronome(), metrics);
    var view = new DrumWorkoutView(session, metrics, input);
    var display = new FakeDisplay();
    view.nextPage();
    view.render(display);
    Test.assert(display.lines.indexOf("Song avg: -- SPM") >= 0);
    return true;
}

(:test)
function viewShowsSaveFailureAndRetryInstruction(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(fit), input, new FakeSessionMetronome(), metrics);
    var view = new DrumWorkoutView(session, metrics, input);
    var display = new FakeDisplay();
    Test.assert(session.start(0));
    fit.failSave = true;
    Test.assert(!session.finish());
    view.render(display);
    Test.assert(display.lines.indexOf("Save required") >= 0);
    Test.assert(display.lines.indexOf("START: save menu") >= 0);
    return true;
}

(:test)
function lapFailureShowsCorrectRetryControl(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(fit), input, new FakeSessionMetronome(), metrics);
    var view = new DrumWorkoutView(session, metrics, input);
    var display = new FakeDisplay();
    Test.assert(session.start(0));
    fit.failLap = true;
    Test.assert(!session.lap(1000));
    view.render(display);
    Test.assert(display.lines.indexOf("NEXT: retry song") >= 0);
    Test.assert(session.pause());
    view.render(display);
    Test.assert(display.lines.indexOf("START: resume") >= 0);
    fit.failLap = false;
    Test.assert(session.resume());
    view.render(display);
    Test.assert(display.lines.indexOf("NEXT: retry song") >= 0);
    Test.assert(session.lap(1200));
    view.render(display);
    Test.assert(display.lines.indexOf("Song 2") >= 0);
    Test.assert(display.lines.indexOf("Strokes: 0") >= 0);
    return true;
}

(:test)
function gapWarningIsVisibleOnEveryPageIncludingAfterSave(logger) {
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), input, new FakeSessionMetronome(), metrics);
    var view = new DrumWorkoutView(session, metrics, input);
    var display = new FakeDisplay();
    Test.assert(session.start(0));
    input.gap = true;
    for (var i = 0; i < 4; i += 1) {
        view.render(display);
        Test.assert(display.lines.indexOf("SENSOR GAP") >= 0);
        Test.assert(display.lines.indexOf("NEXT") >= 0);
        view.nextPage();
    }
    Test.assert(session.pause());
    view.render(display);
    Test.assertEqual("SENSOR GAP", display.lines[0]);
    Test.assert(display.lines.indexOf("SAVE") >= 0);
    Test.assert(session.resume());
    Test.assert(session.finish());
    for (var i = 0; i < 4; i += 1) {
        view.render(display);
        Test.assertEqual("SAVED SENSOR GAP", display.lines[0]);
        Test.assert(display.lines.indexOf("BACK") >= 0);
        view.nextPage();
    }
    return true;
}

(:test)
function detailsExplainEvennessInCurrentAndPreviousSong(logger) {
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), input, new FakeSessionMetronome(), metrics);
    var view = new DrumWorkoutView(session, metrics, input);
    var display = new FakeDisplay();
    Test.assert(session.start(0));
    metrics.registerHit(500);
    metrics.registerHit(1000);
    metrics.registerHit(1500);
    metrics.registerHit(2000);
    view.nextPage();
    view.render(display);
    Test.assert(display.lines.indexOf("Evenness: 100%") >= 0);
    Test.assert(session.lap(2200));
    view.nextPage();
    view.render(display);
    Test.assert(display.lines.indexOf("Last: 4  Evenness: 100%") >= 0);
    return true;
}

(:test)
function navigationUsesButtonLabelsAndDownIndicator(logger) {
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), input, new FakeSessionMetronome(), metrics);
    var view = new DrumWorkoutView(session, metrics, input);
    var display = new FakeDisplay();
    view.render(display);
    Test.assert(display.lines.indexOf("UP/DOWN: pages") < 0);
    var start = display.lines.indexOf("START");
    Test.assert(start >= 0);
    Test.assert(display.xs[start] > display.getWidth() / 2);
    Test.assert(display.positions[start] <= 45);
    Test.assert(display.linesDrawn >= 2);
    var metro = display.lines.indexOf("METRO");
    var up = display.lines.indexOf("UP");
    Test.assert(metro >= 0 && up >= 0);
    Test.assert(display.positions[metro] - display.positions[up] >= 16);
    return true;
}

(:test)
function previousPageCyclesBackwardThroughAllPages(logger) {
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), input, new FakeSessionMetronome(), metrics);
    var view = new DrumWorkoutView(session, metrics, input);
    var delegate = new DrumWorkoutDelegate(session);
    delegate.setView(view);
    var display = new FakeDisplay();
    Test.assert(delegate.onPreviousPage());
    view.render(display);
    Test.assert(display.lines.indexOf("Metronome") >= 0);
    Test.assert(display.lines.indexOf("SET") >= 0);
    Test.assert(delegate.onPreviousPage());
    view.render(display);
    Test.assert(display.lines.indexOf("No completed song") >= 0);
    Test.assert(delegate.onPreviousPage());
    view.render(display);
    Test.assert(display.lines.indexOf("Total: 0") >= 0);
    Test.assert(delegate.onNextPage());
    view.render(display);
    Test.assert(display.lines.indexOf("No completed song") >= 0);
    return true;
}
