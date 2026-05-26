package objects;

import objects.Extendable;
import objects.Items.Item;
import Game;
import Eight.Object;
import Eight.Engine;
import util.Texture;
import util.Math;
import hscript.Parser;
import hscript.Interp;

typedef ShipAutopilotActuator = {
    var id:String;
    var worldPos:Vec3;
    var force:Vec3;
    var fire:(Float, Float)->Void;
}

typedef StorageDetail = {
    var dx:Float;
    var dy:Float;
    var sx:Int;
    var sy:Int;
    var color:Int;
}

class GameObject extends Object {

}

class ItemVisuals {
    public static function getTexturePath(itemName:String):String {
        return switch (itemName) {
            case 'Ice': 'terrain/ice.png';
            case 'Fuel': 'ship/liquid_tank.png';
            case 'Preserved food package': 'box.png';
            case 'Food': 'station/farm.png';
            case 'Charge': 'ship/battery.png';
            case 'Blanket': 'ship/bed.png';
            case 'Reactor': 'ship/reactor.png';
            case 'Impulse plasma drive': 'ship/engine.png';
            default: 'box.png';
        };
    }
}

class AsteroidIce extends ExtendableObject {
    public function new() {
        super(20, 20, 'terrain/ice.png');
    }
}

class Wall extends ExtendableObject {
    public function new() {
        super(20, 20, 'ship/wall1.png');
        heatInF = 0.15;
        heatOutF = 0.05;

        gasPassable = false;
        o2 = 0;
    }
}

class Door extends ExtendableObject {
    public function new() {
        super(20, 20, 'ship/door_open.png');
        heatInF = 0.15;
        heatOutF = 0.05;

        gasPassable = true;
        o2 = 0;
    }
}

class Hull extends ExtendableObject {
    public function new() {
        super(20, 20, 'ship/hull2.png');
        heatInF = 0.15;
        heatOutF = 0.05;
    }
}

class Vendor extends ExtendableObject {
    public var marketInventory:Array<Item> = [];

    public function new() {
        super(40, 40, 'station/vendor.png');
        heatInF = 0.15;
        heatOutF = 0.05;
        marketInventory = [
            new Item('Ice'),
            new Item('Preserved food package'),
            new Item('Fuel'),
            new Item('Reactor'),
            new Item('Impulse plasma drive')
        ];
        inventory = [];
    }

    public function getTradeStorage():Storage {
        var objects = manager != null ? manager.objects : Game.currentShip.objects;
        var nearest:Storage = null;
        var nearestDistance = 1e9;

        for (obj in Game.currentShip.objects) {
            var storage:Storage = Std.downcast(obj, Storage);
            if (storage == null) continue;

            var distance = Eight.distance(pos, storage.pos);
            if (distance < nearestDistance) {
                nearestDistance = distance;
                nearest = storage;
            }
        }

        return nearest;
    }
}

class Storage extends ExtendableObject {
    var detailSprites:Array<Object> = [];
    var itemSprites:Array<Object> = [];
    static inline var maxItemSprites:Int = 9;

    public function new() {
        super(20, 20, null, 0xFF5B4931);
        heatInF = 0.12;
        heatOutF = 0.03;
        gasPassable = false;
        o2 = 0;

        for (detail in buildDetailLayout()) {
            var sprite = new Object(detail.sx, detail.sy, null, detail.color);
            sprite.selectable = false;
            detailSprites.push(sprite);
        }

        for (i in 0...maxItemSprites) {
            var sprite = new Object(12, 12, 'box.png');
            sprite.selectable = false;
            sprite.setVisible(false);
            itemSprites.push(sprite);
        }
    }

