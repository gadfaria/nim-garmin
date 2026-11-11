import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

// Shared Nim visual identity: colors, fonts and the centered stacked text layout.
module NimStyle {
    const COLOR_BACKGROUND = 0x000000;
    const COLOR_PRIMARY = 0xF1EFE8;
    const COLOR_SECONDARY = 0xB4B2A9;
    const COLOR_TERTIARY = 0x888780;
    const COLOR_DIMMED = 0x5F5E5A;
    const COLOR_ALERT = 0xD85A30;

    const FONT_LARGE_NUMBER = Graphics.FONT_NUMBER_HOT;
    const FONT_LARGE_TEXT = Graphics.FONT_LARGE;
    const FONT_SMALL = Graphics.FONT_SMALL;

    // Fraction of the screen height between stacked lines.
    const LINE_GAP = 0.01;
    // Fraction of the visible width text may take, leaving a margin on each side.
    const TEXT_WIDTH_RATIO = 0.9;

    function clear(dc as Dc) as Void {
        dc.setColor(COLOR_BACKGROUND, COLOR_BACKGROUND);
        dc.clear();
    }

    // Number fonts have no descenders, so only their ascent takes up room.
    function lineHeight(dc as Dc, font as FontType) as Number {
        if (font == Graphics.FONT_NUMBER_MILD || font == Graphics.FONT_NUMBER_MEDIUM
                || font == Graphics.FONT_NUMBER_HOT || font == Graphics.FONT_NUMBER_THAI_HOT) {
            return Graphics.getFontAscent(font);
        }
        return dc.getFontHeight(font);
    }

    function lineGap(dc as Dc) as Number {
        return (dc.getHeight() * LINE_GAP).toNumber();
    }

    // Total height of lines of [text, font, color] stacked with the line gap.
    function blockHeight(dc as Dc, lines as Array<Array>) as Number {
        var total = lineGap(dc) * (lines.size() - 1);
        for (var i = 0; i < lines.size(); i++) {
            total += lineHeight(dc, lines[i][1] as FontType);
        }
        return total;
    }

    // Whether the lines, laid out as drawLines does, fit the visible part of the area.
    // obscurity is a data field's getObscurityFlags() (0 for full, unobscured areas).
    function fits(dc as Dc, lines as Array<Array>, obscurity as Number) as Boolean {
        var total = blockHeight(dc, lines);
        if (total > dc.getHeight()) {
            return false;
        }
        var gap = lineGap(dc);
        var y = (dc.getHeight() - total) / 2;
        for (var i = 0; i < lines.size(); i++) {
            var font = lines[i][1] as FontType;
            var height = lineHeight(dc, font);
            var width = dc.getTextWidthInPixels(lines[i][0] as String, font);
            if (width > visibleWidth(dc, y, y + height, obscurity)) {
                return false;
            }
            y += height + gap;
        }
        return true;
    }

    // Width available to text centered in the area between local rows yTop and yBottom.
    // On round screens the area's position is inferred from which screen edges it touches.
    function visibleWidth(dc as Dc, yTop as Number, yBottom as Number, obscurity as Number) as Float {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var settings = System.getDeviceSettings();
        if (settings.screenShape == System.SCREEN_SHAPE_RECTANGLE) {
            return width * TEXT_WIDTH_RATIO;
        }

        var screenWidth = settings.screenWidth;
        var screenHeight = settings.screenHeight;
        var x0 = (screenWidth - width) / 2.0;
        if ((obscurity & WatchUi.DataField.OBSCURE_LEFT) != 0 && (obscurity & WatchUi.DataField.OBSCURE_RIGHT) == 0) {
            x0 = 0.0;
        } else if ((obscurity & WatchUi.DataField.OBSCURE_RIGHT) != 0 && (obscurity & WatchUi.DataField.OBSCURE_LEFT) == 0) {
            x0 = (screenWidth - width).toFloat();
        }
        var y0 = (screenHeight - height) / 2.0;
        if ((obscurity & WatchUi.DataField.OBSCURE_TOP) != 0 && (obscurity & WatchUi.DataField.OBSCURE_BOTTOM) == 0) {
            y0 = 0.0;
        } else if ((obscurity & WatchUi.DataField.OBSCURE_BOTTOM) != 0 && (obscurity & WatchUi.DataField.OBSCURE_TOP) == 0) {
            y0 = (screenHeight - height).toFloat();
        }

        // The circle is narrowest at whichever row of the line is farthest from the center.
        var radius = screenWidth / 2.0;
        var dyTop = (y0 + yTop - screenHeight / 2.0).abs();
        var dyBottom = (y0 + yBottom - screenHeight / 2.0).abs();
        var dy = dyTop > dyBottom ? dyTop : dyBottom;
        if (dy >= radius) {
            return 0.0;
        }
        var halfChord = Math.sqrt(radius * radius - dy * dy).toFloat();

        var center = x0 + width / 2.0;
        var left = screenWidth / 2.0 - halfChord;
        var right = screenWidth / 2.0 + halfChord;
        if (left < x0) {
            left = x0;
        }
        if (right > x0 + width) {
            right = x0 + width;
        }
        var half = center - left < right - center ? center - left : right - center;
        return half * 2 * TEXT_WIDTH_RATIO;
    }

    // Draws lines of [text, font, color], centered horizontally and vertically,
    // optionally shifted (used for AMOLED burn-in protection).
    function drawLines(dc as Dc, lines as Array<Array>, shiftX as Number, shiftY as Number) as Void {
        var gap = lineGap(dc);
        var x = dc.getWidth() / 2 + shiftX;
        var y = (dc.getHeight() - blockHeight(dc, lines)) / 2 + shiftY;
        for (var i = 0; i < lines.size(); i++) {
            var line = lines[i];
            var font = line[1] as FontType;
            dc.setColor(line[2] as Number, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, font, line[0] as String, Graphics.TEXT_JUSTIFY_CENTER);
            y += lineHeight(dc, font) + gap;
        }
    }
}
