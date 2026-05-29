//haxe -lib hscript -lib hlsdl -D -O2 -hl ..\out\build.c -main Game -D hlgen.makefile=vs2022 && ..\out\x64\Release\build.exe
//haxe -lib hscript -lib hlsdl -D -O2 -hl ..\out\build.c -main Game -D hlgen.makefile=vs2022 -D analyzer-optimize -D analyzer-user-var-fusion -D analyzer-fusion -D hl-optimize -D hlcunsafe -D release && ..\out\x64\Release\build.exe
//haxe -lib format -lib hlopenal -lib hscript -lib hlsdl -D -O3 -D analyzer-optimize -D analyzer-fusion -hl ..\out\build.c -main Game -D hlgen.makefile=vs2022 && ..\out\x64\Release\build.exe

import Eight;
import Character.MoveJob;
import sdl.Event;
import util.Math.Vec3;
import util.Math.FastTrig;
import util.Texture.FontManager;
import util.Texture.Texture;
import util.Texture.Button;
import ui.*;
import util.*;
import objects.Objects;
import objects.Pipe;
import objects.Extendable;
import objects.MiniMap;
import objects.Items;

class Production {
    public var item:Item;
}

class Station {
    public var manager:ExtendableManager;
    public function new() {
        
    }
}

class Game extends Eight {
    public var paused:Bool = false;
    public static var credits:Int = 100;

    public static var currentShip:ExtendableManager = new ExtendableManager();
    public static var currentShip2:ExtendableManager = new ExtendableManager();
    public static var stations:Array<Station> = [];
    public static var characters:Array<Character> = [];
    
    public var ui:UI;
    public var mainMenu:MainMenu;
    public var contextMenu:ContextMenu;

    public static var isLogicVisible:Bool = false;
    
    public var bg:Eight.Object;
    public var minimap:MiniMap;
    var line:Line; var lineAngular:Line;
    public static var planets:Array<Planet> = [];

    var mainCharacter:ExtendableObject;