    function buildDetailLayout():Array<StorageDetail> {
        var palette = [0xFF493926, 0xFF6C5639, 0xFF8D744C, 0xFF241D14];
        var seed = id;
        var details:Array<StorageDetail> = [];

        var pick = (salt:Int, max:Int) -> {
            if (max <= 0) return 0;
            return Std.int(Math.abs((seed * 1103515245 + salt * 92821 + 12345) % max));
        };

        details.push({ dx: 0, dy: 0, sx: 18, sy: 18, color: palette[pick(1, palette.length)] });
        details.push({ dx: 0, dy: 5, sx: 14, sy: 2, color: palette[3] });
        details.push({ dx: 0, dy: -5, sx: 14, sy: 2, color: palette[3] });

        var stripCount = 2 + pick(2, 2);
        for (i in 0...stripCount) {
            details.push({
                dx: -4 + pick(10 + i, 9),
                dy: -4 + i * 4,
                sx: 4 + pick(30 + i, 5),
                sy: 2,
                color: palette[1 + pick(50 + i, 2)]
            });
        }

        var studs = [
            { dx: -6.0, dy: -6.0 },
            { dx: 6.0, dy: -6.0 },
            { dx: -6.0, dy: 6.0 },
            { dx: 6.0, dy: 6.0 }
        ];
        for (i in 0...studs.length) {
            if (pick(80 + i, 100) < 75) {
                details.push({ dx: studs[i].dx, dy: studs[i].dy, sx: 2, sy: 2, color: palette[3] });
            }
        }

        return details;
    }

    function getInventoryAnchor():util.Math.Vec3 {
        return new util.Math.Vec3(pos[0] - 6, pos[1] + 6, 0);
    }

    function syncDetails():Void {
        var details = buildDetailLayout();
        for (i in 0...detailSprites.length) {
            var sprite = detailSprites[i];
            var detail = details[i];
            if (sprite == null || detail == null) continue;

            sprite.setPos(pos[0] + detail.dx, pos[1] + detail.dy);
            sprite.angle = angle;
            sprite.setVisible(show);
        }
    }

    function drawInventorySprites():Void {
        var anchor = getInventoryAnchor();
        for (i in 0...itemSprites.length) {
            var sprite = itemSprites[i];
            if (sprite == null) continue;

            if (i < inventory.length) {
                var item = inventory[i];
                sprite.loadTexture(ItemVisuals.getTexturePath(item.name));
                sprite.setPos(anchor[0] + (i % 3) * 12, anchor[1] - Std.int(i / 3) * 12);
                sprite.angle = angle;
                sprite.setVisible(true);
            } else {
                sprite.setVisible(false);
            }
        }
    }

    public override function draw() {
        syncDetails();
        drawInventorySprites();
        if (selected) {
            FontManager.drawText('Storage inventory: ${inventory.length}', 500, 136, 0x2e2323);
            for (i in 0...inventory.length) {
                if (i >= 8) {
                    FontManager.drawText('...', 500, 118 - 18 * 8, 0x251f1f);
                    break;
                }
                FontManager.drawText('${i + 1}. ${inventory[i].name}', 500, 118 - 18 * i, 0x251f1f);
            }
            if (inventory.length == 0) {
                FontManager.drawText('empty', 500, 118, 0x251f1f);
            }
        }
        super.draw();
    }

    public override function destroy():Void {
        for (sprite in detailSprites) {
            if (sprite != null) sprite.destroy();
        }
        for (sprite in itemSprites) {
            if (sprite != null) sprite.destroy();
        }
        super.destroy();
    }
}

class Hydroponics extends ExtendableObject {
    public function new() {
        super(40, 40, 'station/farm.png');
        zlayer = 1;
        heatInF = 0.15;
        heatOutF = 0.05;
        inventory = [
            new Item('Food')
        ];
    }
}

class Sensor extends ExtendableObject {
    public function new() {
        super(20, 20, 'ship/sensor.png');
        heatInF = 0.15;
        heatOutF = 0.05;
    }
}

class ShipCore extends ExtendableObject {
    public function new() {
        super(20, 20, 'ship/ship_core.png');
        heatInF = 0.15;
        heatOutF = 0.05;
    }
    /* public function addToVelocity(dir:Vec3) {
        var cos:Float = FastTrig.fastcos(angle); var sin:Float = FastTrig.fastsin(angle);
        
        var lx = dir[0] * cos - dir[1] * sin;
        var ly = dir[0] * sin + dir[1] * cos;

        velocity = velocity.add(new Vec3(lx, ly, 0));
    } */

    public override function update(dt:Float) {
        pos[0] += velocity[0] * dt;
        pos[1] += velocity[1] * dt;
    } 
}

