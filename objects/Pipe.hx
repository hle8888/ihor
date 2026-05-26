package objects;

import Eight.Engine;
import objects.Extendable;
import util.Math;
import util.Fx;

class PipeManager extends ExtendableManager {

}

class ExtendablePipe extends ExtendableObject {
    public static function drawPipeSegments(obj:ExtendableObject) {
        var pipeColor = 0xFF5D3A1A;     // Dark Brown
        var highlightColor = 0xFF8B4513; // Lighter Brown
        var couplingColor = 0xFF3D2612;  // Very Dark Brown
        var pipeThickness = 3;
        var halfThickness = 1;

        var isPipe = Std.isOfType(obj, Pipe);

        // Draw central hub if it's a dedicated Pipe object
        if (isPipe) {
            Engine.drawRectangle(obj.pos.x - 2, obj.pos.y - 2, 4, 4, pipeColor);
            Engine.drawRectangle(obj.pos.x - 1, obj.pos.y - 1, 2, 2, highlightColor);
        }

        // Check each connector for connections
        for (connector in obj.connectors) {
            if (connector.type != 1) continue;

            var myConnectorWorldPos = obj.getConnectorWorldPosThis(connector.pos);
            var isConnected = false;

            for (neighbor in obj.neighborsFuel) {
                var n = neighbor.obj;
                for (nc in n.connectors) {
                    if (nc.type != 1) continue;
                    var neighborConnectorWorldPos = n.getConnectorWorldPosThis(nc.pos);
                    if (Eight.distance(myConnectorWorldPos, neighborConnectorWorldPos) < 2.0) {
                        isConnected = true;
                        break;
                    }
                }
                if (isConnected) break;
            }

            if (isConnected) {
                // Draw segment towards this connector
                var dir = connector.pos; // local dir
                var cos = FastTrig.fastcos(obj.getAngle());
                var sin = FastTrig.fastsin(obj.getAngle());
                
                var rx = dir[0] * cos - dir[1] * sin;
                var ry = dir[0] * sin + dir[1] * cos;
                
                var steps = Std.int(Math.max(Math.abs(dir[0]), Math.abs(dir[1])));
                var startT = isPipe ? 0.0 : 0.75; // Only draw a stub at the edge for non-pipes
                
                for (i in 0...steps + 1) {
                    var t = i / steps;
                    if (t < startT) continue;
                    
                    var px = obj.pos.x + rx * t;
                    var py = obj.pos.y + ry * t;
                    
                    // Main pipe body
                    Engine.drawRectangle(px - 1, py - 1, 3, 3, pipeColor);
                    // Detail: 1px highlight in the center
                    Engine.drawRectangle(px, py, 1, 1, highlightColor);
                }

                // Draw a thicker coupling/joint at the connector point
                var cx = obj.pos.x + rx;
                var cy = obj.pos.y + ry;
                Engine.drawRectangle(cx - 2, cy - 2, 4, 4, couplingColor);
            }
        }
    }
}

class Pipe extends ExtendablePipe {
    public function new() {
        super(20, 20, null);
        heatInF = 0.1;
        heatOutF = 0.8;
        noClip = false;
    }

    public override function generateConnectors():Array<Connector> {
        return [
            new Connector([0, -10, 0], 1), // BOTTOM
            new Connector([10, 0, 0], 1),  // RIGHT
            new Connector([0, 10, 0], 1),  // TOP
            new Connector([-10, 0, 0], 1), // LEFT
        ];
    }

    public override function draw() {
        if (!show) return;
        ExtendablePipe.drawPipeSegments(this);
        if (selected) {
            super.draw();
        }
    }
}

class LiquidTank extends ExtendableObject {    
    public function new() {
        super(20, 20, 'ship/liquid_tank.png');
        heatInF = 0.1;
        heatOutF = 0.8;
        fuel = 100;
        noClip = false;
    }

    public override function generateConnectors():Array<Connector> {
        return [
            new Connector([0, 0, 0], 2), //CENTER

            new Connector([0, -Std.int(sizeX / 2), 0], 1), 
            new Connector([Std.int(sizeX / 2), 0, 0], 1), 
            new Connector([0, Std.int(sizeX / 2), 0], 1),  
            new Connector([-Std.int(sizeX / 2), 0, 0], 1),
        ];
    }

    public override function draw() {
        if (!show) return;
        ExtendablePipe.drawPipeSegments(this);
        super.draw();
    }
}


