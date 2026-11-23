import Toybox.Test;

(:test)
class FakeMetronomeTimer {
    var started = false;
    var period = 0;
    function start(callback, periodMs, repeat) { started = repeat; period = periodMs; }
    function stop() { started = false; }
}

(:test)
class FakeVibrationOutput {
    var pulses = 0;
    function pulse() { pulses += 1; }
}

(:test)
function metronomeStartsAndStopsPulses(logger) {
    var timer = new FakeMetronomeTimer();
    var output = new FakeVibrationOutput();
    var metronome = new Metronome(timer, output);
    Test.assert(metronome.start(120));
    Test.assertEqual(500, timer.period);
    Test.assert(timer.started);
    metronome.onTick();
    Test.assertEqual(1, output.pulses);
    metronome.stop();
    metronome.onTick();
    Test.assert(!timer.started);
    Test.assert(!metronome.isEnabled());
    Test.assertEqual(1, output.pulses);
    return true;
}

(:test)
function invalidMetronomeTempoIsReported(logger) {
    var metronome = new Metronome(new FakeMetronomeTimer(), new FakeVibrationOutput());
    Test.assert(!metronome.start(0));
    Test.assert(metronome.lastError() != null);
    Test.assert(!metronome.isEnabled());
    return true;
}
