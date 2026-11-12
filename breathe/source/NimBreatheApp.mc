import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

enum BreathKind {
    BREATH_INHALE,
    BREATH_HOLD_FULL,
    BREATH_EXHALE,
    BREATH_HOLD_EMPTY
}

class NimBreatheApp extends Application.AppBase {
    // Each technique is a cycle of [kind, seconds] steps, in menu order.
    static const TECHNIQUES = [
        [[BREATH_INHALE, 4], [BREATH_HOLD_FULL, 4], [BREATH_EXHALE, 4], [BREATH_HOLD_EMPTY, 4]],
        [[BREATH_INHALE, 4], [BREATH_HOLD_FULL, 7], [BREATH_EXHALE, 8]],
        [[BREATH_INHALE, 5], [BREATH_EXHALE, 5]]
    ] as Array<Array<Array<Number> > >;

    static const STORAGE_TECHNIQUE = "technique";

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var items = [
            WatchUi.loadResource(Rez.Strings.Box) as String,
            WatchUi.loadResource(Rez.Strings.FourSevenEight) as String,
            WatchUi.loadResource(Rez.Strings.Coherent) as String
        ] as Array<String>;
        var last = Application.Storage.getValue(STORAGE_TECHNIQUE);
        var view = new NimListView(items, last instanceof Number ? last : 0);
        return [view, new TechniqueDelegate(view)];
    }
}

// Technique menu, opened on the one used last.
class TechniqueDelegate extends NimListDelegate {
    function initialize(view as NimListView) {
        NimListDelegate.initialize(view);
    }

    function onSelect() as Boolean {
        var index = _view.index;
        Application.Storage.setValue(NimBreatheApp.STORAGE_TECHNIQUE, index);
        var session = new NimBreatheView(
            NimBreatheApp.TECHNIQUES[index],
            NimApp.readProperty("SessionMinutes", 5) as Number,
            NimApp.readProperty("Vibrate", true) as Boolean
        );
        WatchUi.pushView(session, new BreatheDelegate(session), WatchUi.SLIDE_LEFT);
        return true;
    }
}
