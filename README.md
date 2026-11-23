# Drum Workout

Experimental Garmin Connect IQ watch app for the Forerunner 255 (`fr255`). Tracks wrist-detected drum strokes, per-song laps, stroke rate, experimental beat and evenness estimates, a vibration metronome, and custom FIT activity fields.

> **Status:** Experimental. Stroke detection thresholds, 25 Hz accelerometer sampling, FIT field persistence, Garmin Connect display, metronome vibration, and real-watch controls still require validation on physical hardware.

## Features

- **Stroke detection:** 25 Hz wrist accelerometer sampling with real-time hit detection and sensor-gap warnings.
- **Song laps:** Start numbered songs on the fly while recording, with live metrics and previous-song summaries.
- **Live metrics:** Stroke count, active duration, average stroke rate (`Avg`), experimental tempo estimate (`Beat~/2`), and interval consistency (`Evenness`).
- **Vibration metronome:** Built-in metronome configurable from 40 to 180 BPM.
- **FIT recording:** Saves cardio training sessions with custom developer fields for lap/total strokes, average stroke rates, and beat estimates.

## Requirements

- Connect IQ SDK (developed with `9.3.0`)
- Java 21
- Forerunner 255 (`fr255`) device profile installed via SDK Manager
- Private Connect IQ developer signing key

Add the SDK `bin` directory and Java to `PATH`, and set `CONNECTIQ_KEY` to the path of your developer signing key. Keep and securely back up the original key outside this repository; app updates require the same signing key.

## Build and Test

Build the `.prg` binary:

```sh
mkdir -p build
monkeyc -d fr255 -f monkey.jungle -o build/drum-workout.prg -y "$CONNECTIQ_KEY"
```

Run in the Connect IQ simulator:

1. Start the Connect IQ simulator and wait until it is ready.
2. Load the app:
   ```sh
   monkeydo build/drum-workout.prg fr255
   ```

Run unit tests (with the simulator running):

```sh
scripts/test.sh
```

Notes on testing:
- `scripts/test.sh` checks the Run No Evil summary output directly because SDK 9.3.0 can return exit code `1` even when all tests pass.
- The test suite creates a synthetic FIT recording in the simulator. Restart the simulator after running tests and before manually testing a recording; otherwise test lap data can leak into the next simulated activity.

## Controls

- **START:** Begin, pause, or resume on the workout pages.
- **UP / DOWN:** Navigate the four pages:
  1. Live strokes and beat
  2. Current workout details
  3. Previous song summary
  4. Metronome
- **Metronome page (`UP` from live page):** Press **START** (`SET`) to toggle the metronome on/off or adjust its tempo (40–180 BPM). While on this page, **START** controls the metronome rather than the workout.
- **BACK:**
  - Before starting: exit the app.
  - While recording (`NEXT`): start the next numbered song immediately.
  - While paused: open the menu to choose **Stop and save** or **Resume**.
  - After a save error: **BACK** or **START** opens the retry menu.
  - After successful saving: leave the app.
- **Action menu:** Pause, resume, stop and save, or toggle the metronome.

### Save Error and Sensor Gap Handling

- After a save error, the recording remains open in the running app; press **START** and select **Retry save**. If the OS terminates the app, it attempts to save, but a failed shutdown save cannot be retried from that screen.
- A `SENSOR GAP` warning stays visible after sensor data recovers and after saving to indicate that stroke counts and estimates may be incomplete. It resets when a new app session starts.

## Metrics and Beat Estimation

- **Pausing:** Stops the FIT timer and excludes paused time from displayed duration and song averages.
- **`Avg`:** Detected strokes divided by active song time (strokes per minute), including rests within a song.
- **`Beat~/2`:** Experimental tempo estimate assuming two detected strokes per beat for even strokes, or looking for repeated shorter and longer subdivisions. This can halve the true tempo for quarter-note patterns; the displayed BPM is not a measurement of song tempo.
  - Shows `--` when intervals are too few or inconsistent.
  - Resets on a new song, sensor interruption, or a gap longer than two seconds.
  - Live beat display clears after three seconds without a detected hit; the last available estimate is kept for the song summary.
- **`Evenness`:** Describes how consistent recent stroke intervals are (not synchronization with a song). Shown live and for the previous song.

## FIT Recording and Garmin Connect

- Records lap and total stroke counts and, when available, average lap/session stroke rates and lap beat estimates.
- A session beat estimate is stored only for single-song activities.
- Missing lap estimates use FIT's invalid `uint16` value (decoded as missing in simulator FIT files after a valid lap).
- Uses the cardio training activity type to avoid strength-training exercises and sets in Garmin Connect.
- Garmin Connect display for developer fields and this activity type is unverified; developer fields may require installation via the Connect IQ Store (including a private beta) rather than USB sideloading alone. Garmin Connect may still display standard distance fields.

## Known Limitations

- **Single wrist limitation:** One wrist cannot capture all strokes across both hands and feet, nor reliably determine musical beat.
- **Detector calibration:** Thresholds and 25 Hz sampling need on-watch validation against manually counted strokes.
- **Device variants:** `fr255m`, `fr255s`, and `fr255sm` have distinct device IDs and are not yet included in `manifest.xml`.
- **Step tracking:** Connect IQ cannot automatically disable system-wide step tracking. Disabling it manually affects general activity tracking and must be re-enabled manually.
- **Accelerometer timestamps:** The timestamp API requires Connect IQ 5.1.1+. Both SDK 9.3.0's simulator and an FR255 diagnostic reported the same timestamp for all 25 samples in each 1-second batch (with a different origin than `System.getTimer()`). The adapter estimates sample times at 40 ms intervals based on the 25 Hz rate and rejects other non-increasing patterns.
- **Boundary buffering:** Laps are recorded immediately when requested; buffered strokes near a lap boundary may land in the following lap. Stopping or pausing can discard undelivered samples. Missing ranges longer than one second trigger the sensor-gap warning but cannot recover lost strokes.
- **Simulator vs. hardware:** Simulator tests do not replace real-watch verification of sensor sampling, vibration, FIT saving, lap handling, or Garmin Connect sync.
