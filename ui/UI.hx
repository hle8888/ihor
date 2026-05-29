package ui;
import Eight;
import util.Texture.Button;

class UI {
    public var buttonLogic:Button;

    public var isShown:Bool = false;

    public function new() {
        /* buttonLogic = new Button('Logic', 50, 9);

        buttonLogic.clicked = function() {
            Game.isLogicVisible = !Game.isLogicVisible;
        }
        setVisible(true); */
    }

    public function setVisible(visible:Bool) {
        isShown = visible;

        //buttonLogic.setVisible(visible);
    }
}

