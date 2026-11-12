import Toybox.Application;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Pomodoro: time left large, then the phase (focus, break, long break) and the
// current focus block. Starts counting as soon as it opens.
// START pauses and resumes; holding MENU offers skip and restart; BACK leaves and
// the session is picked up again on the next launch.
class NimFocusView extends WatchUi.View {
    private const STORAGE_STATE = "state";
    // A session left alone for longer than this starts over.
    private const STALE_SECONDS = 3600;

    private var _cycles as Number = 4;
    private var _autoAdvance as Boolean = true;
    // Focus and break alternate; the last break of the cycle is the long one.
    private var _phases as NimPhases;
    // The phase is over and waiting for START to begin the next one.
    private var _ended as Boolean = false;
    private var _ticker as Timer.Timer = new Timer.Timer();

    function initialize() {
        View.initialize();
        _phases = buildPhases();
        if (!restore()) {
            _phases.resume();
        }
    }

    function onShow() as Void {
        onTick();
        if (_phases.isRunning()) {
            tick();
        }
    }

    function onHide() as Void {
        _ticker.stop();
    }

    function onTick() as Void {
        if (_phases.isRunning()) {
            if (_autoAdvance) {
                if (_phases.advance()) {
                    alert();
                }
            } else if (_phases.remainingMs() == 0) {
                _phases.pause();
                _ended = true;
                _ticker.stop();
                alert();
            }
        }
        WatchUi.requestUpdate();
    }

    function togglePause() as Void {
        if (_ended) {
            start(true);
        } else if (_phases.isRunning()) {
            _phases.pause();
            _ticker.stop();
        } else {
            start(false);
        }
        WatchUi.requestUpdate();
    }

    function skip() as Void {
        start(true);
    }

    function restart() as Void {
        _phases = buildPhases();
        start(false);
    }

    // Saved with the wall clock, so the countdown keeps going while the app is closed.
    function save() as Void {
        Application.Storage.setValue(STORAGE_STATE, {
            "index" => _phases.index(),
            "remainingMs" => _phases.remainingMs(),
            "running" => _phases.isRunning(),
            "savedAt" => Time.now().value()
        });
    }

    function onUpdate(dc as Dc) as Void {
        var paused = !_phases.isRunning();
        var color = _ended ? NimStyle.COLOR_ALERT : (paused ? NimStyle.COLOR_SECONDARY : NimStyle.COLOR_PRIMARY);
        var index = _phases.index();
        var block = (index / 2 + 1).toString() + " / " + _cycles.toString();

        NimStyle.clear(dc);
        NimStyle.drawLines(dc, [
            [NimApp.formatClock(_phases.remainingMs()), NimStyle.FONT_LARGE_NUMBER, color],
            [label(index), NimStyle.FONT_SMALL, NimStyle.COLOR_SECONDARY],
            [paused && !_ended ? WatchUi.loadResource(Rez.Strings.Paused) as String : block,
                NimStyle.FONT_SMALL, NimStyle.COLOR_TERTIARY]
        ] as Array<Array>, 0, 0);
    }

    private function buildPhases() as NimPhases {
        _cycles = atLeastOne(NimApp.readProperty("Cycles", 4) as Number);
        _autoAdvance = NimApp.readProperty("AutoAdvance", true) as Boolean;
        var focusMs = atLeastOne(NimApp.readProperty("FocusMinutes", 25) as Number) * 60000;
        var breakMs = atLeastOne(NimApp.readProperty("BreakMinutes", 5) as Number) * 60000;
        var longBreakMs = atLeastOne(NimApp.readProperty("LongBreakMinutes", 15) as Number) * 60000;

        var durations = [] as Array<Number>;
        for (var i = 0; i < _cycles; i++) {
            durations.add(focusMs);
            durations.add(i < _cycles - 1 ? breakMs : longBreakMs);
        }
        return new NimPhases(durations);
    }

    // An empty cycle or a zero-length phase would never let the countdown settle.
    private function atLeastOne(value as Number) as Number {
        return value > 0 ? value : 1;
    }

    // Runs the current phase, or the next one from its start.
    private function start(next as Boolean) as Void {
        _ended = false;
        if (next) {
            _phases.pause();
            _phases.next();
        }
        _phases.resume();
        tick();
        WatchUi.requestUpdate();
    }

    private function tick() as Void {
        _ticker.stop();
        _ticker.start(method(:onTick), 1000, true);
    }

    // Picks up the saved session. Returns false when there is none worth resuming.
    private function restore() as Boolean {
        var state = Application.Storage.getValue(STORAGE_STATE);
        if (!(state instanceof Dictionary)) {
            return false;
        }
        var index = state["index"];
        var remainingMs = state["remainingMs"];
        var running = state["running"];
        var savedAt = state["savedAt"];
        if (!(index instanceof Number) || !(remainingMs instanceof Number)
                || !(running instanceof Boolean) || !(savedAt instanceof Number)) {
            return false;
        }

        var awaySeconds = Time.now().value() - savedAt;
        if (awaySeconds < 0 || awaySeconds > STALE_SECONDS || index >= _cycles * 2) {
            return false;
        }
        _phases.restore(index, remainingMs);
        if (remainingMs > _phases.durationMs()) {
            // Settings changed since the session was saved.
            _phases = buildPhases();
            return false;
        }

        if (running) {
            var leftMs = remainingMs - awaySeconds * 1000;
            _phases.restore(index, leftMs > 0 ? leftMs : 0);
            if (leftMs > 0) {
                _phases.resume();
            }
        }
        // A phase that ran out, here or while away, waits for START.
        _ended = _phases.remainingMs() == 0;
        return true;
    }

    private function label(index as Number) as String {
        if (index % 2 == 0) {
            return WatchUi.loadResource(Rez.Strings.Focus) as String;
        } else if (index == _cycles * 2 - 1) {
            return WatchUi.loadResource(Rez.Strings.LongBreak) as String;
        }
        return WatchUi.loadResource(Rez.Strings.Break) as String;
    }

    private function alert() as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 400),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(100, 400)
            ] as Array<Attention.VibeProfile>);
        }
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_ALARM);
        }
    }
}

class FocusDelegate extends WatchUi.BehaviorDelegate {
    private var _view as NimFocusView;

    function initialize(view as NimFocusView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        _view.togglePause();
        return true;
    }

    function onMenu() as Boolean {
        var menu = new NimListView([
            WatchUi.loadResource(Rez.Strings.Skip) as String,
            WatchUi.loadResource(Rez.Strings.Restart) as String
        ] as Array<String>, 0);
        WatchUi.pushView(menu, new FocusMenuDelegate(menu, _view), WatchUi.SLIDE_UP);
        return true;
    }
}

// Skip and restart, in that order.
class FocusMenuDelegate extends NimListDelegate {
    private var _focus as NimFocusView;

    function initialize(menu as NimListView, focus as NimFocusView) {
        NimListDelegate.initialize(menu);
        _focus = focus;
    }

    function onSelect() as Boolean {
        if (_view.index == 0) {
            _focus.skip();
        } else {
            _focus.restart();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
