package objects;

import Eight;
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
import objects.Items;

class Connector {
    public var pos:Vec3;
    public var type:Int;

    public function new(_pos:Vec3, _type:Int=0) {
        pos = _pos;
        type = _type;
    }

    public function draw() {

    }
}

class ConnectorLink {
    public var connected:ExtendableObject;
    public var from:Vec3;
    public var to:Vec3;

    public function new(_connected:ExtendableObject, _from:Vec3, _to:Vec3) {
        connected = _connected;
        from = _from;
        to = _to;
    }
}

class LogicConnector extends Connector {
    public var circle:Circle;
    public var obj:ExtendableObject;
    public var isIn:Bool;
    public var callback:(Bool, Float)->Bool;
    public var labelKey:String;
    public var labelDesc:String;
    
    public override function new(_pos:Vec3, _obj:ExtendableObject, _isIn:Bool, _callback:(Bool, Float)->Bool, _labelKey:String="", _labelDesc:String="") {
        super(_pos);
        isIn = _isIn;
        obj = _obj;
        callback = _callback;
        labelKey = _labelKey;
        labelDesc = _labelDesc;
        circle = new LogicCircle(ExtendableObject.getConnectorWorldPos(obj, pos), 3, this, isIn ? 0xFF0101 : 0x04FF19);
        circle.selectable = true;
    }

    inline function isHovered():Bool {
        return Eight.distance(Game.worldPos, circle.pos) <= 8;
    }

    inline function getTooltipText():String {
        if (labelKey == "" && labelDesc == "") return isIn ? "Logic In" : "Logic Out";
        if (labelKey == "") return labelDesc;
        if (labelDesc == "") return labelKey;
        return labelKey + " " + labelDesc;
    }

    public override function draw() {
        circle.setVisible(Game.isLogicVisible ? true : false);
        //circle.color = isIn ? 0xFF0101 : 0x04FF19;
        circle.pos = ExtendableObject.getConnectorWorldPos(obj, pos);

        if (Game.isLogicVisible && isHovered()) {
            FontManager.drawText(getTooltipText(), Std.int(Game.mx + 14), Std.int(Game.my + 14));
        }
    }
}

class LogicCircle extends Circle {
    public var logicConnector:LogicConnector;

    public function new(_pos:Vec3, _r:Int, _logicConnector:LogicConnector, _color:Int) {
        super(_pos, _r, null, _color);
        logicConnector = _logicConnector;
    }
}

class LogicConnectorLink {
    public var from:LogicConnector;
    public var to:LogicConnector;
    public var line:Line;

    public function new(_from:LogicConnector, _to:LogicConnector) {
        from = _from;
        to = _to;

        line = new Line(from.circle.pos, to.circle.pos);
    }

    public inline function getFromPos():Vec3 {
        return ExtendableObject.getConnectorWorldPos(from.obj, from.pos);
    }

    public inline function getToPos():Vec3 {
        return ExtendableObject.getConnectorWorldPos(to.obj, to.pos);
    }

    public function distanceTo(point:Vec3):Float {
        var a = getFromPos();
        var b = getToPos();
        var ab = b.sub(a);
        var ap = point.sub(a);
        var abLenSq = ab.dot(ab);
        if (abLenSq <= 0.0001) return Eight.distance(point, a);

        var t = Math.max(0.0, Math.min(1.0, ap.dot(ab) / abLenSq));
        var closest = a.add(ab.multiply(t));
        return Eight.distance(point, closest);
    }

    public inline function isHovered(point:Vec3, radius:Float = 6.0):Bool {
        return distanceTo(point) <= radius;
    }

    public function draw(dt:Float) {
        line.setVisible(Game.isLogicVisible ? true : false);
        line.pos1 = getFromPos();
        line.pos2 = getToPos();
        line.color = this == Game.logicLinkHoldTarget ? 0xFF6A5C : (isHovered(Game.worldPos) ? 0xFFD27A : 0xD6D3D3);
    }
}

class Neighbor {
    public var obj:ExtendableObject;
    public var type:Int;

    public function new(obj:ExtendableObject, type:Int) {
        this.obj = obj;
        this.type = type;
    }
}

class ExtendableObject extends GameObject {
    public var id:Int;
    static var nextId:Int = Std.int(haxe.Timer.stamp() * 1000) + Std.random(1000);

    public var manager:ExtendableManager;
    public var connectors:Array<Connector> = [];
    public var linked:Array<ConnectorLink> = [];
    public var noClip = true;
    public var neighbors:Array<Neighbor> = [];
    public var neighborsFuel:Array<Neighbor> = []; //1

