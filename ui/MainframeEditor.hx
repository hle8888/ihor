package ui;

import Eight;
import util.Math.Vec3;
import util.Texture.Button;
import util.Texture.FontManager;
import sdl.Event;
import objects.Objects.Mainframe;

class MainframeEditor {
    var bg:Eight.Object;
    var buttonSave:Button;
    var buttonClose:Button;
    var updateCb:Float->Void;
    var eventCb:Event->Void;

    public var isOpen:Bool = false;
    public var current:Mainframe;
    public var text:String = "";
    public var status:String = "Ready";

    public function new() {}

    public function open(mainframe:Mainframe) {
        if (isOpen) close(false);

        current = mainframe;
        text = mainframe.script;
        status = "Editing";
        isOpen = true;

        bg = new Eight.Object(Engine.n - 120, Engine.n2 - 120, null, 0xFF1E2127);
        bg.isUI = true;

        buttonSave = new Button('Save');
        buttonSave.pos = new Vec3(120, 34, 0);
        buttonSave.setVisible(true);
        buttonSave.clicked = function() {
            if (current == null) return;
            current.script = text;
            current.compileScript();
            status = current.lastError == '' ? 'Saved' : 'Error';
        };

        buttonClose = new Button('Close');
        buttonClose.pos = new Vec3(240, 34, 0);
        buttonClose.setVisible(true);
        buttonClose.clicked = function() {
            close();
        };

        updateCb = (dt:Float) -> {
            bg.setPos(Engine.n / 2, Engine.n2 / 2);
            FontManager.drawText('Mainframe editor', 30, Engine.n2 - 54);
            FontManager.drawText(status, 30, Engine.n2 - 74);

            var lines = text.split("\n");
            var maxLines = Std.int((Engine.n2 - 180) / 18);
            var visible = Std.int(Math.min(lines.length, maxLines));
            for (i in 0...visible) {
                FontManager.drawText(lines[i], 30, Engine.n2 - 110 - 18 * i);
            }

            FontManager.drawText('Script API:', Engine.n - 320, Engine.n2 - 54);
            FontManager.drawText('setOut(index, bool)', Engine.n - 320, Engine.n2 - 74);
            FontManager.drawText('getIn(index)', Engine.n - 320, Engine.n2 - 92);
            FontManager.drawText('time, dt', Engine.n - 320, Engine.n2 - 110);

            if (current != null && current.lastError != '') {
                FontManager.drawText(current.lastError, 30, 70);
            }
        };

        eventCb = (event:Event) -> {
            if (event.type != EventType.KeyDown) return;

            if (event.keyCode == 27) { // esc
                close();
                return;
            }
            if (event.keyCode == 8) { // backspace
                if (text.length > 0) text = text.substr(0, text.length - 1);
                return;
            }
            if (event.keyCode == 13) { // enter
                text += "\n";
                return;
            }
            if (event.keyCode == 9) { // tab
                text += "    ";
                return;
            }
            if (event.keyCode == 32) { // space
                text += " ";
                return;
            }

            var ch = keyCodeToChar(event.keyCode);
            if (ch != null) {
                text += ch;
            }
        };

        Eight.registerUpdateCallback(updateCb);
        Eight.registerEventCallback(eventCb);
    }

    function keyCodeToChar(keyCode:Int):String {
        if (keyCode >= 97 && keyCode <= 122) return String.fromCharCode(keyCode);
        if (keyCode >= 48 && keyCode <= 57) return String.fromCharCode(keyCode);

        return switch (keyCode) {
            case 45: "-";
            case 61: "=";
            case 91: "[";
            case 93: "]";
            case 59: ";";
            case 39: "'";
            case 44: ",";
            case 46: ".";
            case 47: "/";
            case 92: "\\";
            case 96: "`";
            default: null;
        };
    }

    public function close(save:Bool = false) {
        if (!isOpen) return;

        if (save && current != null) {
            current.script = text;
            current.compileScript();
        }

        isOpen = false;

        if (updateCb != null) Eight.unregisterUpdateCallback(updateCb);
        if (eventCb != null) Eight.unregisterEventCallback(eventCb);

        if (buttonSave != null) buttonSave.destroy();
        if (buttonClose != null) buttonClose.destroy();
        if (bg != null) bg.destroy();

        updateCb = null;
        eventCb = null;
        buttonSave = null;
        buttonClose = null;
        bg = null;
        current = null;
    }
}
