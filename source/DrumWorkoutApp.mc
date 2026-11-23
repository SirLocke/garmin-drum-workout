import Toybox.Application;
import Toybox.System;
import Toybox.Timer;

class DrumWorkoutApp extends Application.AppBase {
    private var _session;
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var metrics = new DrumMetrics();
        var input = new AccelerometerInput(new HitDetector(350, 180), metrics);
        var metronome = new Metronome(new Timer.Timer(), new VibrationOutput());
        _session = new DrumSession(new ActivityRecorder(null), input, metronome, metrics);
        var view = new DrumWorkoutView(_session, metrics, input);
        var delegate = new DrumWorkoutDelegate(_session);
        delegate.setView(view);
        return [view, delegate];
    }

    function onStop(state) {
        if (_session != null && (_session.state() == :recording ||
            _session.state() == :paused || _session.state() == :saveError)) {
            if (!_session.finish()) {
                System.println("Unable to save recording on exit: " + _session.lastError());
            }
        }
    }
}