    public var logicConnectors:Array<LogicConnector> = [];

    public function new(sizeX:Int=61, sizeY:Int=61, texturePath:String=null, _color:Int=0x000000) {
        super(sizeX, sizeY, texturePath, _color);
        selectable = true;

        connectors = generateConnectors();
        logicConnectors = generateLogicConnectors();

        id = nextId++;// = Std.int(haxe.Timer.stamp() * 1000) + Std.random(1000);
    }

    public function dirV():Vec3 {
        var cos:Float = FastTrig.fastcos(getAngle()); var sin:Float = FastTrig.fastsin(getAngle());
        return (new Vec3(cos, sin, 0)).cross(new Vec3(0, 0, -1));
    }

    public function addToVelocity(dir:Vec3) {
        var cos:Float = FastTrig.fastcos(getAngle()); var sin:Float = FastTrig.fastsin(getAngle());
        
        var lx = dir[0] * cos - dir[1] * sin;
        var ly = dir[0] * sin + dir[1] * cos;

        velocity = velocity.add(new Vec3(lx, ly, 0));
    }

    public function addToVelocityDirect(dir:Vec3) {
        velocity = velocity.add(dir);
    }

    public function generateConnectors():Array<Connector> {
        return [
            new Connector([-Std.int(sizeX / 2), -Std.int(sizeY / 2), 0]), //LEFT BOTTOM 
            new Connector([Std.int(sizeX / 2), -Std.int(sizeY / 2), 0]), //RIGHT BOTTOM
            new Connector([Std.int(sizeX / 2), Std.int(sizeY / 2), 0]),  //RIGHT TOP
            new Connector([-Std.int(sizeX / 2), Std.int(sizeY / 2), 0]), //LEFT TOP

            new Connector([0, 0, 0], 2), //CENTER

            /* new Connector([0, -Std.int(sizeX / 2), 0], 1), 
            new Connector([Std.int(sizeX / 2), 0, 0], 1), 
            new Connector([0, Std.int(sizeX / 2), 0], 1),  
            new Connector([-Std.int(sizeX / 2), 0, 0], 1), */
        ];
    }

    public function generateLogicConnectors():Array<LogicConnector> {
        return [];
    }

    public var mass:Float = 10.0;
    public var velocity:Vec3 = new Vec3(0, 0, 0);
    public var angularVelocity:Float = 0.0;

    public var isBroken:Bool = false;
    public var health:Float = 1.0;
    public var inventory:Array<Item> = [];

    public var fuel:Float = 0.0;

    public var heat:Float = 0;
    public var heatConductivityF = 0.8; //conductivity
    public var heatInF:Float = 0.15; //absorptivity
    public var heatOutF:Float = 0.05; //emission

    public var current:Float = 0;
    public var currentConductivity:Float = 0;
    public var currentGeneration:Float = 0;

    public var gasPassable:Bool = true;
    public var o2:Float = 21;
    public var co2:Float = 0.42;

    public inline function placeAccordingly(connected:ExtendableObject, from:Vec3, to:Vec3) {      
        var _cos:Float = FastTrig.fastcos(getAngle()); var _sin:Float = FastTrig.fastsin(getAngle());
        var lx:Float = from[0]-to[0]; var ly:Float = from[1]-to[1];
        var posX:Float = (lx) * _cos - (ly) * _sin;
        var posY:Float = (lx) * _sin + (ly) * _cos;

        connected.setPos(pos[0]+posX, pos[1]+posY, 0);
        connected.angle = getAngle(); 
    }

    public inline function calculateMechanics(dt:Float) {
        if(neighbors.length != 0) {
            var randomNeighbor:Neighbor = neighbors[Std.random(neighbors.length)];
            if (randomNeighbor.obj.gasPassable) {
                var o2Transfer:Float = Math.abs(o2 - randomNeighbor.obj.o2) * dt;
                if (randomNeighbor.obj.o2 < o2) {
                    randomNeighbor.obj.o2 += o2Transfer;
                    o2 -= o2Transfer;
                } else {
                    randomNeighbor.obj.o2 -= o2Transfer;
                    o2 += o2Transfer;
                }
            }
        }

        if(neighborsFuel.length != 0) {
            for (randomNeighbor in neighborsFuel) {
                //trace(this, randomNeighbor.obj);
                var fuelTransfer:Float = Math.abs(fuel - randomNeighbor.obj.fuel) * dt * 0.1;
                if (randomNeighbor.obj.fuel < fuel) {
                    randomNeighbor.obj.fuel += fuelTransfer;
                    fuel -= fuelTransfer;
                } else {
                    randomNeighbor.obj.fuel -= fuelTransfer;
                    fuel += fuelTransfer;
                }
            }
        }
    }

