import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Checklist items come from the phone settings (comma separated); checks survive closing the app.
class Checklist {
    private const STORAGE_KEY = "checked";

    private var _items as Array<String>;
    private var _checked as Array<String>;

    function initialize() {
        _items = parse(readSetting());
        var stored = Application.Storage.getValue(STORAGE_KEY);
        _checked = stored instanceof Array ? stored as Array<String> : [] as Array<String>;
    }

    // Items plus a final "clear all" entry.
    function labels() as Array<String> {
        var labels = _items.slice(0, null);
        labels.add(WatchUi.loadResource(_items.size() > 0 ? Rez.Strings.ClearAll : Rez.Strings.Empty) as String);
        return labels;
    }

    function struck() as Array<Boolean> {
        var struck = new Array<Boolean>[_items.size() + 1];
        for (var i = 0; i < _items.size(); i++) {
            struck[i] = _checked.indexOf(_items[i]) >= 0;
        }
        struck[_items.size()] = false;
        return struck;
    }

    // Toggles the item at index, or clears everything when the last entry is selected.
    function select(index as Number) as Void {
        if (index >= _items.size()) {
            _checked = [] as Array<String>;
        } else if (_checked.indexOf(_items[index]) >= 0) {
            _checked.remove(_items[index]);
        } else {
            _checked.add(_items[index]);
        }
        Application.Storage.setValue(STORAGE_KEY, _checked as Array<Application.Storage.ValueType>);
    }

    private function readSetting() as String {
        var value = null;
        try {
            value = Application.Properties.getValue("ChecklistItems");
        } catch (e) {
            value = null;
        }
        if (value instanceof String && value.length() > 0) {
            return value;
        }
        return WatchUi.loadResource(Rez.Strings.DefaultChecklist) as String;
    }

    private function parse(text as String) as Array<String> {
        var items = [] as Array<String>;
        var rest = text;
        while (rest.length() > 0) {
            var comma = rest.find(",");
            var item = comma != null ? rest.substring(0, comma) : rest;
            rest = comma != null ? rest.substring(comma + 1, rest.length()) : "";
            item = trim(item as String);
            if (item.length() > 0) {
                items.add(item);
            }
        }
        return items;
    }

    private function trim(text as String) as String {
        var chars = text.toCharArray();
        var start = 0;
        var end = chars.size();
        while (start < end && chars[start] == ' ') {
            start++;
        }
        while (end > start && chars[end - 1] == ' ') {
            end--;
        }
        return text.substring(start, end) as String;
    }
}

class ChecklistDelegate extends ListDelegate {
    private var _checklist as Checklist;

    function initialize(view as NimListView, checklist as Checklist) {
        ListDelegate.initialize(view);
        _checklist = checklist;
        view.setItems(checklist.labels(), checklist.struck());
    }

    function onSelect() as Boolean {
        _checklist.select(_view.index);
        _view.setItems(_checklist.labels(), _checklist.struck());
        return true;
    }
}
