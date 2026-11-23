import Toybox.Attention;

class VibrationOutput {
    function initialize() {}
    function pulse() {
        Attention.vibrate([new Attention.VibeProfile(50, 100)]);
    }
}