class SolarPanel extends ExtendableObject {
    public var efficiencyF = 0.2;
    public function new() {
        super(40, 40, 'solar_panel.png');
        heatInF = 0.9;
        heatOutF = 0.01;

        currentConductivity = 1;
        currentGeneration = 1;

        o2 = 0;

        gasPassable = false;
    }

    /* public override inline function generateConnectors():Array<Vec3> {
        return [
            [-Std.int(sizeX / 2), 0, 0], //LEFT
            [Std.int(sizeX / 2), 0, 0],  //RIGHT
            [0, -Std.int(sizeY / 2), 0], //BOTTOM
            [0, Std.int(sizeY / 2), 0]   //TOP
        ];
    } */
}

class Radiator extends ExtendableObject {    
    public function new() {
        super(20, 20, 'radiator.png');
        heatInF = 0.1;
        heatOutF = 0.8;

        gasPassable = false;
    }
}

class Battery extends ExtendableObject {
    public function new() {
        super(20, 20, 'ship/liquid_tank.png');
        inventory = [
            new Item('Charge')
        ];
    }

}

class Bed extends ExtendableObject {
    public function new() {
        super(20, 40, 'ship/bed.png');

        gasPassable = true;
        inventory = [
            new Item('Blanket')
        ];
    }

    /* public override inline function generateConnectors():Array<Vec3> {
        return [
            new Connector([-Std.int(sizeX / 2), -Std.int(sizeY / 2), 0]), //LEFT BOTTOM 
            new Connector([Std.int(sizeX / 2), -Std.int(sizeY / 2), 0]), //RIGHT BOTTOM
            new Connector([Std.int(sizeX / 2), Std.int(sizeY / 2), 0]),  //RIGHT TOP
            new Connector([-Std.int(sizeX / 2), Std.int(sizeY / 2), 0]), //LEFT TOP
        ];
    } */
}

class ShipConsole extends ExtendableObject {    

    public static var isWPressed:Bool = false;
    public static var isQPressed:Bool = false;
    public static var isEPressed:Bool = false;
    public static var isAPressed:Bool = false;
    public static var isDPressed:Bool = false;
    public static var isSPressed:Bool = false;

    public function new() {
        super(20, 20, 'ship/ship_console.png');

        noClip = false;
    }

    public override function generateConnectors():Array<Connector> {
        return [
            new Connector([0, 0, 0], 2), //CENTER
        ];
    }

    public override function generateLogicConnectors():Array<LogicConnector> {
        return [
            new LogicConnector([-Std.int(sizeX / 2), Std.int(sizeX / 2), 0], this, false, (signal:Bool, dt:Float) -> { //LEFT
                if (isQPressed) {
                    return true;
                }
                return false;
            }, "Q", "TurnLeft Out"), 
            new LogicConnector([Std.int(sizeX / 2), Std.int(sizeX / 2), 0], this, false, (signal:Bool, dt:Float) -> { //RIGHT
                if (isEPressed) {
                    return true;
                }
                return false;
            }, "E", "TurnRight Out"), 
            new LogicConnector([-Std.int(sizeX / 2), 0, 0], this, false, (signal:Bool, dt:Float) -> { //LEFT
                if (isAPressed) {
                    return true;
                }
                return false;
            }, "A", "StrafeRight Out"), 
            new LogicConnector([Std.int(sizeX / 2), 0, 0], this, false, (signal:Bool, dt:Float) -> { //RIGHT
                if (isDPressed) {
                    return true;
                }
                return false;
            }, "D", "StrafeLeft Out"),             
            
            new LogicConnector([0, -Std.int(sizeY / 2), 0], this, false, (signal:Bool, dt:Float) -> { //BOTTOM
                if (isSPressed) {
                    return true;
                }
                return false;
            }, "S", "Reverse Out"),  
            new LogicConnector([0, Std.int(sizeY / 2), 0], this, false, (signal:Bool, dt:Float) -> { //TOP
                if (isWPressed) {
                    return true;
                }
                return false;
            }, "W", "Thrust Out")  
        ];
    }
}

class ShipAutopilot extends ExtendableObject {
    var isEnabled:Bool = true;
    var rotationIntegral:Float = 0.0;
    var cmdTurnLeft:Bool = false;
    var cmdTurnRight:Bool = false;
    var cmdStrafeRight:Bool = false;
    var cmdStrafeLeft:Bool = false;
    var cmdBackward:Bool = false;
    var cmdForward:Bool = false;