    //public var mainCharacter:objects.ExtendableObject;
    public function new() {         
        super();
        
        //Worker.run();
        bg = new Eight.Object(Engine.n*2, Engine.n2*2, null, 0xFF000000);
        bg.isUI = true;
         
        mouseMoveLine = new Line(new Vec3(0, 0, 0), new Vec3(0, 0, 0));
        mouseMoveLine.setVisible(false);

        mainCharacter = new TwoLegCharacter();
        mainCharacter.setPos(250, 250);

        var box = new Box();
        box.setPos(100, 100);
        

        ui = new UI();
        mainMenu = new MainMenu();    
        //SoundManager.init();
        
        /*
        currentShip2.template = 'data/station1.json';
        SaveManager.load(currentShip2);
        currentShip2.core.pos = new Vec3(600, 250, 0);
        
        var station = new Station();
        station.manager = new ExtendableManager();
        station.manager.template = 'data/station1.json';
        SaveManager.load(station.manager);
        station.manager.core.pos = new Vec3(1600, 1600, 0);
        stations.push(station);
        
       
        //planets.push(new Planet(1000, 1000, 150, 5000000));
        
        minimap = new MiniMap([Engine.n-210, Engine.n2-210, 0], 200, 200, 0.05);

        currentShip.template = 'data/ship1.json';
        SaveManager.load(currentShip);
        currentShip.core.pos = new Vec3(250, 250, 0);
        currentShip.core.inventory = [
            new Item('Fuel'),
            new Item('Ice'),
            new Item('Preserved food package')
        ];
        
        // Randomly break 3-5 components
        var numToBreak = 3 + Std.random(3);
        var shipObjects = currentShip.objects.copy();
        for (i in 0...numToBreak) {
            if (shipObjects.length == 0) break;
            var idx = Std.random(shipObjects.length);
            var obj = shipObjects.splice(idx, 1)[0];
            obj.isBroken = true;
            obj.health = 0.2 + Math.random() * 0.5;
        }
        
        new Hydroponics().setPos(60, 500);
        new Vendor().setPos(100, 500);
        new Storage().setPos(140, 500);
        new Sensor().setPos(180, 500);
        new Bed().setPos(220, 500);
        new ShipThruster().setPos(260, 500);
        new Pipe().setPos(300, 500); new Pipe().setPos(300, 460);
        new Door().setPos(340, 500);
        for(i in 0...10) new Wall().setPos(380, 500); 
        new Radiator().setPos(420, 500);
        new LiquidTank().setPos(460, 500);
        new ShipConsole().setPos(500, 500);
        new SolarPanel().setPos(540, 500);
        for(i in 0...20) new Hull().setPos(580, 500); 
        new ShipEngine().setPos(620, 500);
        new Mainframe().setPos(660, 500);
        new ShipAutopilot().setPos(700, 500);
        characters.push(new Character(300, 300));

           
        contextMenu = new ContextMenu();
        //generateRooms();

        //debugNeighbors();

        line = new Line(new Vec3(0, 0, 0), new Vec3(0, 0, 0));
        lineAngular = new Line(new Vec3(0, 0, 0), new Vec3(0, 0, 0));

        var expr = "var x = 4; 1 + 2 * x";
        var parser = new hscript.Parser();
        var ast = parser.parseString(expr);
        var interp = new hscript.Interp();
        trace(interp.execute(ast));

         */
    }

    
    public var showMinimap:Bool = true;
    public override function update(dt:Float) {
        bg.setPos(Engine.n/2, Engine.n2/2);
        /*
        try {
            bg.setPos(Engine.n/2, Engine.n2/2);
            if(paused) dt *= 0.05;

            for (planet in planets) {
                var diff = planet.pos.sub(currentShip.core.pos);
                var dist = diff.length();
                if (dist > 1) {
                    var force = diff.normalize().multiply(planet.mass / (dist * dist));
                    currentShip.core.velocity = currentShip.core.velocity.add(force.multiply(dt));
                }
            } 

            Engine.cameraOffset = new Vec3(currentShip.core.pos[0] - Engine.n/2, currentShip.core.pos[1] - Engine.n2/2, 0);

            currentShip.advance(dt);
            currentShip.traverseLogic(dt);
            updateLogicLinkHold(dt);
            SoundManager.update(dt, currentShip.core.velocity);
            FontManager.drawText('Mouse: ${mx} ${my}', 0, Engine.n2-18, 0x251f1f);
            FontManager.drawText("FPS: " + Eight.fps, 0, Engine.n2-18*2);
            FontManager.drawText('Credits: $credits', 0, Engine.n2-18*3, 0x251f1f);

            minimap.clear();
            minimap.centerWorldPos = currentShip.calculateMassCenter();
            if (showMinimap) {
                minimap.addCircle(currentShip.core.pos, 40, 0x1821AC);
                minimap.addCircle(currentShip2.core.pos, 40, 0x00FF00);
                for (station in stations) minimap.addCircle(station.manager.core.pos, 40, 0x00FF00);
                for (planet in planets) minimap.addCircle(planet.pos, Std.int(planet.radius), planet.color);
                drawProjectedTrajectory(currentShip, minimap, 15, 60);
                minimap.draw();
            }

            //currentShip2.core.rotate(-1.0*dt);
            //currentShip2.traverseCycle(dt);
            //debugConnectors();        
            for(station in stations) {
                if (Eight.distance(currentShip.core.pos, station.manager.core.pos) < 500) {
                    station.manager.traverseCycle(dt);
                } else {
                    
                }
            }

            //var forceVector:Vec3 = currentShip2.core.pos.sub(currentShip.core.pos).multiply(0.001);
            //currentShip.core.velocity = currentShip.core.velocity.add(forceVector);

            var center:Vec3 = currentShip.calculateMassCenter();
            line.pos1 = center;
            line.pos2 = center.add(currentShip.core.velocity.multiply(10));
            line.color = 0x00FF00;

            lineAngular.pos1 = center;
            lineAngular.pos2 = center.add(currentShip.core.dirV()
                .multiply(currentShip.core.angularVelocity*4).cross(new Vec3(0, 0, -1)));
        } catch (error:Dynamic) {
            trace('Error!!!');
            throw error;
        }
        */
    }

