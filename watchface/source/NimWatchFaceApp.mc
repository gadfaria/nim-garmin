import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class NimWatchFaceApp extends Application.AppBase {
    private var _view as NimWatchFaceView?;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        _view = new NimWatchFaceView();
        return [_view];
    }

    function onSettingsChanged() as Void {
        // Local copy so the type checker can narrow away null.
        var view = _view;
        if (view != null) {
            view.loadSettings();
        }
        WatchUi.requestUpdate();
    }
}
