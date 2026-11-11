import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class NimRunView extends WatchUi.DataField {
    private const METERS_PER_KM = 1000.0;
    private const METERS_PER_MILE = 1609.344;
    // Below this speed (m/s) pace is meaningless, so it shows as blank.
    private const MIN_PACE_SPEED = 0.3;
    // Seconds of speed averaged into the pace.
    private const PACE_SAMPLES = 5;

    // Largest first; the biggest one that still fits the field wins.
    private const TIME_FONTS = [
        Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD,
        Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL
    ] as Array<FontType>;

    private var _decimalSeparator as String;
    private var _time as String = "0:00";
    private var _distance as String = "";
    private var _pace as String = "";
    private var _speeds as Array<Float> = [] as Array<Float>;

    // Workout state: timer value when the current step began, and what the step shows.
    private var _timerMs as Number = 0;
    private var _stepStartMs as Number = 0;
    private var _stepRemaining as String? = null;
    private var _offTargetPace as Boolean = false;

    function initialize() {
        DataField.initialize();
        _decimalSeparator = WatchUi.loadResource(Rez.Strings.DecimalSeparator) as String;
        _distance = formatDistance(0.0);
        _pace = formatPace(null);
    }

    function compute(info as Activity.Info) as Void {
        var timer = info.timerTime;
        _timerMs = timer != null ? timer : 0;
        _time = formatDuration(_timerMs / 1000);

        var meters = info.elapsedDistance;
        _distance = formatDistance(meters != null ? meters : 0.0);
        var speed = smoothedSpeed(info.currentSpeed);
        _pace = formatPace(speed);
        computeWorkout(speed);
    }

    function onWorkoutStarted() as Void {
        _stepStartMs = _timerMs;
    }

    function onWorkoutStepComplete() as Void {
        _stepStartMs = _timerMs;
    }

    function onTimerReset() as Void {
        _stepStartMs = 0;
    }

    // During a timed workout step (Garmin Coach, scheduled workouts) the main line counts
    // down the step, and pace turns orange when it leaves the step's target range.
    private function computeWorkout(speed as Float?) as Void {
        _stepRemaining = null;
        _offTargetPace = false;
        var step = currentWorkoutStep();
        if (step == null) {
            return;
        }

        // durationValue is undocumented; time steps are reported in seconds.
        var duration = step.durationValue;
        if (step.durationType == Activity.WORKOUT_STEP_DURATION_TIME && duration != null) {
            var remaining = duration.toNumber() - (_timerMs - _stepStartMs) / 1000;
            _stepRemaining = formatDuration(remaining > 0 ? remaining : 0);
        }

        // Speed targets are in m/s, low to high.
        var low = step.targetValueLow;
        var high = step.targetValueHigh;
        if (step.targetType == Activity.WORKOUT_STEP_TARGET_SPEED && low != null && high != null
                && high > low && speed != null && speed >= MIN_PACE_SPEED) {
            _offTargetPace = speed < low || speed > high;
        }
    }

    private function currentWorkoutStep() as Activity.WorkoutStep? {
        if (!(Activity has :getCurrentWorkoutStep)) {
            return null;
        }
        var info = Activity.getCurrentWorkoutStep();
        if (info == null) {
            return null;
        }
        var step = info.step;
        if (step instanceof Activity.WorkoutIntervalStep) {
            var resting = info.intensity == Activity.WORKOUT_INTENSITY_REST
                || info.intensity == Activity.WORKOUT_INTENSITY_RECOVERY;
            return resting ? step.restStep : step.activeStep;
        }
        return step as Activity.WorkoutStep;
    }

    // Moving average of the last few speed samples (compute runs once per second),
    // since instantaneous GPS speed makes pace jump around.
    private function smoothedSpeed(speed as Float?) as Float? {
        if (speed == null) {
            _speeds = [] as Array<Float>;
            return null;
        }
        _speeds.add(speed);
        if (_speeds.size() > PACE_SAMPLES) {
            _speeds = _speeds.slice(1, null);
        }
        var sum = 0.0;
        for (var i = 0; i < _speeds.size(); i++) {
            sum += _speeds[i];
        }
        return sum / _speeds.size();
    }

    function onUpdate(dc as Dc) as Void {
        NimStyle.clear(dc);
        NimStyle.drawLines(dc, fittingLines(dc), 0, 0);
    }

    // Small fields drop the last line, then the second, before shrinking the main line below its smallest font.
    private function fittingLines(dc as Dc) as Array<Array> {
        var lines = [] as Array<Array>;
        for (var count = 3; count >= 1; count--) {
            for (var i = 0; i < TIME_FONTS.size(); i++) {
                lines = buildLines(count, TIME_FONTS[i]);
                if (NimStyle.fits(dc, lines, getObscurityFlags())) {
                    return lines;
                }
            }
        }
        return lines;
    }

    // Running: time, distance, pace. Timed workout step: time left, pace, distance.
    private function buildLines(count as Number, timeFont as FontType) as Array<Array> {
        var lines = [] as Array<Array>;
        if (_stepRemaining != null) {
            var paceColor = _offTargetPace ? NimStyle.COLOR_ALERT : NimStyle.COLOR_SECONDARY;
            lines.add([_stepRemaining, timeFont, NimStyle.COLOR_PRIMARY]);
            lines.add([_pace, NimStyle.FONT_SMALL, paceColor]);
            lines.add([_distance, NimStyle.FONT_SMALL, NimStyle.COLOR_TERTIARY]);
        } else {
            lines.add([_time, timeFont, NimStyle.COLOR_PRIMARY]);
            lines.add([_distance, NimStyle.FONT_SMALL, NimStyle.COLOR_SECONDARY]);
            lines.add([_pace, NimStyle.FONT_SMALL, NimStyle.COLOR_TERTIARY]);
        }
        return lines.slice(0, count);
    }

    // 42:18, or 1:02:03 past an hour.
    private function formatDuration(totalSeconds as Number) as String {
        var hours = totalSeconds / 3600;
        var minutes = (totalSeconds / 60) % 60;
        var seconds = totalSeconds % 60;
        if (hours > 0) {
            return hours.toString() + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
        }
        return minutes.toString() + ":" + seconds.format("%02d");
    }

    // 6.2 km (6,2 km in Portuguese). Truncated, like Garmin's own distance field.
    private function formatDistance(meters as Float) as String {
        var metric = System.getDeviceSettings().distanceUnits == System.UNIT_METRIC;
        var tenths = (meters / (metric ? METERS_PER_KM : METERS_PER_MILE) * 10).toNumber();
        return (tenths / 10).toString() + _decimalSeparator + (tenths % 10).toString()
            + (metric ? " km" : " mi");
    }

    // 6:49 /km, or -:-- while standing still.
    private function formatPace(speed as Float?) as String {
        var metric = System.getDeviceSettings().paceUnits == System.UNIT_METRIC;
        var suffix = metric ? " /km" : " /mi";
        if (speed == null || speed < MIN_PACE_SPEED) {
            return "-:--" + suffix;
        }
        var seconds = ((metric ? METERS_PER_KM : METERS_PER_MILE) / speed).toNumber();
        if (seconds >= 3600) {
            return "-:--" + suffix;
        }
        return (seconds / 60).toString() + ":" + (seconds % 60).format("%02d") + suffix;
    }
}