    public function debugConnectors() {
        if (Std.isOfType(Eight.currentSelected, ExtendableObject)) {
            var e:ExtendableObject = cast Eight.currentSelected;     
            var connector:Connector = currentShip.findNearestConnector(e, Game.worldPos, false);
            line.pos2 = ExtendableObject.getConnectorWorldPos(e, connector.pos);
        } 
    }

    public function debugNeighbors() {
        for(obj in currentShip.objects) {
            for(neighbor in obj.neighbors) new Line(obj.pos, neighbor.obj.pos);
        }
    }

    public static var mx:Float = 0;
    public static var my:Float = 0;
    public static var worldPos:Vec3 = new Vec3(0, 0, 0);
    public static var worldPosClicked:Vec3;
    public static var isLeftMouseDown:Bool = false;
    public static var logicLinkHoldTime:Float = 0.0;
    public static var logicLinkHoldTarget:LogicConnectorLink;
    public static var logicLinkDeletedOnHold:Bool = false;
    public var mouseMoveLine:Line;
    public function getSelectedCharacter():Character {
        for (char in characters) {
            if (char.selected) return char;
        }
        return null;
    }

    public override function onEvent(event:Event):Bool {
        mx = event.mouseX * Engine.n / Eight.screenW;
        my = Engine.n2 - (event.mouseY * Engine.n2 / Eight.screenH);
        worldPos = Engine.screenToWorld(mx, my);

        if (event.type == EventType.MouseDown) {
            if (event.button == 1) {
                isLeftMouseDown = true;
                logicLinkDeletedOnHold = false;
            }
            //mouseMoveLine.setVisible(true);
            mouseMoveLine.pos1 = worldPos;
        }
        /* if (event.type == EventType.MouseMove && mouseMoveLine.show) {
            mouseMoveLine.pos2 = worldPos;
        } */
        if (event.type == EventType.MouseUp) {
            if (event.button == 1) {
                isLeftMouseDown = false;
                if (!logicLinkDeletedOnHold) selectObject(event); //left click
                logicLinkDeletedOnHold = false;
                logicLinkHoldTarget = null;
                logicLinkHoldTime = 0.0;
            }
            if (event.button == 3) { //right click        
                var selectedChar = getSelectedCharacter();
                if (selectedChar != null) {
                    var clickedObj:Object = findObjectOnMouse(worldPos[0], worldPos[1], obj -> Std.isOfType(obj, ExtendableObject));
                    if (clickedObj != null) {
                        contextMenu.setPos(mx, my);
                        contextMenu.setVisible(true, cast clickedObj, selectedChar, worldPos);
                    } else {
                        selectedChar.setSingleJob(new MoveJob(worldPos));
                        contextMenu.setVisible(false);
                    }
                } else {
                    contextMenu.setVisible(false);
                }
            }

            mouseMoveLine.setVisible(false);
        }
        
        if (event.type == EventType.KeyDown) {
            if (event.keyCode == 32) paused = !paused; //space

            if (event.keyCode == 27) { //esc
                mainMenu.setVisible(!mainMenu.isShown);
                paused = mainMenu.isShown ? true : false;
            }

            if (event.keyCode == 122) { //z
                Engine.zoom += 0.01;
                Engine.allocBuffers(Engine.zoom);
            }
            if (event.keyCode == 120) { //x
                if (Engine.zoom > 0.5) Engine.zoom -= 0.01;
                Engine.allocBuffers(Engine.zoom);
            }

            //camera
            if (event.keyCode == 1073741903) {
                Engine.cameraOffset[0] += 5;
            }
            if (event.keyCode == 1073741904) {
                Engine.cameraOffset[0] -= 5;
            }
            if (event.keyCode == 1073741905) {
                Engine.cameraOffset[1] -= 5;
            }
            if (event.keyCode == 1073741906) {
                Engine.cameraOffset[1] += 5;
            }

            if (event.keyCode == 119) { //w
                //ShipConsole.isWPressed = true;
                mainCharacter.pos[1] += 3;
            }
            if (event.keyCode == 115) { //s
                //ShipConsole.isSPressed = true;
                mainCharacter.pos[1] -= 3;
            }
            if (event.keyCode == 113) { //q
                //ShipConsole.isQPressed = true;
            }
            if (event.keyCode == 101) { //e
                //ShipConsole.isEPressed = true;
            }
            if (event.keyCode == 97) { //A
                //ShipConsole.isAPressed = true;
                mainCharacter.pos[0] -= 3;
            }
            if (event.keyCode == 100) { //D
                //ShipConsole.isDPressed = true;
                mainCharacter.pos[0] += 3;
            }

            if (event.keyCode == 109) { //m
                if (!minimap.isExpanded && showMinimap) {
                    minimap.isExpanded = true;
                    minimap.pos = new Vec3(50, 50, 0);
                    minimap.width = Std.int(Engine.n - 100);
                    minimap.height = Std.int(Engine.n2 - 100);
                    minimap.scale = 0.01;
                } else if (minimap.isExpanded) {
                    minimap.isExpanded = false;
                    showMinimap = false;
                } else {
                    showMinimap = true;
                    minimap.pos = new Vec3(Engine.n - 210, Engine.n2 - 210, 0);
                    minimap.width = 200;
                    minimap.height = 200;
                    minimap.scale = 0.05;
                }
            }

            trace('key pressed: ' + event.keyCode);
        }

        if(event.type == EventType.KeyUp) {
            if (event.keyCode == 119) { //w
                ShipConsole.isWPressed = false;
            }
            if (event.keyCode == 115) { //s
                ShipConsole.isSPressed = false;
            }
            if (event.keyCode == 113) { //q
                ShipConsole.isQPressed = false;
            }
            if (event.keyCode == 101) { //e
                ShipConsole.isEPressed = false;
            }
            if (event.keyCode == 97) { //A
                ShipConsole.isAPressed = false;
            }
            if (event.keyCode == 100) { //D
                ShipConsole.isDPressed = false;
            }

            if (event.keyCode == 111) { // O
                orbitShipAroundPlanet(currentShip, planets[0], 400);
            }

            trace('key up: ' + event.keyCode);
        }
        
        return super.onEvent(event);
    }

