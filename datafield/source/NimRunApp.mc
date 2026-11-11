import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class NimRunApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [new NimRunView()];
    }
}