class ShipEngine extends ExtendableObject {
    // ... rest of fields unchanged
    public var fuelcombustionT:Float = 3227;
    public var fuelMolecularMass:Float = 0.018;
    public var fuelCameraPressure:Float = 7e6;
    public var p1p2:Float = 1.22;
    var topFlame:Float = 0.0;
    var leftFlame:Float = 0.0;
    var rightFlame:Float = 0.0;
    var topFlameTarget:Float = 0.0;
    var leftFlameTarget:Float = 0.0;
    var rightFlameTarget:Float = 0.0;

    public function new() {
        super(40, 40, 'ship/engine.png');
    }

    public inline function resetControlTargets() {
        topFlameTarget = 0.0;
        leftFlameTarget = 0.0;
        rightFlameTarget = 0.0;
    }

    public inline function getMainActuatorPos():Vec3 {
        return pos;
    }

    public inline function getMainActuatorForce():Vec3 {
        return dirV().multiply(10);
    }

    public inline function burnMain(dt:Float) {
        burnMainThrottle(dt, 1.0);
    }

    public inline function burnMainThrottle(dt:Float, throttle:Float) {
        throttle = Math.max(0.0, Math.min(1.0, throttle));
        if (throttle <= 0) return;
        if (fuel <= 0) return;
        topFlameTarget = throttle;
        Game.currentShip.applyForceAtWorld(getMainActuatorPos(), getMainActuatorForce().multiply(dt * throttle));
        fuel -= 1 * dt * throttle;
    }

    public inline function getLeftActuatorPos():Vec3 {
        var right = new Vec3(FastTrig.fastcos(getAngle()), FastTrig.fastsin(getAngle()), 0);
        return pos.add(right.multiply(-sizeX * 0.46));
    }

    public inline function getLeftActuatorForce():Vec3 {
        var right = new Vec3(FastTrig.fastcos(getAngle()), FastTrig.fastsin(getAngle()), 0);
        return right.multiply(8);
    }

    public inline function burnLeft(dt:Float) {
        burnLeftThrottle(dt, 1.0);
    }

    public inline function burnLeftThrottle(dt:Float, throttle:Float) {
        throttle = Math.max(0.0, Math.min(1.0, throttle));
        if (throttle <= 0) return;
        if (fuel <= 0) return;
        leftFlameTarget = 0.9 * throttle;
        Game.currentShip.applyForceAtWorld(getLeftActuatorPos(), getLeftActuatorForce().multiply(dt * throttle));
        fuel -= 1 * dt * throttle;
    }

    public inline function getRightActuatorPos():Vec3 {
        var right = new Vec3(FastTrig.fastcos(getAngle()), FastTrig.fastsin(getAngle()), 0);
        return pos.add(right.multiply(sizeX * 0.46));
    }

    public inline function getRightActuatorForce():Vec3 {
        var right = new Vec3(FastTrig.fastcos(getAngle()), FastTrig.fastsin(getAngle()), 0);
        return right.multiply(-8);
    }

    public inline function burnRight(dt:Float) {
        burnRightThrottle(dt, 1.0);
    }

    public inline function burnRightThrottle(dt:Float, throttle:Float) {
        throttle = Math.max(0.0, Math.min(1.0, throttle));
        if (throttle <= 0) return;
        if (fuel <= 0) return;
        rightFlameTarget = 0.9 * throttle;
        Game.currentShip.applyForceAtWorld(getRightActuatorPos(), getRightActuatorForce().multiply(dt * throttle));
        fuel -= 1 * dt * throttle;
    }

    public override function generateConnectors():Array<Connector> {
        return super.generateConnectors().concat([
            new Connector([-Std.int(sizeX / 4), Std.int(sizeY / 2), 0], 1)
        ]);
    }

    public override function generateLogicConnectors():Array<LogicConnector> {
        return [
            new LogicConnector([0, -Std.int(sizeY / 2), 0], this, true, (signal:Bool, dt:Float) -> {  //BOTTOM
                topFlameTarget = 0;
                return false;
            }, "", "Main Cut In"),
            new LogicConnector([0, Std.int(sizeY / 2), 0], this, true, (signal:Bool, dt:Float) -> { //TOP
                topFlameTarget = signal && fuel > 0 ? 1.0 : 0.0;
                if (signal && fuel > 0) {
                    burnMain(dt);
                } 
                return false;
            }, "", "Main Thrust In"),

            new LogicConnector([-Std.int(sizeX / 2), 0, 0], this, true, (signal:Bool, dt:Float) -> { //LEFT
                leftFlameTarget = signal && fuel > 0 ? 0.9 : 0.0;
                if (signal && fuel > 0) {
                    burnLeft(dt);
                }                
                return false;
            }, "", "Left Jet In"),

            new LogicConnector([Std.int(sizeX / 2), 0, 0], this, true, (signal:Bool, dt:Float) -> { //RIGHT
                rightFlameTarget = signal && fuel > 0 ? 0.9 : 0.0;
                if (signal && fuel > 0) {
                    burnRight(dt);
                }                 
                return false;
            }, "", "Right Jet In") 
        ];
    }

