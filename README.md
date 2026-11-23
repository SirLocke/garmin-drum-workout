# Drum Workout

Connect IQ watch app for Garmin Forerunner 255. This project is experimental:
the stroke detection still needs a measured drumming test on a watch.

The detector thresholds and 25 Hz sampling approach require validation on the
watch against manually counted strokes. A single wrist cannot measure all
strokes of both hands and feet. Interval-based tempo and regularity describe
detected strokes, not synchronization with a song.

Development has used Connect IQ SDK 9.3.0 and Java 21. Install the SDK and the
Forerunner 255 (`fr255`) device profile. Put the SDK
`bin` directory and Java on `PATH` and set `CONNECTIQ_KEY` to the path of your
private developer signing key. Keep and securely back up the original key
outside this repository; updates to an app require the same signing key.

Build the app:

```sh
mkdir -p build
monkeyc -d fr255 -f monkey.jungle -o build/drum-workout.prg -y "$CONNECTIQ_KEY"
```

Start the Connect IQ simulator and wait until it is ready, then run
`monkeydo build/drum-workout.prg fr255`. Run the unit tests with
`scripts/test.sh` while the simulator is running. The test script checks the
Run No Evil summary because SDK 9.3.0 can return exit code 1 after passing tests.
The tests create a synthetic FIT recording in the simulator. Restart the
simulator after running them and before manually testing a recording; otherwise
test lap data can leak into the next simulated activity.

## Controls

- Press START to begin, pause, or resume on the workout pages.
- From the live page, press UP to reach the metronome page. Press START
  (`SET`) there to turn the metronome on or off or set its tempo; START
  controls the metronome rather than the workout while on that page.
- Before starting, press BACK to exit.
- Press BACK (`NEXT`) while recording to start the next numbered song immediately.
  UP and DOWN navigate the four pages: live strokes and beat, current workout
  details, the previous song summary, and the metronome.
- While paused, press BACK to open the menu, then select **Stop and save** or
  **Resume**. If saving fails, BACK or START opens the retry menu.
- Use the action menu to pause, resume, stop and save, or toggle the
  metronome. When enabled, its tempo can be set from 40 to 180 BPM.
- After a save error, the recording remains open in the running app; use START
  and choose **Retry save**. If the operating system stops the app, it attempts
  to save, but a failed save at shutdown cannot be retried from that screen.
- After successful saving, press BACK to leave the app. A `SENSOR GAP` warning
  remains visible after sensor data recovers and after saving: stroke counts
  and estimates can be incomplete. It resets when a new app session starts.

Pausing stops the FIT timer and excludes paused time from the displayed
duration and song average. `Avg` is detected strokes divided by active song
time, expressed in strokes per minute. `Beat~/2` is an
experimental tempo estimate that assumes two detected strokes per beat for
even strokes, or looks for repeated shorter and longer subdivisions. This
assumption can halve the true tempo if the strokes are quarter notes; the
displayed BPM is not a measurement of song tempo. Too few or inconsistent
intervals show `--`. It resets on a new song, sensor interruption, or a gap
longer than two seconds. A single wrist cannot reliably determine the musical
beat. The live beat display clears after three seconds without a detected hit;
the last available estimate is retained for the song summary.
`Evenness` describes how similar recent stroke intervals are, not how well
the player follows a song; it is shown live and for the previous song.

The FIT recording submits lap and total stroke counts and, when available,
average lap and session stroke rates and lap beat estimates. A
session beat estimate is stored only for a single-song activity. Average stroke rates use
active time and include rests within a song. Missing lap estimates
use FIT's invalid uint16 value; a simulator FIT file decoded it as missing
after a valid lap. New recordings use the cardio training activity type to
avoid strength-training exercises and sets in Garmin Connect. Garmin controls
the exact display, which remains unverified for this activity type.
Real-watch FIT contents and Garmin Connect display still
need verification. Connect may
require installation through the Connect IQ Store, including a private beta,
for developer fields to appear; USB sideloading alone may not be sufficient.
Garmin Connect may still show its standard distance fields.

Connect IQ cannot automatically disable the watch's system-wide step
tracking. If manually disabled, it affects other activity tracking too and
must be re-enabled manually.

A simulator does not replace a real-watch test of sensor sampling, vibration,
FIT saving, lap handling, or Garmin Connect synchronization. The
`fr255m`, `fr255s`, and `fr255sm` variants are distinct device IDs and are not
included in the current manifest.

The accelerometer timestamp API requires Connect IQ 5.1.1 or later. Both SDK
9.3.0's simulator and an FR255 diagnostic showed the same timestamp for all 25
samples in each one-second batch, with a different origin from
`System.getTimer()`. For these batches the adapter estimates sample times at
40 ms intervals, based on the requested 25 Hz sampling rate; it rejects other
non-increasing timestamp patterns. A lap is recorded immediately when
requested; buffered strokes near its boundary may be counted in the following
lap. Stopping or pausing can also discard samples that have not yet been
delivered. Missing timestamp ranges longer than one second show a sensor-gap
warning, but cannot recover the missing strokes. FIT field persistence and Garmin Connect visibility, real-watch controls,
metronome vibration, and real-world accuracy remain to be verified.
