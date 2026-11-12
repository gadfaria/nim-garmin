import Toybox.Lang;
import Toybox.System;

// Cyclic sequence of timed phases (focus and break, inhale and exhale).
// Measured from the system clock so it doesn't drift with timer jitter.
class NimPhases {
    private var _durationsMs as Array<Number>;
    private var _index as Number = 0;
    // Time left in the current phase; only current while paused.
    private var _remainingMs as Number;
    // System.getTimer() value at which the current phase ends; null while paused.
    private var _endsAt as Number? = null;

    function initialize(durationsMs as Array<Number>) {
        _durationsMs = durationsMs;
        _remainingMs = durationsMs[0];
    }

    function index() as Number {
        return _index;
    }

    function durationMs() as Number {
        return _durationsMs[_index];
    }

    function isRunning() as Boolean {
        return _endsAt != null;
    }

    function remainingMs() as Number {
        var endsAt = _endsAt;
        if (endsAt == null) {
            return _remainingMs;
        }
        var remaining = endsAt - System.getTimer();
        return remaining > 0 ? remaining : 0;
    }

    function resume() as Void {
        if (_endsAt == null) {
            _endsAt = System.getTimer() + _remainingMs;
        }
    }

    function pause() as Void {
        _remainingMs = remainingMs();
        _endsAt = null;
    }

    // Jumps to a phase with the given time left, paused.
    function restore(index as Number, remainingMs as Number) as Void {
        _index = index % _durationsMs.size();
        _remainingMs = remainingMs;
        _endsAt = null;
    }

    // Starts the next phase at its full length, keeping the running or paused state.
    function next() as Void {
        var running = isRunning();
        restore(_index + 1, _durationsMs[(_index + 1) % _durationsMs.size()]);
        if (running) {
            resume();
        }
    }

    // Moves past every phase that has ended while running, carrying the overshoot
    // into the next one. Returns whether the phase changed.
    function advance() as Boolean {
        var changed = false;
        var endsAt = _endsAt;
        // Compared by difference, which stays right when the system timer wraps around.
        while (endsAt != null && endsAt - System.getTimer() <= 0) {
            _index = (_index + 1) % _durationsMs.size();
            endsAt += _durationsMs[_index];
            _endsAt = endsAt;
            changed = true;
        }
        return changed;
    }
}