    public function new() {
        super(20, 20, 'ship/sensor.png');
        noClip = false;
    }

    public override function generateConnectors():Array<Connector> {
        return [
            new Connector([0, 0, 0], 2)
        ];
    }

    public override function generateLogicConnectors():Array<LogicConnector> {
        return [
            new LogicConnector([0, Std.int(sizeY / 2), 0], this, true, (signal:Bool, dt:Float) -> {
                if (signal) {
                    setEnabled(true);
                }
                return false;
            }, "", "Turn On In"),
            new LogicConnector([0, -Std.int(sizeY / 2), 0], this, true, (signal:Bool, dt:Float) -> {
                if (signal) {
                    setEnabled(false);
                }
                return false;
            }, "", "Turn Off In"),
            new LogicConnector([-Std.int(sizeX / 2), 15, 0], this, true, (signal:Bool, dt:Float) -> {
                cmdTurnLeft = signal;
                return false;
            }, "Q", "TurnLeft In"),
            new LogicConnector([-Std.int(sizeX / 2), 5, 0], this, true, (signal:Bool, dt:Float) -> {
                cmdTurnRight = signal;
                return false;
            }, "E", "TurnRight In"),
            new LogicConnector([-Std.int(sizeX / 2), -5, 0], this, true, (signal:Bool, dt:Float) -> {
                cmdStrafeRight = signal;
                return false;
            }, "A", "StrafeRight In"),
            new LogicConnector([-Std.int(sizeX / 2), -15, 0], this, true, (signal:Bool, dt:Float) -> {
                cmdStrafeLeft = signal;
                return false;
            }, "D", "StrafeLeft In"),
            new LogicConnector([Std.int(sizeX / 2), 10, 0], this, true, (signal:Bool, dt:Float) -> {
                cmdBackward = signal;
                return false;
            }, "S", "Reverse In"),
            new LogicConnector([Std.int(sizeX / 2), -10, 0], this, true, (signal:Bool, dt:Float) -> {
                cmdForward = signal;
                return false;
            }, "W", "Thrust In")
        ];
    }

    inline function setEnabled(value:Bool):Void {
        isEnabled = value;

        var ship = manager != null ? manager : Game.currentShip;
        if (ship == null || ship.core == null) return;

        if (isEnabled) {
            rotationIntegral = 0.0;
        } else {
            rotationIntegral = 0.0;
        }
    }

    inline function cross2(a:Vec3, b:Vec3):Float {
        return a[0] * b[1] - a[1] * b[0];
    }

    inline function normalizedDot(a:Vec3, b:Vec3):Float {
        var aLen = a.length();
        var bLen = b.length();
        if (aLen == 0 || bLen == 0) return 0;
        return a.dot(b) / (aLen * bLen);
    }

    function collectActuators(ship:ExtendableManager):Array<ShipAutopilotActuator> {
        var result:Array<ShipAutopilotActuator> = [];

        for (obj in ship.objects) {
            if (Std.isOfType(obj, objects.Pipe.ShipThruster)) {
                var thruster:objects.Pipe.ShipThruster = cast obj;
                thruster.resetControlTargets();
                if (thruster.fuel <= 0) continue;
                result.push({
                    id: 'thruster_${thruster.id}',
                    worldPos: thruster.getActuatorPos(),
                    force: thruster.getActuatorForce(),
                    fire: (dt:Float, throttle:Float) -> thruster.burnThrottle(dt, throttle)
                });
            } else if (Std.isOfType(obj, objects.Pipe.ShipEngine)) {
                var engine:objects.Pipe.ShipEngine = cast obj;
                engine.resetControlTargets();
                if (engine.fuel <= 0) continue;
                result.push({
                    id: 'engine_main_${engine.id}',
                    worldPos: engine.getMainActuatorPos(),
                    force: engine.getMainActuatorForce(),
                    fire: (dt:Float, throttle:Float) -> engine.burnMainThrottle(dt, throttle)
                });
                result.push({
                    id: 'engine_left_${engine.id}',
                    worldPos: engine.getLeftActuatorPos(),
                    force: engine.getLeftActuatorForce(),
                    fire: (dt:Float, throttle:Float) -> engine.burnLeftThrottle(dt, throttle)
                });
                result.push({
                    id: 'engine_right_${engine.id}',
                    worldPos: engine.getRightActuatorPos(),
                    force: engine.getRightActuatorForce(),
                    fire: (dt:Float, throttle:Float) -> engine.burnRightThrottle(dt, throttle)
                });
            }
        }

        return result;
    }

