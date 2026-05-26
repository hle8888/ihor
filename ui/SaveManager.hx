package ui;
import sys.io.File;
import haxe.Json;
import util.Math.Vec3;
import Eight;
import objects.Extendable;
import objects.Objects;
import objects.Pipe;
import Lambda;

typedef SaveData = {
    var objects:Array<SaveObject>;
    var logicLinks:Array<LogicLinked>;
}

typedef SaveObject = {
    var id:Int;
    var type:String;
    var linked:Array<Linked>;
    var x:Float;
    var y:Float;
    var z:Float;
    var angle:Float;
    var localAngle:Float;
    var sizeX:Int;
    var sizeY:Int;
}

typedef Linked = {
    var toId:Int;
    var from:Int;
    var to:Int;
}

typedef LogicLinked = {
    var fromId:Int;
    var from:Int;
    var toId:Int;
    var to:Int;
}

class SaveManager {
    public static function save(ship:ExtendableManager) {
        var data:SaveData = {
            objects: [],
            logicLinks: []
        };

        for (obj in ship.objects) {
            if(!Std.isOfType(obj, ExtendableObject)) continue;
            var eObj:ExtendableObject = cast obj;

            var jsonObj:SaveObject = {
                id: eObj.id,
                type: Type.getClassName(Type.getClass(obj)),
                linked: [],
                x: obj.pos.x,
                y: obj.pos.y,
                z: obj.pos.z,
                angle: obj.angle,
                localAngle: obj.localAngle,
                sizeX: obj.sizeX,
                sizeY: obj.sizeY
            }

            for(link in eObj.linked) {
                var fromIndex = Lambda.findIndex(eObj.connectors, c -> c.pos == link.from);
                var toIndex = Lambda.findIndex(link.connected.connectors, c -> c.pos == link.to);
                if (fromIndex == -1 || toIndex == -1) {
                    throw("BAD CONNECTOR INDEX");
                    continue;
                }
                jsonObj.linked.push({
                    toId: link.connected.id,
                    from: fromIndex,
                    to: toIndex,
                });
            }

            data.objects.push(jsonObj);
        }

        for (link in ship.logicLinks) {
            var fromObj = link.from.obj;
            var toObj = link.to.obj;

            var fromIndex = Lambda.findIndex(fromObj.logicConnectors, c -> c == link.from);
            var toIndex = Lambda.findIndex(toObj.logicConnectors, c -> c == link.to);
            if (fromIndex == -1 || toIndex == -1) {
                throw("BAD LOGIC CONNECTOR INDEX");
                continue;
            }

            data.logicLinks.push({
                fromId: fromObj.id,
                from: fromIndex,
                toId: toObj.id,
                to: toIndex
            });
        }

        var json = Json.stringify(data);

        var path:String = ship.template;
        File.saveContent(path, json);
        trace("Game saved: " + path);
    }

    public static function load(ship:ExtendableManager) {
        var path:String = ship.template;

        if (!sys.FileSystem.exists(path)) {
            trace("Save not found");
            return;
        }

        var json = File.getContent(path);
        var data:SaveData = Json.parse(json);
        if (data.logicLinks == null) data.logicLinks = [];

        //Engine.cameraOffset.x = data.cameraOffsetX;
        //Engine.cameraOffset.y = data.cameraOffsetY;

        var map = new Map<Int, ExtendableObject>();
        var i = -1; while(++i < data.objects.length) { 
            var o = data.objects[i];

            try {
                var cls = Type.resolveClass(o.type);
                var obj:ExtendableObject = cast Type.createInstance(cls, []);

                obj.id = o.id;
                obj.setPos(o.x, o.y, o.z);
                obj.angle = o.angle;
                obj.localAngle = o.localAngle;
                //obj.setSize(o.sizeX, o.sizeY);

                map.set(obj.id, obj);
            } catch (error:Dynamic) {
                trace('Cant\'t create object of instance ${o.type}');
                trace(error);
            }
        }

        var i = -1; while(++i < data.objects.length) { 
            var obj = map.get(data.objects[i].id);

            for (l in data.objects[i].linked) {
                var target = map.get(l.toId);

                if (target == null) continue;
                //trace('[${obj}, ${obj.pos}] connect [${target}, ${target.pos}]');
                ship.connect(obj, target, obj.connectors[l.from].pos, target.connectors[l.to].pos);
            }
        }

        for (logicLink in data.logicLinks) {
            var fromObj = map.get(logicLink.fromId);
            var toObj = map.get(logicLink.toId);
            if (fromObj == null || toObj == null) continue;
            if (logicLink.from < 0 || logicLink.from >= fromObj.logicConnectors.length) continue;
            if (logicLink.to < 0 || logicLink.to >= toObj.logicConnectors.length) continue;

            ship.connectLogic(fromObj.logicConnectors[logicLink.from], toObj.logicConnectors[logicLink.to]);
        }

        ship.core = ship.objects[0];

        trace('Ship ${path} loaded');
    }
}