    public inline function rotateConnected(dt:Float) {        
        var i = -1; while(++i < linked.length) {
            try {
                var link:ConnectorLink = linked[i];
                var connected:ExtendableObject = link.connected;
                var from:Vec3 = link.from;
                var to:Vec3 = link.to;

                placeAccordingly(connected, from, to);

                var heatTransfer:Float = (heat - connected.heat) * heatConductivityF * dt * 0.1;
                connected.heat += heatTransfer;
                heat -= heatTransfer;            

                var currentTransfer:Float = Math.abs(current - connected.current) * currentConductivity;
                if (connected.current < current) {
                    connected.current += currentTransfer;
                    current -= currentTransfer;
                } else {
                    connected.current -= currentTransfer;
                    current += currentTransfer;
                }

            } catch (error:Dynamic) {
                trace('Error!!!');
                throw('Failed to link extendable ${error}');
            }
        } 
        

        if (!isBroken) {
            heat += ((1e7 - heat) / 1e6) * 1360 * heatInF * dt * 0.1;
            heat -= ((-3e5 - heat) / -3e5) * heat * heatOutF * dt * 0.1;
            current += currentGeneration * dt * 0.1;
        } else {
            health = Math.max(0, health - dt * 0.002);
        }
    }

    public override function draw() {
        if (!show) return;
        if (selected) {
            FontManager.drawText(Type.getClassName(Type.getClass(this)), 500, 100+18*2, 0x2e2323);

            FontManager.drawText('Fuel: $fuel', 500, 100+18*1, 0x2e2323);

            FontManager.drawText('Temperature: ${heat/1000}', 500, 100, 0x251f1f);
            FontManager.drawText('Conductivity F: $heatConductivityF', 500, 100-18, 0x2e2323);
            FontManager.drawText('Absorptivity F: $heatInF', 500, 100-18*2, 0x2e2323);
            FontManager.drawText('Emission F: $heatOutF', 500, 100-18*3, 0x2e2323);

            FontManager.drawText('Current: $current', 500, 100-18*4, 0x2e2323);
            
            FontManager.drawText('O2: $o2', 500, 100-18*5, 0x2e2323);
            FontManager.drawText('Broken: ${isBroken}', 500, 100-18*6, 0x2e2323);
            FontManager.drawText('Health: ${Std.int(health * 100)}%', 500, 100-18*7, 0x2e2323);
        }

        for(i in 0...logicConnectors.length) {
            logicConnectors[i].draw();
        }

        super.draw();

        // Procedural holes for broken components
        if (isBroken && health < 1.0) {
            var damage = 1.0 - health;
            var holeCount = Std.int(damage * 40);
            var seed = id; // Consistent holes for this object
            var rng = new util.SeedRandom(seed);
            
            var _cos:Float = FastTrig.fastcos(getAngle());
            var _sin:Float = FastTrig.fastsin(getAngle());

            for (i in 0...holeCount) {
                var rx = (rng.randomFloat() - 0.5) * (sizeX - 4);
                var ry = (rng.randomFloat() - 0.5) * (sizeY - 4);
                var radius = rng.randomFloat() * 3.0 * damage;
                
                // Rotate hole position
                var rotatedX = rx * _cos - ry * _sin;
                var rotatedY = rx * _sin + ry * _cos;
                
                // Draw a small black blob/hole
                var rInt = Std.int(radius) + 1;
                for (dx in -rInt...rInt) {
                    for (dy in -rInt...rInt) {
                        if (dx*dx + dy*dy <= radius*radius) {
                            Engine.drawDot(pos.x + rotatedX + dx, pos.y + rotatedY + dy, 0, 0x000000, isUI);
                        }
                    }
                }
            }
        }
    }

    public static function getConnectorWorldPos(obj:ExtendableObject, connector:Vec3):Vec3 {
        var _cos:Float = FastTrig.fastcos(obj.getAngle()); var _sin:Float = FastTrig.fastsin(obj.getAngle());
        var posX = obj.pos[0] + (connector[0]) * _cos - (connector[1]) * _sin;
        var posY = obj.pos[1] + (connector[0]) * _sin + (connector[1]) * _cos;

        return new Vec3(posX, posY, 0);
    }

