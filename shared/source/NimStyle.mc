import Toybox.Graphics;
import Toybox.Lang;

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

    // Draws lines of [text, font, color], centered horizontally and vertically,
    // optionally shifted (used for AMOLED burn-in protection).
    function drawLines(dc as Dc, lines as Array<Array>, shiftX as Number, shiftY as Number) as Void {
        var gap = (dc.getHeight() * LINE_GAP).toNumber();
        var heights = new Array<Number>[lines.size()];
        var total = 0;
        for (var i = 0; i < lines.size(); i++) {
            heights[i] = lineHeight(dc, lines[i][1] as FontType);
            total += heights[i];
        }
        total += gap * (lines.size() - 1);

        var x = dc.getWidth() / 2 + shiftX;
        var y = (dc.getHeight() - total) / 2 + shiftY;
        for (var i = 0; i < lines.size(); i++) {
            var line = lines[i];
            dc.setColor(line[2] as Number, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, line[1] as FontType, line[0] as String, Graphics.TEXT_JUSTIFY_CENTER);
            y += heights[i] + gap;
        }
    }
}
