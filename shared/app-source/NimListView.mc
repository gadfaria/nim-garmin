import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Vertical text list: the focused item sits in the middle, large and bright;
// the others shrink and darken with their distance from it.
class NimListView extends WatchUi.View {
    // Font and color by distance from the focused item; the last entry repeats beyond that.
    private const FONTS = [Graphics.FONT_LARGE, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY] as Array<FontType>;
    private const COLORS = [NimStyle.COLOR_PRIMARY, NimStyle.COLOR_SECONDARY, NimStyle.COLOR_TERTIARY, NimStyle.COLOR_DIMMED] as Array<Number>;

    var index as Number;
    private var _items as Array<String>;

    function initialize(items as Array<String>, index as Number) {
        View.initialize();
        _items = items;
        self.index = index >= 0 && index < items.size() ? index : 0;
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
        dc.setColor(COLORS[clampDistance(distance, COLORS.size())], Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, y, fontAt(distance), _items[i],
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function fontAt(distance as Number) as FontType {
        return FONTS[clampDistance(distance, FONTS.size())];
    }

    private function clampDistance(distance as Number, count as Number) as Number {
        return distance < count ? distance : count - 1;
    }
}

// Scrolls a NimListView with UP/DOWN or swipes; BACK leaves.
class NimListDelegate extends WatchUi.BehaviorDelegate {
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
