import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Vertical text list: the focused item sits in the middle, large and bright;
// the others shrink and darken with their distance from it.
class NimListView extends WatchUi.View {
    // Font and color by distance from the focused item; the last entry repeats beyond that.
    private const FONTS = [Graphics.FONT_LARGE, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY] as Array<FontType>;
    private const COLORS = [NimStyle.COLOR_PRIMARY, NimStyle.COLOR_SECONDARY, NimStyle.COLOR_TERTIARY, NimStyle.COLOR_DIMMED] as Array<Number>;

    var index as Number = 0;
    private var _items as Array<String>;
    // Items drawn struck through, e.g. checked checklist entries.
    private var _struck as Array<Boolean>;

    function initialize(items as Array<String>) {
        View.initialize();
        _items = items;
        _struck = new Array<Boolean>[items.size()];
        for (var i = 0; i < items.size(); i++) {
            _struck[i] = false;
        }
    }

    function setItems(items as Array<String>, struck as Array<Boolean>) as Void {
        _items = items;
        _struck = struck;
        if (index >= items.size()) {
            index = items.size() - 1;
        }
        WatchUi.requestUpdate();
    }

    function size() as Number {
        return _items.size();
    }

    // Moves the focus, stopping at the ends.
    function move(delta as Number) as Void {
        var next = index + delta;
        if (next >= 0 && next < _items.size()) {
            index = next;
            WatchUi.requestUpdate();
        }
    }

    function onUpdate(dc as Dc) as Void {
        NimStyle.clear(dc);
        if (_items.size() == 0) {
            return;
        }
        var centerY = dc.getHeight() / 2;
        var focusHalf = dc.getFontHeight(FONTS[0]) / 2;
        drawItem(dc, index, 0, centerY);
        drawSide(dc, 1, centerY + focusHalf);
        drawSide(dc, -1, centerY - focusHalf);
    }

    // Draws items after (direction 1) or before (-1) the focused one, outward from edgeY.
    private function drawSide(dc as Dc, direction as Number, edgeY as Number) as Void {
        var gap = NimStyle.lineGap(dc);
        var y = edgeY;
        var i = index + direction;
        while (i >= 0 && i < _items.size() && y > 0 && y < dc.getHeight()) {
            var distance = (i - index).abs();
            var height = dc.getFontHeight(fontAt(distance));
            y += direction * (gap + height / 2);
            drawItem(dc, i, distance, y);
            y += direction * (height - height / 2);
            i += direction;
        }
    }

    private function drawItem(dc as Dc, i as Number, distance as Number, y as Number) as Void {
        var font = fontAt(distance);
        var x = dc.getWidth() / 2;
        dc.setColor(COLORS[clampDistance(distance, COLORS.size())], Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, _items[i], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (_struck[i]) {
            var halfWidth = dc.getTextWidthInPixels(_items[i], font) / 2;
            dc.setPenWidth(distance == 0 ? 2 : 1);
            dc.drawLine(x - halfWidth, y, x + halfWidth, y);
        }
    }

    private function fontAt(distance as Number) as FontType {
        return FONTS[clampDistance(distance, FONTS.size())];
    }

    private function clampDistance(distance as Number, count as Number) as Number {
        return distance < count ? distance : count - 1;
    }
}

// Scrolls a NimListView with UP/DOWN or swipes; BACK leaves.
class ListDelegate extends WatchUi.BehaviorDelegate {
    protected var _view as NimListView;

    function initialize(view as NimListView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        _view.move(1);
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.move(-1);
        return true;
    }
}
