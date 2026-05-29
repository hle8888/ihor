import Eight;
import util.Math.Vec3;
import Game;
import objects.Objects;
import objects.Extendable;
import objects.Items;
import util.Sequence;
import util.Texture;

class PawnJob {
    public var label:String;

    public function new(label:String) {
        this.label = label;
    }

    public function start(char:Character, done:Void->Void):Void {
        done();
    }
}

class MoveJob extends PawnJob {
    public var target:Vec3;

    public function new(target:Vec3) {
        super('Move');
        this.target = target;
    }

    public override function start(char:Character, done:Void->Void):Void {
        char.setTarget(target, done);
    }
}

class RepairJob extends PawnJob {
    public var targetObj:ExtendableObject;
    public var workTime:Float;

    public function new(targetObj:ExtendableObject, workTime:Float = 2.0) {
        super('Repair');
        this.targetObj = targetObj;
        this.workTime = workTime;
    }

    public override function start(char:Character, done:Void->Void):Void {
        if (targetObj == null) return done();
        char.setTarget(targetObj.pos, () -> {
            Eight.wait(workTime, () -> {
                targetObj.isBroken = false;
                targetObj.health = 1;
                done();
            });
        });
    }
}

class UseJob extends PawnJob {
    public var targetObj:ExtendableObject;
    public var workTime:Float;

    public function new(targetObj:ExtendableObject, workTime:Float = 1.0) {
        super('Use');
        this.targetObj = targetObj;
        this.workTime = workTime;
    }

    public override function start(char:Character, done:Void->Void):Void {
        if (targetObj == null) return done();
        char.setTarget(targetObj.pos, () -> {
            Eight.wait(workTime, () -> {
                if (Std.isOfType(targetObj, Vendor)) {
                    char.food = Math.min(1.0, char.food + 0.35);
                } else if (Std.isOfType(targetObj, Hydroponics)) {
                    char.skillFarming += 1;
                    char.food = Math.min(1.0, char.food + 0.15);
                } else if (Std.isOfType(targetObj, Sensor)) {
                    char.skillScience += 1;
                } else if (Std.isOfType(targetObj, ShipConsole)) {
                    char.sleep = Math.max(0.0, char.sleep - 0.02);
                }
                done();
            });
        });
    }
}

class HaulJob extends PawnJob {
    public var sourceObj:ExtendableObject;
    public var targetObj:ExtendableObject;
    public var itemName:String;
    public var workTime:Float;

    public function new(sourceObj:ExtendableObject, targetObj:ExtendableObject, itemName:String = 'Fuel', workTime:Float = 0.8) {
        super('Haul');
        this.sourceObj = sourceObj;
        this.targetObj = targetObj;
        this.itemName = itemName;
        this.workTime = workTime;
    }

    public override function start(char:Character, done:Void->Void):Void {
        if (sourceObj == null || targetObj == null) return done();

        char.setTarget(sourceObj.pos, () -> {
            Eight.wait(workTime, () -> {
                var item = sourceObj.takeItem(itemName);
                if (item == null) item = new Item(itemName);
                char.carriedItem = item;

                char.setTarget(targetObj.pos, () -> {
                    Eight.wait(workTime, () -> {
                        if (char.carriedItem != null) {
                            targetObj.inventory.push(char.carriedItem);
                            char.carriedItem = null;
                        }
                        done();
                    });
                });
            });
        });
    }
}

class SleepJob extends PawnJob {
    public var bed:ExtendableObject;
    public var workTime:Float;

    public function new(bed:ExtendableObject, workTime:Float = 4.0) {
        super('Sleep');
        this.bed = bed;
        this.workTime = workTime;
    }

    public override function start(char:Character, done:Void->Void):Void {
        if (bed == null) return done();
        char.setTarget(bed.pos, () -> {
            Eight.wait(workTime, () -> {
                char.sleep = 1;
                done();
            });
        });
    }
}

class Character extends GameObject {
    public var x:Float;
    public var y:Float;
    public var isInside:Bool = false;
    public var currentObj:Object;
    public var speed:Float = 75;

    private var targetX:Float;
    private var targetY:Float;

    var bobTime:Float = 0;

    public var o2:Float = 1;
    public var food:Float = 1;
    public var sleep:Float = 1;

    public var skillFarming = 0;
    public var skillMining = 0;
    public var skillConstructing = 0;
    public var skillScience = 0;

    public var jobs:Array<PawnJob> = [];
    public var currentJob:PawnJob;
    public var carriedItem:Item;
    var jobVersion:Int = 0;
    var moveRequestId:Int = 0;

    public function new(x:Float=0.0, y:Float=0.0) {
        super(15, 22, 'character.png');

        this.zlayer = 1;
        this.x = x;
        this.y = y;
        this.targetX = x;
        this.targetY = y;

        selectable = true;
        setPos(x, y);
    }

    public override function update(dt:Float):Void {
        var dx = targetX - x;
        var dy = targetY - y;
        var dist = Math.sqrt(dx * dx + dy * dy);
        var isMoving = false;
        if (dist > speed * dt) {
            x += dx / dist * speed * dt;
            y += dy / dist * speed * dt;
            isMoving = true;
        } else {
            if (isInside && currentObj != null) {
                targetX = currentObj.pos[0];
                targetY = currentObj.pos[1];
            }
            x = targetX;
            y = targetY;
        }

        if (isMoving) {
            bobTime += dt * 15;
            localAngle = Math.sin(bobTime) * 0.15;
        } else {
            bobTime = 0;
            localAngle = 0;
        }

        setPos(x, y);

        o2 -= 0.005 * dt;
        food -= 0.005 * 1/10 * dt;
        sleep -= 0.005 * 1/50 * dt;

        if (sleep < 0.2 && !hasJobType('Sleep')) {
            var bed = findNearestInteractable(obj -> Std.isOfType(obj, Bed));
            if (bed != null) enqueueJob(new SleepJob(bed));
        }

        if (isInside) {
            o2 = 1;
        }

        if (currentJob == null && jobs.length > 0) {
            startNextJob();
        }
    }

