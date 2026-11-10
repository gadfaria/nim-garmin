import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

enum DateFormat {
    DATE_WEEKDAY_COMMA_DAY_MONTH = 0, // mon, 9 nov
    DATE_WEEKDAY_DAY_MONTH = 1,       // mon 9 nov
    DATE_DAY_MONTH = 2,               // 9 nov
    DATE_WEEKDAY_DAY = 3              // mon 9
}

class NimWatchFaceView extends WatchUi.WatchFace {
    private var _isSleeping as Boolean = false;
    private var _weekdays as Array<String> = [] as Array<String>;
    private var _months as Array<String> = [] as Array<String>;

    private var _showBattery as Boolean = true;
    private var _batteryThreshold as Number = 20;
    private var _dateFormat as Number = DATE_WEEKDAY_COMMA_DAY_MONTH;

    function initialize() {
        WatchFace.initialize();
        loadSettings();
    }

    function onLayout(dc as Dc) as Void {
        // Loaded from resources so they follow the watch language.
        _weekdays = loadStrings([
            Rez.Strings.Weekday1, Rez.Strings.Weekday2, Rez.Strings.Weekday3, Rez.Strings.Weekday4,
            Rez.Strings.Weekday5, Rez.Strings.Weekday6, Rez.Strings.Weekday7
        ]);
        _months = loadStrings([
            Rez.Strings.Month1, Rez.Strings.Month2, Rez.Strings.Month3, Rez.Strings.Month4,
            Rez.Strings.Month5, Rez.Strings.Month6, Rez.Strings.Month7, Rez.Strings.Month8,
            Rez.Strings.Month9, Rez.Strings.Month10, Rez.Strings.Month11, Rez.Strings.Month12
        ]);
    }

    function loadSettings() as Void {
        _showBattery = readProperty("ShowBattery", true) as Boolean;
        _batteryThreshold = readProperty("BatteryThreshold", 20) as Number;
        _dateFormat = readProperty("DateFormat", DATE_WEEKDAY_COMMA_DAY_MONTH) as Number;
    }

    function onUpdate(dc as Dc) as Void {
        // Dimmed always-on layout only applies to screens that need burn-in protection (AMOLED).
        var lowPower = _isSleeping && System.getDeviceSettings().requiresBurnInProtection;
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

        var lines = [
            [formatTime(), NimStyle.FONT_LARGE_NUMBER, lowPower ? NimStyle.COLOR_DIMMED : NimStyle.COLOR_PRIMARY],
            [formatDate(now), NimStyle.FONT_SMALL, lowPower ? NimStyle.COLOR_DIMMED : NimStyle.COLOR_SECONDARY]
        ] as Array<Array>;

        if (!lowPower && _showBattery) {
            var battery = Math.round(System.getSystemStats().battery).toNumber();
            var color = battery < _batteryThreshold ? NimStyle.COLOR_ALERT : NimStyle.COLOR_TERTIARY;
            lines.add([battery.toString() + "%", NimStyle.FONT_SMALL, color]);
        }

        var shift = lowPower ? burnInShift(dc, now.min as Number) : [0, 0];
        NimStyle.clear(dc);
        NimStyle.drawLines(dc, lines, shift[0], shift[1]);
    }

    function onEnterSleep() as Void {
        _isSleeping = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _isSleeping = false;
        WatchUi.requestUpdate();
    }

    private function formatTime() as String {
        var clock = System.getClockTime();
        if (System.getDeviceSettings().is24Hour) {
            return clock.hour.format("%02d") + ":" + clock.min.format("%02d");
        }
        var hour = clock.hour % 12;
        if (hour == 0) {
            hour = 12;
        }
        return hour.toString() + ":" + clock.min.format("%02d");
    }

    private function formatDate(now as Gregorian.Info) as String {
        // FORMAT_SHORT gives day_of_week 1..7 (Sunday first) and month 1..12.
        var weekday = _weekdays[(now.day_of_week as Number) - 1];
        var month = _months[(now.month as Number) - 1];
        var day = now.day.toString();

        switch (_dateFormat) {
            case DATE_WEEKDAY_DAY_MONTH:
                return weekday + " " + day + " " + month;
            case DATE_DAY_MONTH:
                return day + " " + month;
            case DATE_WEEKDAY_DAY:
                return weekday + " " + day;
            default:
                return weekday + ", " + day + " " + month;
        }
    }

    // Moves the text a few pixels each minute so no AMOLED pixel stays lit for long.
    private function burnInShift(dc as Dc, minute as Number) as Array<Number> {
        var step = dc.getWidth() / 100;
        var offsets = [[-step, 0], [0, step], [step, 0], [0, -step]];
        return offsets[minute % offsets.size()] as Array<Number>;
    }

    private function loadStrings(ids as Array<ResourceId>) as Array<String> {
        var strings = new Array<String>[ids.size()];
        for (var i = 0; i < ids.size(); i++) {
            strings[i] = WatchUi.loadResource(ids[i]) as String;
        }
        return strings;
    }

    private function readProperty(key as String, fallback as Properties.ValueType) as Properties.ValueType {
        try {
            var value = Application.Properties.getValue(key);
            return value != null ? value : fallback;
        } catch (e) {
            return fallback;
        }
    }
}
