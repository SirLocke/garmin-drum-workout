import Toybox.Test;

(:test)
function detectsImpactOnlyOnce(logger) {
    var detector = new HitDetector(350, 180);
    Test.assert(!detector.processSample(0, 0, 1000, 0));
    Test.assert(detector.processSample(0, 0, 1500, 40));
    Test.assert(!detector.processSample(0, 0, 1500, 80));
    return true;
}

(:test)
function ignoresImpactInsideRefractoryPeriod(logger) {
    var detector = new HitDetector(350, 180);
    detector.processSample(0, 0, 1000, 0);
    Test.assert(detector.processSample(0, 0, 1500, 40));
    detector.processSample(0, 0, 1500, 80);
    Test.assert(!detector.processSample(0, 0, 1000, 120));
    detector.processSample(0, 0, 1000, 160);
    Test.assert(detector.processSample(0, 0, 1500, 240));
    return true;
}

(:test)
function detectsLargeThreeAxisImpactWithoutIntegerOverflow(logger) {
    var detector = new HitDetector(350, 180);
    Test.assert(!detector.processSample(-16000, -16000, -16000, 0));
    Test.assert(detector.processSample(16000, 16000, 16000, 40));
    return true;
}