    public function orbitShipAroundPlanet(ship:ExtendableManager, planet:Planet, distance:Float) {
        var angle = Math.random() * Math.PI * 2;
        var relPos = new Vec3(Math.cos(angle) * distance, Math.sin(angle) * distance, 0);
        ship.core.pos = planet.pos.add(relPos);
        
        var v = Math.sqrt(planet.mass / distance);
        var orbitVel = new Vec3(-relPos.y, relPos.x, 0).normalize().multiply(v);
        ship.core.velocity = orbitVel;
    }

    function drawProjectedTrajectory(ship:ExtendableManager, minimap:MiniMap, seconds:Float, steps:Int) {
        var dt = seconds / steps;
        var tempPos = ship.core.pos;
        var tempVel = ship.core.velocity;
        
        for (i in 0...steps) {
            var totalForce = new Vec3(0, 0, 0);
            for (planet in planets) {
                var diff = planet.pos.sub(tempPos);
                var dist = diff.length();
                if (dist > 1) {
                    var force = diff.normalize().multiply(planet.mass / (dist * dist));
                    totalForce = totalForce.add(force);
                }
            }
            
            var nextPos = tempPos.add(tempVel.multiply(dt));
            tempVel = tempVel.add(totalForce.multiply(dt));
            
            minimap.addLine(tempPos, nextPos, 0x00FF00);
            tempPos = nextPos;
        }
    }

    function getLogicManagers():Array<ExtendableManager> {
        var managers:Array<ExtendableManager> = [];
        if (currentShip != null) managers.push(currentShip);
        if (currentShip2 != null) managers.push(currentShip2);
        for (station in stations) {
            if (station != null && station.manager != null) managers.push(station.manager);
        }
        return managers;
    }

    function findHoveredLogicLink():{ manager:ExtendableManager, link:LogicConnectorLink } {
        var bestManager:ExtendableManager = null;
        var bestLink:LogicConnectorLink = null;
        var bestDistance = 99999.0;

        for (manager in getLogicManagers()) {
            for (link in manager.logicLinks) {
                var distance = link.distanceTo(worldPos);
                if (distance <= 6.0 && distance < bestDistance) {
                    bestDistance = distance;
                    bestManager = manager;
                    bestLink = link;
                }
            }
        }

        if (bestLink == null) return null;
        return { manager: bestManager, link: bestLink };
    }

