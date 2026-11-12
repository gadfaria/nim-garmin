import Toybox.Activity;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Guided breathing: the current step as a word, the seconds left in it and the time
// left in the session. The word brightens while inhaling and darkens while exhaling,
// and a short buzz marks each step so it works with eyes closed.
// START pauses and resumes; BACK leaves.
class NimBreatheView extends WatchUi.View {
    // Fast enough for the word's shade to change smoothly.
    private const TICK_MS = 200;

    private var _steps as Array<Array<Number> >;
    private var _vibrate as Boolean;
    private var _phases as NimPhases;
    // The whole session as a single phase, paused and resumed with the steps.
    private var _session as NimPhases;
    private var _sessionMs as Number;
    private var _ticker as Timer.Timer = new Timer.Timer();
    private var _started as Boolean = false;
    private var _done as Boolean = false;
    private var _startHeartRate as Number? = null;
    private var _endHeartRate as Number? = null;

    function initialize(steps as Array<Array<Number> >, minutes as Number, vibrate as Boolean) {
        View.initialize();
        _steps = steps;
        _vibrate = vibrate;

        var durations = [] as Array<Number>;
        var cycleMs = 0;
        for (var i = 0; i < steps.size(); i++) {
            durations.add(steps[i][1] * 1000);
            cycleMs += steps[i][1] * 1000;
        }
        // Whole cycles only, so the session ends on the last exhale or hold.
        var cycles = (minutes * 60000 + cycleMs / 2) / cycleMs;
        _sessionMs = (cycles > 0 ? cycles : 1) * cycleMs;

        _phases = new NimPhases(durations);
        _session = new NimPhases([_sessionMs] as Array<Number>);
    }

    function onShow() as Void {
        if (_done) {
            return;
        }
        if (!_started) {
            _started = true;
            _startHeartRate = heartRate();
            cue();
        }
        resume();
    }

    function onHide() as Void {
        pause();
    }

    // Returns false once the session is over, when START should leave instead.
    function togglePause() as Boolean {
        if (_done) {
            return false;
        }
        if (_phases.isRunning()) {
            pause();
        } else {
            resume();
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onTick() as Void {
        if (_session.remainingMs() == 0) {
            finish();
        } else if (_phases.advance()) {
            cue();
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        NimStyle.clear(dc);
        if (_done) {
            drawDone(dc);
            return;
        }

        var paused = !_phases.isRunning();
        var kind = _steps[_phases.index()][0];
        NimStyle.drawLines(dc, [
            [word(kind), NimStyle.FONT_LARGE_TEXT, paused ? NimStyle.COLOR_SECONDARY : shade(kind)],
            [((_phases.remainingMs() + 999) / 1000).toString(), NimStyle.FONT_SMALL, NimStyle.COLOR_SECONDARY],
            [paused ? WatchUi.loadResource(Rez.Strings.Paused) as String : NimApp.formatClock(_session.remainingMs()),
                NimStyle.FONT_SMALL, NimStyle.COLOR_TERTIARY]
        ] as Array<Array>, 0, 0);
    }

    private function drawDone(dc as Dc) as Void {
        var lines = [
            [WatchUi.loadResource(Rez.Strings.Done) as String, NimStyle.FONT_LARGE_TEXT, NimStyle.COLOR_PRIMARY]
        ] as Array<Array>;
        var start = _startHeartRate;
        var end = _endHeartRate;
        if (start != null && end != null) {
            lines.add([start.toString() + " > " + end.toString(), NimStyle.FONT_SMALL, NimStyle.COLOR_SECONDARY]);
        }
        lines.add([NimApp.formatClock(_sessionMs), NimStyle.FONT_SMALL, NimStyle.COLOR_TERTIARY]);
        NimStyle.drawLines(dc, lines, 0, 0);
    }

    private function resume() as Void {
        _phases.resume();
        _session.resume();
        _ticker.stop();
        _ticker.start(method(:onTick), TICK_MS, true);
    }

    private function pause() as Void {
        _phases.pause();
        _session.pause();
        _ticker.stop();
    }

    private function finish() as Void {
        pause();
        _done = true;
        _endHeartRate = heartRate();
        buzz([new Attention.VibeProfile(100, 400)] as Array<Attention.VibeProfile>);
    }

    private function word(kind as Number) as String {
        if (kind == BREATH_INHALE) {
            return WatchUi.loadResource(Rez.Strings.Inhale) as String;
        } else if (kind == BREATH_EXHALE) {
            return WatchUi.loadResource(Rez.Strings.Exhale) as String;
        }
        return WatchUi.loadResource(Rez.Strings.Hold) as String;
    }

    // Gray between dimmed (lungs empty) and primary (lungs full).
    private function shade(kind as Number) as Number {
        var left = _phases.remainingMs().toFloat() / _phases.durationMs();
        var level = 0.0;
        if (kind == BREATH_INHALE) {
            level = 1.0 - left;
        } else if (kind == BREATH_HOLD_FULL) {
            level = 1.0;
        } else if (kind == BREATH_EXHALE) {
            level = left;
        }
        var color = 0;
        for (var shift = 16; shift >= 0; shift -= 8) {
            var from = (NimStyle.COLOR_DIMMED >> shift) & 0xFF;
            var to = (NimStyle.COLOR_PRIMARY >> shift) & 0xFF;
            color |= (from + ((to - from) * level).toNumber()) << shift;
        }
        return color;
    }

    // One buzz to inhale, two to exhale, a faint one to hold.
    private function cue() as Void {
        if (!_vibrate) {
            return;
        }
        var kind = _steps[_phases.index()][0];
        if (kind == BREATH_INHALE) {
            buzz([new Attention.VibeProfile(50, 150)] as Array<Attention.VibeProfile>);
        } else if (kind == BREATH_EXHALE) {
            buzz([
                new Attention.VibeProfile(50, 100),
                new Attention.VibeProfile(0, 100),
                new Attention.VibeProfile(50, 100)
            ] as Array<Attention.VibeProfile>);
        } else {
            buzz([new Attention.VibeProfile(25, 80)] as Array<Attention.VibeProfile>);
        }
    }

    private function buzz(pattern as Array<Attention.VibeProfile>) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate(pattern);
        }
    }

    private function heartRate() as Number? {
        var info = Activity.getActivityInfo();
        return info != null ? info.currentHeartRate : null;
    }
}

class BreatheDelegate extends WatchUi.BehaviorDelegate {
    private var _view as NimBreatheView;

    function initialize(view as NimBreatheView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        if (!_view.togglePause()) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }
}