    function limitCandidates(actuators:Array<ShipAutopilotActuator>, score:(ShipAutopilotActuator)->Float, maxCount:Int):Array<ShipAutopilotActuator> {
        var sorted = actuators.copy();
        sorted.sort((a, b) -> {
            var sa = score(a);
            var sb = score(b);
            return sa > sb ? -1 : (sa < sb ? 1 : 0);
        });
        if (sorted.length > maxCount) {
            sorted.splice(maxCount, sorted.length - maxCount);
        }
        return sorted;
    }

    function chooseTranslation(actuators:Array<ShipAutopilotActuator>, desiredDir:Vec3, center:Vec3):Array<ShipAutopilotActuator> {
        var candidates = [];
        for (actuator in actuators) {
            var align = normalizedDot(actuator.force, desiredDir);
            if (align > 0.15) candidates.push(actuator);
        }

        candidates = limitCandidates(candidates, actuator -> normalizedDot(actuator.force, desiredDir), 12);

        if (candidates.length == 0) return [];

        var bestScore = -1e18;
        var best:Array<ShipAutopilotActuator> = [];
        var subsetCount = 1 << candidates.length;

        for (mask in 1...subsetCount) {
            var force = new Vec3(0, 0, 0);
            var torque = 0.0;
            var current:Array<ShipAutopilotActuator> = [];

            for (i in 0...candidates.length) {
                if ((mask & (1 << i)) == 0) continue;
                var actuator = candidates[i];
                current.push(actuator);
                force = force.add(actuator.force);
                torque += cross2(actuator.worldPos.sub(center), actuator.force);
            }

            var forward = force.dot(desiredDir);
            if (forward <= 0) continue;

            var lateral = Math.abs(cross2(force, desiredDir));
            var score = forward * 2.5 - lateral * 3.5 - Math.abs(torque) * 0.45 - current.length * 0.05;

            if (score > bestScore) {
                bestScore = score;
                best = current;
            }
        }

        return best;
    }

    function chooseRotation(actuators:Array<ShipAutopilotActuator>, desiredSign:Float, center:Vec3):Array<ShipAutopilotActuator> {
        var candidates = [];
        for (actuator in actuators) {
            var torque = cross2(actuator.worldPos.sub(center), actuator.force) * desiredSign;
            if (torque > 0.02) candidates.push(actuator);
        }

        candidates = limitCandidates(candidates, actuator -> cross2(actuator.worldPos.sub(center), actuator.force) * desiredSign, 12);

        if (candidates.length == 0) return [];

        var bestScore = -1e18;
        var best:Array<ShipAutopilotActuator> = [];
        var subsetCount = 1 << candidates.length;

        for (mask in 1...subsetCount) {
            var force = new Vec3(0, 0, 0);
            var torque = 0.0;
            var current:Array<ShipAutopilotActuator> = [];

            for (i in 0...candidates.length) {
                if ((mask & (1 << i)) == 0) continue;
                var actuator = candidates[i];
                current.push(actuator);
                force = force.add(actuator.force);
                torque += cross2(actuator.worldPos.sub(center), actuator.force);
            }

            var signedTorque = torque * desiredSign;
            if (signedTorque <= 0) continue;

            var score = signedTorque * 2.0 - force.length() * 3.2 - current.length * 0.04;

            if (score > bestScore) {
                bestScore = score;
                best = current;
            }
        }

        return best;
    }

    inline function clamp(v:Float, minV:Float, maxV:Float):Float {
        return Math.max(minV, Math.min(maxV, v));
    }

    inline function addSelection(selected:Map<String, ShipAutopilotActuator>, throttles:Map<String, Float>, actuator:ShipAutopilotActuator, throttle:Float) {
        if (throttle <= 0) return;
        selected.set(actuator.id, actuator);
        var current = throttles.exists(actuator.id) ? throttles.get(actuator.id) : 0.0;
        if (throttle > current) {
            throttles.set(actuator.id, throttle);
        }
    }

