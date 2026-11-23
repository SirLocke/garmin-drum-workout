import Toybox.Test;

(:test)
function totalHitsCountsRegisteredStrokes(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    metrics.registerHit(500);
    metrics.registerHit(1000);
    Test.assertEqual(2, metrics.totalHits());
    return true;
}

(:test)
function lapAverageAndReset(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    Test.assert(metrics.averageSpm(0) == null);
    Test.assertEqual(0.0, metrics.averageSpm(1000));
    metrics.registerHit(500);
    metrics.registerHit(1000);
    metrics.registerHit(1500);
    metrics.registerHit(2000);
    Test.assertEqual(4, metrics.lapHits());
    Test.assertEqual(120.0, metrics.averageSpm(2000));
    metrics.beginLap(3000);
    Test.assertEqual(4, metrics.totalHits());
    Test.assertEqual(0, metrics.lapHits());
    Test.assert(metrics.averageSpm(3000) == null);
    return true;
}

(:test)
function tempoRequiresFourHitsAndResetsForNewLap(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    metrics.registerHit(500);
    metrics.registerHit(1000);
    metrics.registerHit(1500);
    Test.assert(metrics.estimatedTempoBpm() == null);
    Test.assert(metrics.regularityPercent() == null);
    metrics.registerHit(2000);
    Test.assertEqual(120.0, metrics.estimatedTempoBpm());
    Test.assertEqual(100.0, metrics.regularityPercent());
    metrics.beginLap(3000);
    Test.assert(metrics.estimatedTempoBpm() == null);
    return true;
}

(:test)
function unevenIntervalsReduceRegularity(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    metrics.registerHit(500);
    metrics.registerHit(1000);
    metrics.registerHit(2000);
    metrics.registerHit(2500);
    Test.assertEqual(120.0, metrics.estimatedTempoBpm());
    Test.assert(metrics.regularityPercent() < 100.0);
    Test.assert(metrics.regularityPercent() > 0.0);
    return true;
}

(:test)
function sessionEstimateRetainsIntervalsWithoutCrossingLapOrPause(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    metrics.registerHit(500);
    metrics.registerHit(1000);
    metrics.registerHit(1500);
    Test.assert(metrics.sessionTempoBpm() == null);
    metrics.beginLap(10000);
    metrics.registerHit(10000);
    metrics.registerHit(10500);
    Test.assertEqual(120.0, metrics.sessionTempoBpm());
    metrics.breakSequence();
    metrics.registerHit(60000);
    metrics.registerHit(60500);
    Test.assertEqual(120.0, metrics.sessionTempoBpm());
    Test.assert(metrics.estimatedTempoBpm() == null);
    metrics.begin(70000);
    Test.assert(metrics.sessionTempoBpm() == null);
    return true;
}

(:test)
function sessionEstimateUsesRecentBoundedIntervals(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    var time = 0;
    metrics.registerHit(time);
    for (var i = 0; i < 80; i += 1) {
        time += i < 16 ? 1000 : 500;
        metrics.registerHit(time);
    }
    Test.assertEqual(120.0, metrics.sessionTempoBpm());
    return true;
}