    public function getConnectorWorldPosThis(connector:Vec3):Vec3 {
        var _cos:Float = FastTrig.fastcos(getAngle()); var _sin:Float = FastTrig.fastsin(getAngle());
        var posX = pos[0] + (connector[0]) * _cos - (connector[1]) * _sin;
        var posY = pos[1] + (connector[0]) * _sin + (connector[1]) * _cos;

        return new Vec3(posX, posY, 0);
    }

    /* public static function getConnectorLocalPos(obj:ExtendableObject, connector:Vec3):Vec3 {
        var _cos:Float = FastTrig.fastcos(obj.getAngle()); var _sin:Float = FastTrig.fastsin(obj.getAngle());
        var posX = connector[0] * _cos - connector[1] * _sin;
        var posY = connector[0] * _sin + connector[1] * _cos;

        return new Vec3(posX, posY, 0);
    } */

    /* public function connectNearest(toConnect:ExtendableObject, mx:Float, my:Float):Bool {
        connect(toConnect, getNearestConnector(this, new Vec3(mx, my, 0)), getNearestConnector(toConnect, new Vec3(mx, my, 0)));
        return false;
    } */
    
    public override function select(isSelected:Bool) {
        if (isSelected) {
            Game.worldPosClicked = Game.worldPos;

            //for(neighbor in neighbors) new Line(pos, neighbor.obj.pos);
            //for(neighbor in neighborsFuel) new Line(pos, neighbor.obj.pos);
            //trace('Neighbors', neighborsFuel.map(n -> n.obj));

            for(child in linked) {
                //new Circle(child.connected.pos, 4);
                child.connected.setOutline(true, 0x2C4CA5);
            }
        }
        super.select(isSelected);
    }

    public function takeItem(itemName:String):Item {
        for (i in 0...inventory.length) {
            if (inventory[i].name == itemName) {
                return inventory.splice(i, 1)[0];
            }
        }
        return null;
    }
}

class ExtendableManager {
    public var template:String;
    public var core:ExtendableObject;
    public var objects:Array<ExtendableObject> = [];    
    public var logicLinks:Array<LogicConnectorLink> = [];

    private var traversed:Map<ExtendableObject, Bool> = new Map<ExtendableObject, Bool>();

    public function new() {
        
    }

    public function deattach(connected:ExtendableObject) {
        for(i in 0...objects.length) {
            var obj = objects[i];
            var j = obj.linked.length - 1; 
            while(j >= 0) {
                var jdx = obj.linked.length-1-j;
                var link = obj.linked[jdx];
                if(link.connected == connected) {
                    if(link.connected.linked.length != 0) return trace('First deattach childs!!!');
                    trace('Deattached ${connected}');
                    obj.linked.splice(jdx, 1);
                    connected.rotate(-10);
                }
                j--;
            }
        }
    }

    /* public static function traverse(dt:Float, obj:ExtendableObject=null) {
        if(obj == null && Worker.tasks.length > 0) return;
        if(traversed.exists(obj)) return;
        
        if(obj == null) {
            if(objects.length == 0) return;
            obj = objects[0];
            traversed = new Map<ExtendableObject, Bool>();
        }
        traversed.set(obj, true);
        obj.rotateConnected(dt);

        var i:Int = -1;
        while(++i < obj.linked.length) {
            traverse(dt, obj.linked[i].connected);
        }
    } */

    public inline function traverseCycle(dt:Float) {
        var traversed:Array<ExtendableObject> = [];
        var i = -1; var l = objects.length; while(++i < l) {
            if (traversed.indexOf(objects[i]) != -1) continue;
            objects[i].rotateConnected(dt);
            objects[i].calculateMechanics(dt);
            objects[i].update(dt);
        }
    }

    public function connectLogic(from:LogicConnector, to:LogicConnector) {
        trace("Logic connected");
        logicLinks.push(new LogicConnectorLink(from, to));
    }

    public function removeLogicLink(target:LogicConnectorLink) {
        var index = logicLinks.indexOf(target);
        if (index == -1) return;
        target.line.destroy();
        logicLinks.splice(index, 1);
    }

    public inline function traverseLogic(dt:Float) {
        var i = -1; var l = logicLinks.length; while(++i < l) {
            var link:LogicConnectorLink = logicLinks[i];
            link.draw(dt);
            link.to.callback(link.from.callback(false, dt), dt);
        }
    }