    function rotationPidOutput(ship:ExtendableManager, dt:Float):Float {
        var angularVelocity = ship.core.angularVelocity;
        if (Math.abs(angularVelocity) < 0.02) {
            ship.core.angularVelocity = 0;
            rotationIntegral = 0.0;
            return 0.0;
        }

        var error = -angularVelocity;
        rotationIntegral = clamp(rotationIntegral + error * dt, -2.0, 2.0);

        var kp = 1.15;
        var ki = 0.18;
        var kd = 0.0;
        var output = kp * error + ki * rotationIntegral - kd * angularVelocity;

        return clamp(output, -1.0, 1.0);
    }

    public override function update(dt:Float) {
        super.update(dt);
        /*
        var ship = manager != null ? manager : Game.currentShip;
        if (ship == null || ship.core == null) return;

        var actuators = collectActuators(ship);
        if (actuators.length == 0) return;
        if (!isEnabled) return;

        var center = ship.calculateMassCenter();
        var forward = ship.core.dirV().normalize();
        var right = new Vec3(FastTrig.fastcos(ship.core.getAngle()), FastTrig.fastsin(ship.core.getAngle()), 0).normalize();

        var selected:Map<String, ShipAutopilotActuator> = new Map();
        var throttles:Map<String, Float> = new Map();
        var turn = (cmdTurnRight ? 1 : 0) - (cmdTurnLeft ? 1 : 0);
        var strafe = (cmdStrafeLeft ? 1 : 0) - (cmdStrafeRight ? 1 : 0);
        var move = (cmdForward ? 1 : 0) - (cmdBackward ? 1 : 0);
        var rotationCorrection = turn == 0 ? rotationPidOutput(ship, dt) : 0.0;
        var manualMoveThrottle = 0.42;
        var manualTurnThrottle = 0.45;

        if (turn != 0) {
            for (actuator in chooseRotation(actuators, turn, center)) {
                addSelection(selected, throttles, actuator, manualTurnThrottle);
            }
            rotationIntegral = 0.0;
        } else if (Math.abs(rotationCorrection) > 0.001) {
            var stabilizeThrottle = clamp(Math.abs(rotationCorrection) * 0.3, 0.04, 0.24);
            for (actuator in chooseRotation(actuators, rotationCorrection, center)) {
                addSelection(selected, throttles, actuator, stabilizeThrottle);
            }
        }

        if (strafe != 0) {
            var strafeDir = right.multiply(-strafe);
            for (actuator in chooseTranslation(actuators, strafeDir, center)) {
                addSelection(selected, throttles, actuator, manualMoveThrottle);
            }
        }

        if (move != 0) {
            var moveDir = forward.multiply(move);
            for (actuator in chooseTranslation(actuators, moveDir, center)) {
                addSelection(selected, throttles, actuator, manualMoveThrottle);
            }
        }

        for (actuator in selected) {
            actuator.fire(dt, throttles.get(actuator.id));
        }
        */
    }

    public override function draw() {
        if (selected) {
            FontManager.drawText('AP Q/E rotate, A/D strafe, W/S thrust', 600, 200, 0x251f1f);
            FontManager.drawText('Enabled: ' + isEnabled, 600, 182, 0x251f1f);
            FontManager.drawText('Angular: ' + shipAngularText(), 600, 164, 0x251f1f);
        }
        super.draw();
    }

    inline function shipAngularText():String {
        var ship = manager != null ? manager : Game.currentShip;
        if (ship == null || ship.core == null) return 'n/a';
        return Std.string(ship.core.angularVelocity);
    }
}

class Planet extends GameObject {
    public var mass:Float;
    public var radius:Float;
    var noiseSeed:Int;

    public function new(x:Float, y:Float, radius:Float, mass:Float) {
        super(Std.int(radius * 2), Std.int(radius * 2), null, 0xFF5555FF);
        this.radius = radius;
        this.mass = mass;
        this.noiseSeed = Std.random(1000000);
        setPos(x, y);
    }