    public override function draw():Void {
        if (selected) {
            FontManager.drawText('O2: $o2', 500, 118, 0x2e2323);
            FontManager.drawText('Food: ${food}', 500, 100, 0x251f1f);
            FontManager.drawText('Sleep: ${sleep}', 500, 82, 0x251f1f);
            FontManager.drawText('Job: ${currentJob != null ? currentJob.label : "Idle"}', 500, 64, 0x251f1f);
            FontManager.drawText('Queue: ${jobs.length}', 500, 46, 0x251f1f);
            if (carriedItem != null) {
                FontManager.drawText('Carry: ${carriedItem.name}', 500, 28, 0x251f1f);
            }
        }
        super.draw();
    }

    public function hasJobType(label:String):Bool {
        if (currentJob != null && currentJob.label == label) return true;
        return jobs.filter(job -> job.label == label).length > 0;
    }

    public function clearJobs():Void {
        jobs = [];
        currentJob = null;
        jobVersion++;
        moveRequestId++;
    }

    public function enqueueJob(job:PawnJob):Void {
        jobs.push(job);
        if (currentJob == null) {
            startNextJob();
        }
    }

    public function setSingleJob(job:PawnJob):Void {
        clearJobs();
        enqueueJob(job);
    }

    function startNextJob():Void {
        if (jobs.length == 0) {
            currentJob = null;
            return;
        }

        currentJob = jobs.shift();
        var startedVersion = jobVersion;
        currentJob.start(this, () -> {
            if (startedVersion != jobVersion) return;
            currentJob = null;
            startNextJob();
        });
    }

    function findNearestInteractable(filter:ExtendableObject->Bool):ExtendableObject {
        var nearest:ExtendableObject = null;
        var nearestDistance = 1e9;

        for (obj in Game.currentShip.objects) {
            if (!filter(obj)) continue;

            var d = Eight.distance(pos, obj.pos);
            if (d < nearestDistance) {
                nearest = obj;
                nearestDistance = d;
            }
        }

        return nearest;
    }

    public function setTarget(target:Vec3, cb:Void->Void=null):Void {
        moveRequestId++;
        var activeMoveRequestId = moveRequestId;
        var moveTo = (_pos:Vec3) -> { return (seq) -> {
            if (activeMoveRequestId != moveRequestId) return;
            targetX = _pos[0];
            targetY = _pos[1];
            trace("Moving character to " + targetX, targetY);

            var waitForApproach:(Float)->Void = null;
            waitForApproach = (dt:Float) -> {
                if (activeMoveRequestId != moveRequestId) {
                    Eight.unregisterUpdateCallback(waitForApproach);
                    return;
                }
                if (Eight.distance(pos, new Vec3(targetX, targetY, 0)) < 1) {
                    trace("Approached " + targetX, targetY);
                    Eight.unregisterUpdateCallback(waitForApproach);
                    seq.next();
                }
            };

            Eight.registerUpdateCallback(waitForApproach);
        }};

        var sorted = Eight.objects.copy();
        sorted.sort(function(a, b) {
            var da = Eight.distance(pos, a.pos);
            var db = Eight.distance(pos, b.pos);
            return da < db ? -1 : (da > db ? 1 : 0);
        });
        sorted.reverse();
        var door:Object = Game.findObject(sorted, obj -> Std.isOfType(obj, Door));
        if (door == null) return trace('Null errror!!!');

        var obj:Object = Game.findObjectOnMouse(target[0], target[1], obj -> !Std.isOfType(obj, Button));
        var movingInside:Bool = Std.isOfType(obj, Hull);
        if (!isInside && movingInside) {
            new Sequence()
                .then(moveTo(door.pos))
                .then(moveTo(target))
                .then((seq) -> {
                    if (activeMoveRequestId != moveRequestId) return;
                    trace('Inside!!!!');
                    isInside = true;
                    currentObj = obj;

                    if (cb != null) cb();
                    seq.next();
                })
                .start();
        } else if (isInside && !movingInside) {
            new Sequence()
                .then(moveTo(door.pos))
                .then(moveTo(target))
                .then((seq) -> {
                    if (activeMoveRequestId != moveRequestId) return;
                    isInside = false;
                    currentObj = null;

                    if (cb != null) cb();
                    seq.next();
                })
                .start();
        } else if (isInside) {
            new Sequence()
                .then(moveTo(target))
                .then((seq) -> {
                    if (activeMoveRequestId != moveRequestId) return;
                    currentObj = obj;
                    targetX = obj.pos[0];
                    targetY = obj.pos[1];

                    if (cb != null) cb();
                    seq.next();
                })
                .start();
        } else if (!isInside) {
            new Sequence()
                .then(moveTo(target))
                .then((seq) -> {
                    if (activeMoveRequestId != moveRequestId) return;
                    if (cb != null) cb();
                    seq.next();
                })
                .start();
        }
    }
}
