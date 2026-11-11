import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Countdown: remaining time large, the timer's length small below it.
// START pauses and resumes; BACK cancels. At zero it turns orange and buzzes.
class NimTimerView extends WatchUi.View {
    private var _minutes as Number;
    private var _remainingMs as Number;
    // System.getTimer() value when the countdown last resumed; null while paused.
    private var _resumedAt as Number? = null;
    private var _ticker as Timer.Timer = new Timer.Timer();
    private var _alerted as Boolean = false;

    function initialize(minutes as Number) {
        View.initialize();
        _minutes = minutes;
        _remainingMs = minutes * 60 * 1000;
    }

    function onShow() as Void {
        if (!_alerted) {
            resume();
        }
    }

    function onHide() as Void {
        _ticker.stop();
    }

    function togglePause() as Void {
        if (_alerted) {
            return;
        }
        if (_resumedAt != null) {
            _remainingMs = remainingMs();
            _resumedAt = null;
            _ticker.stop();
        } else {
            resume();
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var remaining = remainingMs();
        if (remaining == 0 && !_alerted) {
            alert();
        }

        var paused = _resumedAt == null && !_alerted;
        var mainColor = _alerted ? NimStyle.COLOR_ALERT : (paused ? NimStyle.COLOR_SECONDARY : NimStyle.COLOR_PRIMARY);
        var label = paused ? WatchUi.loadResource(Rez.Strings.Paused) as String : _minutes.toString() + " min";

        NimStyle.clear(dc);
        NimStyle.drawLines(dc, [
            [format(remaining), NimStyle.FONT_LARGE_NUMBER, mainColor],
            [label, NimStyle.FONT_SMALL, NimStyle.COLOR_TERTIARY]
        ] as Array<Array>, 0, 0);
    }

    private function resume() as Void {
        _resumedAt = System.getTimer();
        _ticker.start(method(:onTick), 1000, true);
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

    // Measured from the system clock so the countdown doesn't drift with timer jitter.
    private function remainingMs() as Number {
        var resumedAt = _resumedAt;
        if (resumedAt == null) {
            return _remainingMs;
        }
        var remaining = _remainingMs - (System.getTimer() - resumedAt);
        return remaining > 0 ? remaining : 0;
    }

    private function alert() as Void {
        _alerted = true;
        _remainingMs = 0;
        _resumedAt = null;
        _ticker.stop();
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 400),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(100, 400)
            ]);
        }
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_ALARM);
        }
    }

    // Rounds up, so 4:59.2 shows 5:00 and the display reaches 0:00 exactly at the end.
    private function format(ms as Number) as String {
        var seconds = (ms + 999) / 1000;
        return (seconds / 60).toString() + ":" + (seconds % 60).format("%02d");
    }
}

class TimerDelegate extends WatchUi.BehaviorDelegate {
    private var _view as NimTimerView;

    function initialize(view as NimTimerView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        _view.togglePause();
        return true;
    }
}
