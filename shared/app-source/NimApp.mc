import Toybox.Application;
import Toybox.Lang;

// Small helpers shared by the Nim watch apps.
module NimApp {
    function readProperty(key as String, fallback as Properties.ValueType) as Properties.ValueType {
        try {
            var value = Application.Properties.getValue(key);
            return value != null ? value : fallback;
        } catch (e) {
            return fallback;
        }
    }

    // m:ss, rounded up so the display reaches 0:00 exactly at the end.
    function formatClock(ms as Number) as String {
        var seconds = (ms + 999) / 1000;
        return (seconds / 60).toString() + ":" + (seconds % 60).format("%02d");
    }
}