    function updateLogicLinkHold(dt:Float):Void {
        if (!isLogicVisible || !isLeftMouseDown) {
            logicLinkHoldTarget = null;
            logicLinkHoldTime = 0.0;
            return;
        }

        var hovered = findHoveredLogicLink();
        if (hovered == null) {
            logicLinkHoldTarget = null;
            logicLinkHoldTime = 0.0;
            return;
        }

        if (logicLinkHoldTarget != hovered.link) {
            logicLinkHoldTarget = hovered.link;
            logicLinkHoldTime = 0.0;
            return;
        }

        logicLinkHoldTime += dt;
        if (logicLinkHoldTime >= 0.6) {
            hovered.manager.removeLogicLink(hovered.link);
            logicLinkDeletedOnHold = true;
            logicLinkHoldTarget = null;
            logicLinkHoldTime = 0.0;
        }
    }

    public inline function clearSelect() {
        for(char in characters) {
            char.select(false);
            char.setOutline(false);
        }
        for(obj in Eight.objects) {
            obj.select(false);
            obj.setOutline(false);
        }
    }

    public function selectObject(event:Event) {        
        for (i in 0...characters.length) {
            var char = characters[characters.length - 1 - i];
            if (char.checkSelect(mx, my)) {
                clearSelect();
                return char.select(true);
            }
        }

        //buttons
        var obj:Object = findObjectOnMouse(mx, my, obj -> Std.isOfType(obj, Button));
        if (obj != null) {
            //contextMenu.setPos(mx, my);
            //contextMenu.setVisible(true, obj);
            clearSelect();
            return obj.select(true);
        }        

        //game objects
        var worldPos:Vec3 = Engine.screenToWorld(mx, my);
        obj = findObjectOnMouse(worldPos[0], worldPos[1], _ -> true);
        if (obj == null) return;
        if(Std.isOfType(obj, ExtendableObject)) {
            var objExtendable:ExtendableObject = Std.downcast(obj, ExtendableObject);
            //if (objExtendable.manager != null) currentShip = objExtendable.manager;

            contextMenu.setPos(mx, my);
            contextMenu.setVisible(true, cast obj);

            clearSelect();
            return obj.select(true);
        } else if (mouseMoveLine.show == true && Std.isOfType(obj, LogicCircle) && Game.isLogicVisible) {
            var logicCircle1:LogicCircle = Std.downcast(findObjectOnMouse(mouseMoveLine.pos1[0], mouseMoveLine.pos1[1], 
                obj -> Std.isOfType(obj, LogicCircle)), LogicCircle);
            var logicCircle2:LogicCircle = Std.downcast(obj, LogicCircle);
            
            if(logicCircle1 == logicCircle2 || logicCircle1 == null || logicCircle2 == null) return;
            currentShip.connectLogic(logicCircle1.logicConnector, logicCircle2.logicConnector);
            
            clearSelect();
        } else {
            clearSelect();
            return obj.select(true);
        }
    }

    public static function findObjectOnMouse(mx:Float, my:Float, filter:Object->Bool):Object {
        for (i in 0...Eight.objects.length) {
            var obj = Eight.objects[Eight.objects.length - 1 - i];
            if (!obj.selectable) continue;

            if (obj.checkSelectUI(mx, my) && filter(obj)) {
                trace('Clicked ${obj} [${mx}, ${my}]');
                return obj;
            }
        }

        for (i in 0...Eight.objects.length) {
            var obj = Eight.objects[Eight.objects.length - 1 - i];
            if (!obj.selectable) continue;

            if (obj.checkSelect(mx, my) && filter(obj)) {
                trace('Clicked ${obj} [${mx}, ${my}]');
                return obj;
            }
        }

        return null;
    }

    public static function findObject(objects:Array<Object>, filter:Object->Bool):Object {
        for (i in 0...objects.length) {
            var obj = objects[objects.length - 1 - i];
            if (filter(obj)) {
                trace('Found ${obj} [${mx}, ${my}]');
                return obj;
            }
        }

        return null;
    }

    public static function main() {
        var game = new Game();
        game.runMainLoop();
    }
}

