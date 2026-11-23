import Toybox.Test;

(:test)
function batchForwardsTimestampedHits(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    var input = new AccelerometerInput(new HitDetector(350, 180), metrics);
    Test.assert(input.processBatch(
        [0, 40, 80, 120, 160, 240],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [1000, 1500, 1500, 1000, 1000, 1500]));
    Test.assertEqual(2, metrics.totalHits());
    return true;
}

(:test)
function rejectsMisalignedBatchWithoutCounting(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    var input = new AccelerometerInput(new HitDetector(350, 180), metrics);
    Test.assert(!input.processBatch([0, 40], [0], [0, 0], [1000, 1500]));
    Test.assertEqual(0, metrics.totalHits());
    return true;
}

(:test)
function rejectsOutOfOrderTimestampsAtomically(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    var input = new AccelerometerInput(new HitDetector(350, 180), metrics);
    Test.assert(!input.processBatch([0, 40, 20], [0, 0, 0], [0, 0, 0], [1000, 1500, 1000]));
    Test.assertEqual(0, metrics.totalHits());
    Test.assert(input.processBatch([0, 40], [0, 0], [0, 0], [1000, 1500]));
    Test.assert(!input.processBatch([40, 80], [0, 0], [0, 0], [1000, 1500]));
    Test.assertEqual(1, metrics.totalHits());
    return true;
}

(:test)
function unavailableSensorDataIsReported(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    var input = new AccelerometerInput(new HitDetector(350, 180), metrics);
    Test.assert(!input.processBatch(null, [0], [0], [1000]));
    Test.assert(input.lastError() != null);
    Test.assertEqual(0, metrics.totalHits());
    return true;
}

(:test)
function repeatedBatchTimestampUsesSampleRateForHitIntervals(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    var input = new AccelerometerInput(new HitDetector(350, 180), metrics);
    Test.assert(input.processBatch(
        [1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000],
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
        [1000, 1500, 1500, 1000, 1000, 1000, 1000, 1500]));
    Test.assertEqual(2, metrics.totalHits());
    Test.assert(input.processBatch([2000, 2000], [0, 0], [0, 0], [1500, 1500]));
    return true;
}

(:test)
function partiallyRepeatedTimestampsAreRejected(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    var input = new AccelerometerInput(new HitDetector(350, 180), metrics);
    Test.assert(!input.processBatch([1000, 1000, 1040], [0, 0, 0], [0, 0, 0], [1000, 1500, 1000]));
    Test.assertEqual(0, metrics.totalHits());
    return true;
}

(:test)
function resetAcceptsNewSensorClockWithoutCountingAFalseHit(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    var input = new AccelerometerInput(new HitDetector(350, 180), metrics);
    Test.assert(input.processBatch([1000, 1040], [0, 0], [0, 0], [1000, 1500]));
    Test.assertEqual(1, metrics.totalHits());
    input.reset();
    Test.assert(input.processBatch([0, 40], [0, 0], [0, 0], [1000, 1000]));
    Test.assertEqual(1, metrics.totalHits());
    return true;
}

(:test)
function simulatorRegistersAndUnregistersAccelerometer(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    var input = new AccelerometerInput(new HitDetector(350, 180), metrics);
    input.start();
    input.stop();
    return true;
}

(:test)
function missingBatchBreaksDetectionAndIntervalSequence(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    var input = new AccelerometerInput(new HitDetector(350, 180), metrics);
    Test.assert(input.processBatch(
        [0, 40, 240, 280, 480, 520],
        [0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0],
        [1000, 1500, 1500, 1000, 1000, 1500]));
    Test.assertEqual(3, metrics.totalHits());
    Test.assert(!input.processBatch(null, [0], [0], [1000]));
    Test.assert(input.processBatch([1000, 1040], [0, 0], [0, 0], [1000, 1000]));
    Test.assertEqual(3, metrics.totalHits());
    Test.assert(input.processBatch([1080], [0], [0], [1500]));
    Test.assertEqual(4, metrics.totalHits());
    Test.assert(metrics.sessionTempoBpm() == null);
    return true;
}

(:test)
function emptySensorBatchReportsMissingSamples(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    var input = new AccelerometerInput(new HitDetector(350, 180), metrics);
    Test.assert(!input.processBatch([], [], [], []));
    Test.assert(input.lastError() != null);
    return true;
}

(:test)
function sensorGapRemainsVisibleAfterRecoveryAndReset(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    var input = new AccelerometerInput(new HitDetector(350, 180), metrics);
    Test.assert(!input.hadDataGap());
    Test.assert(!input.processBatch([], [], [], []));
    Test.assert(input.hadDataGap());
    Test.assert(input.processBatch([0], [0], [0], [1000]));
    Test.assert(input.lastError() == null);
    Test.assert(input.hadDataGap());
    input.reset();
    Test.assert(input.hadDataGap());
    return true;
}

(:test)
function missingTimestampRangeWarnsAndBreaksDetectionSequence(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    var input = new AccelerometerInput(new HitDetector(350, 180), metrics);
    Test.assert(input.processBatch([0, 40], [0, 0], [0, 0], [1000, 1500]));
    Test.assert(input.processBatch([2080, 2120], [0, 0], [0, 0], [1000, 1000]));
    Test.assert(input.hadDataGap());
    Test.assertEqual(1, metrics.totalHits());
    return true;
}

(:test)
function recentHitUsesDeviceClockRatherThanSensorClock(logger) {
    var metrics = new DrumMetrics();
    metrics.begin(0);
    var input = new AccelerometerInput(new HitDetector(350, 180), metrics);
    Test.assert(input.processBatch([1000, 1040], [0, 0], [0, 0], [1000, 1500]));
    var now = Toybox.System.getTimer();
    Test.assert(input.hasRecentHit(now));
    Test.assert(!input.hasRecentHit(now + 3001));
    input.reset();
    Test.assert(!input.hasRecentHit(now));
    return true;
}
