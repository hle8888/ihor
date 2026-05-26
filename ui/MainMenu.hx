package ui;
import Eight;
import util.Texture.Button;

class MainMenu {
    public var buttonNew:Button;
    public var buttonSave:Button;
    public var buttonLoad:Button;
    public var buttonOptions:Button;
    public var buttonExit:Button;

    public var isShown:Bool = false;

    public function new() {
        buttonNew = new Button('New game ', Engine.n-200, 200+18*4);
        buttonSave = new Button('Save     ', Engine.n-200, 200+18*3);
        buttonLoad = new Button('Load     ', Engine.n-200, 200+18*2);
        buttonOptions = new Button('Options  ', Engine.n-200, 200+18);
        buttonExit = new Button('Exit     ', Engine.n-200, 200);

        buttonExit.clicked = function() {
            SaveManager.save(Game.currentShip);
            //SaveManager.save(Game.currentShip2);
            Eight.run = false;
        }

        setVisible(false);
    }

    public function setVisible(visible:Bool) {
        isShown = visible;

        buttonNew.setVisible(visible);
        buttonSave.setVisible(visible);
        buttonLoad.setVisible(visible);
        buttonOptions.setVisible(visible);
        buttonExit.setVisible(visible);
    }
}

