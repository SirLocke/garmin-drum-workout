class MetronomeTiming {
    function initialize() {}
    function periodMs(bpm) {
        return bpm >= 40 && bpm <= 180 ? 60000 / bpm : null;
    }
}