    public override function update(dt:Float) {
        var speed = dt * 10;
        topFlame = ThrusterFlameFx.approach(topFlame, topFlameTarget, speed);
        leftFlame = ThrusterFlameFx.approach(leftFlame, leftFlameTarget, speed * 1.2);
        rightFlame = ThrusterFlameFx.approach(rightFlame, rightFlameTarget, speed * 1.2);
    }

    public override function draw() {
        if (!show) return;
        var forward = new Vec3(FastTrig.fastcos(getAngle() + Math.PI / 2), FastTrig.fastsin(getAngle() + Math.PI / 2), 0);
        var right = new Vec3(FastTrig.fastcos(getAngle()), FastTrig.fastsin(getAngle()), 0);
        var left = -right;
        var exhaustBase = pos.add(forward.multiply(-sizeY * 0.42));

        ThrusterFlameFx.drawJet(exhaustBase, -forward, topFlame, 4.2, 18, topFlame);
        ThrusterFlameFx.drawJet(pos.add(right.multiply(-sizeX * 0.46)), left, leftFlame, 2.8, 10, leftFlame);
        ThrusterFlameFx.drawJet(pos.add(right.multiply(sizeX * 0.46)), right, rightFlame, 2.8, 10, rightFlame);

        ExtendablePipe.drawPipeSegments(this);
        super.draw();
    }
}

class ShipThruster extends ExtendableObject {
    public var fuelcombustionT:Float = 3227;
    public var fuelMolecularMass:Float = 0.018;
    public var fuelCameraPressure:Float = 7e6;
    public var p1p2:Float = 1.22;
    var flame:Float = 0.0;
    var flameTarget:Float = 0.0;
    //v = 4400

    public function new() {
        super(20, 20, 'ship/thruster.png');
    }

    public inline function resetControlTargets() {
        flameTarget = 0.0;
    }

    public inline function getActuatorPos():Vec3 {
        return pos;
    }

    public inline function getActuatorForce():Vec3 {
        return getConnectorWorldPosThis(new Vec3(0, Std.int(sizeY / 2), 0)).sub(pos).normalize().multiply(3);
    }

    public inline function burn(dt:Float) {
        burnThrottle(dt, 1.0);
    }

    public inline function burnThrottle(dt:Float, throttle:Float) {
        throttle = Math.max(0.0, Math.min(1.0, throttle));
        if (throttle <= 0) return;
        if (fuel <= 0) return;
        flameTarget = throttle;
        Game.currentShip.applyForceAtWorld(getActuatorPos(), getActuatorForce().multiply(dt * throttle));
        fuel -= 1 * dt * throttle;
    }

    public override function generateConnectors():Array<Connector> {
        return super.generateConnectors().concat([
            new Connector([0, Std.int(sizeX / 2), 0], 1)
        ]);
    }

    public override function generateLogicConnectors():Array<LogicConnector> {
        return [
            new LogicConnector([0, Std.int(sizeY / 2), 0], this, true, (signal:Bool, dt:Float) -> { //TOP
                flameTarget = signal && fuel > 0 ? 1.0 : 0.0;
                if (signal && fuel > 0) {
                    burn(dt);
                } 
                return false;
            }, "", "Thruster In")
        ];
    }

    public override function update(dt:Float) {
        flame = ThrusterFlameFx.approach(flame, flameTarget, dt * 12);
    }

    public override function draw() {
        if (!show) return;
        var forward = new Vec3(FastTrig.fastcos(getAngle() + Math.PI / 2), FastTrig.fastsin(getAngle() + Math.PI / 2), 0);
        var exhaustBase = pos.add(forward.multiply(-sizeY * 0.42));
        ThrusterFlameFx.drawJet(exhaustBase, -forward, flame, 2.6, 12, flame);
        
        ExtendablePipe.drawPipeSegments(this);
        super.draw();
    }
}