    public function calculateMassCenter():Vec3 {
        var sumX:Float = 0;
        var sumY:Float = 0;
        var sumZ:Float = 0;
        var totalMass:Float = 0;

        var visited:Map<ExtendableObject, Bool> = new Map();

        var i = -1; 
        var l = objects.length; 
        while(++i < l) {
            var obj = objects[i];

            if (visited.exists(obj)) continue;
            visited.set(obj, true);

            var m = obj.mass;

            sumX += obj.pos[0] * m;
            sumY += obj.pos[1] * m;
            sumZ += obj.pos[2] * m;

            totalMass += m;
        }

        if (totalMass == 0) return new Vec3(0, 0, 0);

        return new Vec3(
            sumX / totalMass,
            sumY / totalMass,
            sumZ / totalMass
        );
    }

    public function calculateTotalMass():Float {
        var totalMass:Float = 0;

        var visited:Map<ExtendableObject, Bool> = new Map();

        var i = -1;
        var l = objects.length;
        while(++i < l) {
            var obj = objects[i];
            if (visited.exists(obj)) continue;
            visited.set(obj, true);
            totalMass += obj.mass;
        }

        return totalMass;
    }

    public inline function applyForceAtWorld(worldPos:Vec3, force:Vec3) {
        if (core == null) return;

        core.velocity = core.velocity.add(force);

        var center = calculateMassCenter();
        var lever = worldPos.sub(center);
        var torque = lever[0] * force[1] - lever[1] * force[0];

        core.angularVelocity += torque * 0.05;
    }

    public inline function advance(dt:Float) {
        if (core == null) return;

        core.rotate(core.angularVelocity * dt);
        traverseCycle(dt);

        /* 
        var centerBefore = calculateMassCenter();
        var desiredCenter = centerBefore.add(core.velocity.multiply(dt));
        
        var centerAfter = calculateMassCenter();
        var correction = desiredCenter.sub(centerAfter);

        if (Math.abs(correction[0]) > 0.0001 || Math.abs(correction[1]) > 0.0001 || Math.abs(correction[2]) > 0.0001) {
            core.pos = core.pos.add(correction);
            traverseCycle(0);
        } */
    }

    //public var lineToNearestObject:Line = new Line(new Vec3(0, 0, 0), new Vec3(0, 0, 0));
    public inline function findNearestToObject(obj:ExtendableObject, pos:Vec3, exclude:Array<ExtendableObject>=null):ExtendableObject {
        var maxD:Float = 9999;
        var nearest:ExtendableObject = null;
        for(i in 0...objects.length) {
            var d = Eight.distance(pos, objects[i].pos);
            if (d < maxD && objects[i] != obj && (exclude == null || exclude.indexOf(nearest) == -1)) {
                nearest = objects[i];
                maxD = d;
            }
        }

        //lineToNearestObject.pos1 = pos;
        //lineToNearestObject.pos2 = nearest.pos;
        return nearest;
    }

    public function findNearestConnectorAll(point:Vec3, type:Int=-1, exclude:ExtendableObject=null):{obj:ExtendableObject, connector: Connector} {
        var sorted = objects.copy();
        sorted.sort(function(a, b) {
            var da = Eight.distance(point, a.pos);
            var db = Eight.distance(point, b.pos);
            return da < db ? -1 : (da > db ? 1 : 0);
        });

        for(obj in sorted) {
            if (obj == exclude) continue;
            var connector:Connector = findNearestConnector(obj, point, type, false);
            if(connector != null) {
                return {obj: obj, connector: connector};
            }
        }
        return null;
    }

    public inline function findNearestConnector(obj:ExtendableObject, point:Vec3, type:Int=-1, local:Bool=false):Connector {
        var maxD:Float = 9999; var connector:Connector = null;//obj.connectors[0];
        for(i in 0...obj.connectors.length) {
            if(type == -1 || obj.connectors[i].type == type) {
                var d = !local ? Eight.distance(point, ExtendableObject.getConnectorWorldPos(obj, obj.connectors[i].pos)) 
                            : Eight.distance(point, Vec3.rotate(obj.connectors[i].pos, obj.getAngle()));
                if(d < maxD) { 
                    maxD = d;
                    connector = obj.connectors[i];
                }
            }
        }      
        return connector;
    }

    public function isConnected(connected:ExtendableObject):Bool {
        return objects.indexOf(connected) != -1;
    }

