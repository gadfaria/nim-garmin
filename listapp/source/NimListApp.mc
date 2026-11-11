import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class NimListApp extends Application.AppBase {
    // Timer lengths in minutes, in menu order; the checklist comes after them.
    static const TIMER_MINUTES = [1, 5, 25] as Array<Number>;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var items = [] as Array<String>;
        for (var i = 0; i < TIMER_MINUTES.size(); i++) {
            items.add(TIMER_MINUTES[i].toString() + " min");
        }
        items.add(WatchUi.loadResource(Rez.Strings.Checklist) as String);

        var view = new NimListView(items);
        return [view, new MenuDelegate(view)];
    }
}

// Main menu: timers, then the checklist.
class MenuDelegate extends ListDelegate {
    function initialize(view as NimListView) {
        ListDelegate.initialize(view);
    }

    function onSelect() as Boolean {
        var index = _view.index;
        if (index < NimListApp.TIMER_MINUTES.size()) {
            var timer = new NimTimerView(NimListApp.TIMER_MINUTES[index]);
            WatchUi.pushView(timer, new TimerDelegate(timer), WatchUi.SLIDE_LEFT);
        } else {
            var checklist = new Checklist();
            var view = new NimListView(checklist.labels());
            WatchUi.pushView(view, new ChecklistDelegate(view, checklist), WatchUi.SLIDE_LEFT);
        }
        return true;
    }
}