    public override function draw() {
        if(!show) return;
        if (Eight.frameNumber % 2 == 0) return;

        var r2 = radius * radius;
        var cx = radius;
        var cy = radius;

        for (x in 0...sizeX) {
            for (y in 0...sizeY) {
                var dx = x - cx;
                var dy = y - cy;
                var dist2 = dx * dx + dy * dy;
                if (dist2 <= r2) {
                    var noise = Math.sin((x + noiseSeed) * 0.1) * Math.cos((y + noiseSeed) * 0.1);
                    var c = color;
                    if (noise > 0.5) c = 0xFF7777FF;
                    else if (noise < -0.5) c = 0xFF3333BB;

                    Engine.drawDot(pos.x + dx, pos.y + dy, 0, c, isUI);
                }
            }
        }
    }
}


class Mainframe extends ExtendableObject {
    public var script:String = "setOut(0, getIn(0));\nsetOut(1, getIn(1));\nsetOut(2, time % 2 < 1);\nsetOut(3, true);";
    public var inputSignals:Array<Bool> = [false, false];
    public var outputSignals:Array<Bool> = [false, false, false, false];
    public var lastError:String = "";

    var parser:Parser;
    var interp:Interp;
    var compiledExpr:Dynamic;

    public function new() {
        super(20, 20, 'ship/sensor.png');
        noClip = false;
        parser = new Parser();
        interp = new Interp();
        compileScript();
    }

    public function compileScript() {
        try {
            compiledExpr = parser.parseString(script);
            lastError = "";
        } catch (error:Dynamic) {
            compiledExpr = null;
            lastError = Std.string(error);
        }
    }

    public function runScript(dt:Float) {
        if (compiledExpr == null) return;

        for (i in 0...outputSignals.length) outputSignals[i] = false;

        interp = new Interp();
        interp.variables.set("dt", dt);
        interp.variables.set("time", haxe.Timer.stamp());
        interp.variables.set("getIn", (index:Int) -> {
            return index >= 0 && index < inputSignals.length ? inputSignals[index] : false;
        });
        interp.variables.set("setOut", (index:Int, signal:Bool) -> {
            if (index >= 0 && index < outputSignals.length) outputSignals[index] = signal;
            return signal;
        });

        try {
            interp.execute(compiledExpr);
            lastError = "";
        } catch (error:Dynamic) {
            lastError = Std.string(error);
        }
    }

    public override function update(dt:Float) {
        super.update(dt);
        runScript(dt);
    }

    public override function generateLogicConnectors():Array<LogicConnector> {
        return [
            new LogicConnector([-Std.int(sizeX / 2), 10, 0], this, true, (signal:Bool, dt:Float) -> {
                inputSignals[0] = signal;
                return false;
            }, "IN0", "Script In"),
            new LogicConnector([-Std.int(sizeX / 2), -10, 0], this, true, (signal:Bool, dt:Float) -> {
                inputSignals[1] = signal;
                return false;
            }, "IN1", "Script In"),
            new LogicConnector([Std.int(sizeX / 2), 15, 0], this, false, (signal:Bool, dt:Float) -> {
                return outputSignals[0];
            }, "OUT0", "Script Out"),
            new LogicConnector([Std.int(sizeX / 2), 5, 0], this, false, (signal:Bool, dt:Float) -> {
                return outputSignals[1];
            }, "OUT1", "Script Out"),
            new LogicConnector([Std.int(sizeX / 2), -5, 0], this, false, (signal:Bool, dt:Float) -> {
                return outputSignals[2];
            }, "OUT2", "Script Out"),
            new LogicConnector([Std.int(sizeX / 2), -15, 0], this, false, (signal:Bool, dt:Float) -> {
                return outputSignals[3];
            }, "OUT3", "Script Out")
        ];
    }

    public override function draw() {
        if (selected) {
            FontManager.drawText('Inputs: ${inputSignals[0]} ${inputSignals[1]}', 500, 10, 0x251f1f);
            FontManager.drawText('Outputs: ${outputSignals[0]} ${outputSignals[1]} ${outputSignals[2]} ${outputSignals[3]}', 500, 28, 0x251f1f);
            if (lastError != "") {
                FontManager.drawText(lastError, 500, 46, 0x251f1f);
            }
        }
        super.draw();
    }
}
