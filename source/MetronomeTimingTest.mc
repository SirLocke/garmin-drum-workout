import Toybox.Test;

(:test)
function metronomePeriodValidatesTempo(logger) {
    var timing = new MetronomeTiming();
    Test.assertEqual(1000, timing.periodMs(60));
    Test.assertEqual(500, timing.periodMs(120));
    Test.assert(timing.periodMs(39) == null);
    Test.assert(timing.periodMs(181) == null);
    return true;
}