    public function connect(obj:ExtendableObject, connected:ExtendableObject, from:Vec3, to:Vec3) {
        //if (connected.noClip == true && !noClippingAt(connected, getConnectedPos(obj, from, to))) return;

        for(connector in connected.connectors) {
            if(connector.type == 0) {
                var connectorPos:Vec3 = ExtendableObject.getConnectorWorldPos(connected, connector.pos);
                //var dot = new Eight.Object(4, 4, null, 0xee4341);
                //dot.pos = connectorPos;

                /* var nearest:ExtendableObject = findNearestToObject(connected, connectorPos, connected.neighbors.map(n -> n.obj));
                if (nearest == null || connected.gasPassable == false || nearest.gasPassable == false) continue;
                connected.neighbors.push(new Neighbor(nearest, 0));
                nearest.neighbors.push(new Neighbor(connected, 0)); */

                var result = findNearestConnectorAll(connectorPos, 0, connected);
                if (result == null) continue;
                var nearest:ExtendableObject = result.obj;
                var distance:Float = Eight.distance(connectorPos, ExtendableObject.getConnectorWorldPos(nearest, result.connector.pos));
                if (distance < 3) {
                    connected.neighbors.push(new Neighbor(nearest, 1));
                    nearest.neighbors.push(new Neighbor(connected, 1));
                }
                //new Line(nearest.pos, obj.pos);
            } else if (connector.type == 1) { //fuel
                var connectorPos:Vec3 = ExtendableObject.getConnectorWorldPos(connected, connector.pos);
                //var dot = new Eight.Object(4, 4, null, 0x1bbe1b);
                //dot.pos = connectorPos;

                var result = findNearestConnectorAll(connectorPos, 1, connected);
                if (result == null) continue;
                var nearest:ExtendableObject = result.obj;
                var distance:Float = Eight.distance(connectorPos, ExtendableObject.getConnectorWorldPos(nearest, result.connector.pos));
                if (distance < 3) {
                    //trace(connected, nearest);
                    connected.neighborsFuel.push(new Neighbor(nearest, 1));
                    nearest.neighborsFuel.push(new Neighbor(connected, 1));
                }
            }
        }

        connected.setGhost(false);
        obj.linked.push(new ConnectorLink(connected, from, to));
        //new Line(obj.pos, connected.pos);
        if (objects.indexOf(obj) == -1) objects.push(obj);
        if (objects.indexOf(connected) == -1) objects.push(connected);

        connected.manager = this;
    }

    public function ghostConnect(obj:ExtendableObject, connected:ExtendableObject, from:Vec3, to:Vec3) {
        //if (connected.noClip == true && !noClippingAt(connected, getConnectedPos(obj, from, to))) return;

        //connected.setGhost(true);
        obj.placeAccordingly(connected, from, to);
    }

    public function getConnectedPos(obj:ExtendableObject, from:Vec3, to:Vec3):Vec3 {
        var cos = FastTrig.fastcos(obj.getAngle()); var sin = FastTrig.fastsin(obj.getAngle());
        var lx = from[0] - to[0];
        var ly = from[1] - to[1];
        var posX = obj.pos[0] + lx * cos - ly * sin;
        var posY = obj.pos[1] + lx * sin + ly * cos;
        return new Vec3(posX, posY, 0);
    }

    public function noClippingAt(obj:ExtendableObject, pos:Vec3):Bool {
        for (o in objects) {
            if (o == obj) continue;

            //trace(Eight.distance(o.pos, testPos), 19);
            if (Eight.distance(o.pos, pos) < 19) {
                return false;
            }
        }
        return true;
    }


    /* public function putAbove<T:ExtendableObject>(cls:Class<T>):T {
        var obj = Type.createInstance(cls, []);
        connect(this, obj, connectors[4], obj.connectors[4]);
        return obj;
    } */

    public function extendUp<T:ExtendableObject>(base:ExtendableObject, cls:Class<T>):T {
        var obj = Type.createInstance(cls, []);
        connect(base, obj, base.connectors[3].pos, base.connectors[2].pos);
        return obj;
    }

    /* public function extendDown<T:ExtendableObject>(cls:Class<T>):T {
        var obj = Type.createInstance(cls, []);
        connect(this, obj, connectors[2], obj.connectors[3]);
        return obj;
    }

    public function extendLeft<T:ExtendableObject>(cls:Class<T>):T {
        var obj = Type.createInstance(cls, []);
        connect(this, obj, connectors[0], obj.connectors[1]);
        return obj;
    }

    public function extendRight<T:ExtendableObject>(cls:Class<T>):T {
        var obj = Type.createInstance(cls, []);
        connect(this, obj, connectors[1], obj.connectors[0]);
        return obj;
    } */
}
