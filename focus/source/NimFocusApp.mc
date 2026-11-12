import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class NimFocusApp extends Application.AppBase {
    private var _view as NimFocusView?;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var view = new NimFocusView();
        _view = view;
        return [view, new FocusDelegate(view)];
    }

    function onStop(state as Dictionary?) as Void {
        var view = _view;
        if (view != null) {
            view.save();
        }
    }

    function onSettingsChanged() as Void {
        var view = _view;
        if (view != null) {
            view.restart();
        }
    }
}
