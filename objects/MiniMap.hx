package objects;
import Eight;
import util.Math.Vec3;

class MiniMap {
    public var pos:Vec3;
    public var width:Int;
    public var height:Int;
    public var scale:Float;
    public var centerWorldPos:Vec3;
    public var isExpanded:Bool = false;

    public var lines:Array<Line> = [];
    public var circles:Array<Circle> = [];

    var l1:Line; var l2:Line; var l3:Line; var l4:Line;

    public function new(_pos:Vec3, _width:Int, _height:Int, _scale:Float = 0.1) {
        pos = _pos;
        width = _width;
        height = _height;
        scale = _scale;
        centerWorldPos = new Vec3(0, 0, 0);

        l1 = createLine([0, 0, 0], [0, 0, 0], 0xAAAAAA); l1.isUI = true;
        l2 = createLine([0, 0, 0], [0, 0, 0], 0xAAAAAA); l2.isUI = true;
        l3 = createLine([0, 0, 0], [0, 0, 0], 0xAAAAAA); l3.isUI = true;
        l4 = createLine([0, 0, 0], [0, 0, 0], 0xAAAAAA); l4.isUI = true;
    }

    public function worldToMiniMap(worldPos:Vec3):Vec3 {
        return new Vec3(
            pos[0] + width / 2 + (worldPos[0] - centerWorldPos[0]) * scale,
            pos[1] + height / 2 + (worldPos[1] - centerWorldPos[1]) * scale,
            0
        );
    }

    function clipLine(p1:Vec3, p2:Vec3):{p1:Vec3, p2:Vec3} {
        var x1 = p1[0], y1 = p1[1];
        var x2 = p2[0], y2 = p2[1];
        var minX = pos[0], maxX = pos[0] + width;
        var minY = pos[1], maxY = pos[1] + height;

        var t0:Float = 0, t1:Float = 1;
        var dx = x2 - x1, dy = y2 - y1;

        function p(p:Float, q:Float):Bool {
            if (p < 0) {
                var r = q / p;
                if (r > t1) return false;
                if (r > t0) t0 = r;
            } else if (p > 0) {
                var r = q / p;
                if (r < t0) return false;
                if (r < t1) t1 = r;
            } else if (q < 0) return false;
            return true;
        }

        if (p(-dx, x1 - minX) && p(dx, maxX - x1) && p(-dy, y1 - minY) && p(dy, maxY - y1)) {
            return {
                p1: new Vec3(x1 + t0 * dx, y1 + t0 * dy, 0),
                p2: new Vec3(x1 + t1 * dx, y1 + t1 * dy, 0)
            };
        }
        return null;
    }

    public function addLine(worldPos1:Vec3, worldPos2:Vec3, color:Int = 0xFFFFFF) {
        var p1 = worldToMiniMap(worldPos1);
        var p2 = worldToMiniMap(worldPos2);
        
        var clipped = clipLine(p1, p2);
        if (clipped != null) {
            var l = new Line(clipped.p1, clipped.p2, null, color);
            l.isUI = true;
            lines.push(l);
        }
    }

    public function addCircle(worldPos:Vec3, radius:Int = 5, color:Int = 0xFF0000) {
        var p = worldToMiniMap(worldPos);
        var r = radius * scale;
        
        // Simple circle clipping: check if circle is at least partially inside
        if (p[0] + r < pos[0] || p[0] - r > pos[0] + width || 
            p[1] + r < pos[1] || p[1] - r > pos[1] + height) {
            return;
        }

        var circle = new Circle(p, Std.int(r), null, color);
        circle.isUI = true;
        circles.push(circle);
    }

    public function draw() {
        l1.pos1 = [pos[0], pos[1], 0]; l1.pos2 = [pos[0]+width, pos[1], 0];
        l2.pos1 = [pos[0]+width, pos[1], 0]; l2.pos2 = [pos[0]+width, pos[1]+height, 0];
        l3.pos1 = [pos[0]+width, pos[1]+height, 0]; l3.pos2 = [pos[0], pos[1]+height, 0];
        l4.pos1 = [pos[0], pos[1]+height, 0]; l4.pos2 = [pos[0], pos[1], 0];
        
        l1.draw(); l2.draw(); l3.draw(); l4.draw();
        for (line in lines) line.draw();
        for (circle in circles) circle.draw();
    }

    public inline function createLine(p1:Vec3, p2:Vec3, color:Int):Line {
        var l = new Line(p1, p2, null, color);
        l.isUI = true;
        return l;
    }

    public function clear() {
        for (line in lines) if (line != null) line.destroy(); 
        for (circle in circles) if (circle != null) circle.destroy();
        lines = [];
        circles = [];
    }
}
