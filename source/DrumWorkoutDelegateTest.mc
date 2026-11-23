import Toybox.Test;
import Toybox.WatchUi;

(:test)
class MenuTrackingDelegate extends DrumWorkoutDelegate {
    var menuOpened = false;
    function initialize(session) { DrumWorkoutDelegate.initialize(session); }
    function onMenu() { menuOpened = true; return true; }
    function onMetronomeMenu() { menuOpened = true; return true; }
}

(:test)
function metronomePageOpensMenuWithoutPausingOrStarting(logger) {
    var metrics = new DrumMetrics();
    var input = new FakeSensorInput();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), input, new FakeSessionMetronome(), metrics);
    var view = new DrumWorkoutView(session, metrics, input);
    var delegate = new MenuTrackingDelegate(session);
    delegate.setView(view);
    view.previousPage();
    Test.assert(delegate.onSelect());
    Test.assert(delegate.menuOpened);
    Test.assertEqual(:ready, session.state());
    delegate.menuOpened = false;
    Test.assert(session.start(0));
    Test.assert(delegate.onSelect());
    Test.assert(delegate.menuOpened);
    Test.assertEqual(:recording, session.state());
    return true;
}

(:test)
function pausedBackOpensSaveMenuWithoutFinishing(logger) {
    var fit = new FakeRecordingSession();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), new DrumMetrics());
    var delegate = new MenuTrackingDelegate(session);
    Test.assert(session.start(0));
    Test.assert(session.pause());
    Test.assert(delegate.onBack());
    Test.assert(delegate.menuOpened);
    Test.assertEqual(:paused, session.state());
    Test.assert(!fit.saved);
    delegate.menuOpened = false;
    Test.assert(delegate.handleKey(WatchUi.KEY_LAP, 2000));
    Test.assert(delegate.menuOpened);
    return true;
}

(:test)
function controlsStartLapPauseResumeAndSave(logger) {
    var fit = new FakeRecordingSession();
    var metrics = new DrumMetrics();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), metrics);
    var delegate = new DrumWorkoutDelegate(session);
    Test.assert(!delegate.handleKey(WatchUi.KEY_LAP, 0));
    Test.assertEqual(0, fit.lapValues.size());
    Test.assert(delegate.handleKey(WatchUi.KEY_START, 0));
    Test.assertEqual(:recording, session.state());
    metrics.registerHit(500);
    Test.assert(delegate.handleKey(WatchUi.KEY_LAP, 1000));
    Test.assertEqual(1, fit.lapValues.size());
    Test.assert(delegate.handleKey(WatchUi.KEY_START, 1000));
    Test.assertEqual(:paused, session.state());
    Test.assert(delegate.handleKey(WatchUi.KEY_START, 2000));
    Test.assertEqual(:recording, session.state());
    Test.assert(delegate.handleAction(:save));
    Test.assertEqual(:saved, session.state());
    return true;
}

(:test)
function failedSaveIsAvailableForRetry(logger) {
    var fit = new FakeRecordingSession();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), new DrumMetrics());
    var delegate = new DrumWorkoutDelegate(session);
    delegate.handleKey(WatchUi.KEY_START, 0);
    fit.failSave = true;
    Test.assert(delegate.handleAction(:save));
    Test.assertEqual(:saveError, session.state());
    fit.failSave = false;
    Test.assert(delegate.handleAction(:save));
    Test.assertEqual(:saved, session.state());
    return true;
}

(:test)
function backCanExitOnlyAfterSuccessfulSave(logger) {
    var fit = new FakeRecordingSession();
    var session = new DrumSession(new ActivityRecorder(fit), new FakeSensorInput(), new FakeSessionMetronome(), new DrumMetrics());
    var delegate = new MenuTrackingDelegate(session);
    Test.assert(!delegate.onBack());
    Test.assert(session.start(0));
    Test.assert(delegate.onBack());
    fit.failSave = true;
    Test.assert(!session.finish());
    Test.assert(delegate.onBack());
    Test.assert(delegate.menuOpened);
    fit.failSave = false;
    Test.assert(session.finish());
    Test.assert(!delegate.onBack());
    Test.assert(!delegate.handleKey(WatchUi.KEY_LAP, 3000));
    return true;
}

(:test)
function tempoPickerUpdatesMenuSubtitleAfterAccept(logger) {
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), new FakeSensorInput(), new FakeSessionMetronome(), new DrumMetrics());
    Test.assert(session.setMetronome(120));
    var item = new WatchUi.MenuItem("Set tempo", "120 BPM", :tempo, null);
    var delegate = new DrumTempoDelegate(session, item);
    Test.assert(delegate.applyTempo(130));
    Test.assertEqual(130, session.metronomeBpm());
    Test.assertEqual("130 BPM", item.getSubLabel());
    return true;
}

(:test)
function failedTempoRestartDoesNotReopenPickerWithNullTempo(logger) {
    var metro = new FakeSessionMetronome();
    var session = new DrumSession(new ActivityRecorder(new FakeRecordingSession()), new FakeSensorInput(), metro, new DrumMetrics());
    Test.assert(session.setMetronome(120));
    Test.assert(session.start(0));
    metro.failStart = true;
    var item = new WatchUi.MenuItem("Set tempo", "120 BPM", :tempo, null);
    Test.assert(!new DrumTempoDelegate(session, item).applyTempo(130));
    Test.assert(session.metronomeBpm() == null);
    Test.assert(session.lastError() != null);
    return true;
}
