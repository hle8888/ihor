package util;
import Eight.Engine;
import util.Math;

class ThrusterFlameFx {
    public static inline function clamp01(v:Float):Float {
        return v < 0 ? 0 : (v > 1 ? 1 : v);
    }

    public static inline function approach(current:Float, target:Float, speed:Float):Float {
        var delta = target - current;
        if (Math.abs(delta) <= speed) return target;
        return current + (delta > 0 ? speed : -speed);
    }

    static inline function lerpColor(from:Int, to:Int, t:Float):Int {
        var tt = clamp01(t);
        var r = Std.int(((from >> 16) & 0xFF) + (((to >> 16) & 0xFF) - ((from >> 16) & 0xFF)) * tt);
        var g = Std.int(((from >> 8) & 0xFF) + (((to >> 8) & 0xFF) - ((from >> 8) & 0xFF)) * tt);
        var b = Std.int((from & 0xFF) + ((to & 0xFF) - (from & 0xFF)) * tt);
        return (r << 16) | (g << 8) | b;
    }

    public static function drawJet(origin:Vec3, direction:Vec3, intensity:Float, width:Float, length:Float, heat:Float) {
        var power = clamp01(intensity);
        if (power <= 0.02) return;

        var dir = new Vec3(direction.x, direction.y, direction.z).normalize();
        var side = dir.cross(new Vec3(0, 0, 1)).normalize();
        var time = haxe.Timer.stamp() * 18.0;
        var flameLength = length * (0.65 + power * 0.55);
        var steps = Std.int(Math.max(6, flameLength));
        var coolColor = heat > 0.65 ? 0xFF5A : 0xFF7A1A;
        var midColor = heat > 0.65 ? 0xFF9F3A : 0xFFB347;
        var coreColor = 0xFFF4C7;

        for (i in 0...steps) {
            var t = i / steps;
            var fade = (1.0 - t) * power;
            var pulse = 0.82 + Math.abs(FastTrig.fastsin(time + i * 0.9)) * 0.45;
            var currentWidth = Math.max(1.0, width * (1.0 - t * 0.8) * pulse);
            var distance = flameLength * t;
            var center = origin.add(dir.multiply(distance));
            var sway = FastTrig.fastsin(time * 0.7 + i * 1.4) * currentWidth * 0.45;
            center = center.add(side.multiply(sway));

            var halfWidth = Std.int(Math.ceil(currentWidth));
            for (w in -halfWidth...halfWidth + 1) {
                var edge = 1.0 - Math.abs(w) / (halfWidth + 0.001);
                if (edge <= 0) continue;

                var point = center.add(side.multiply(w));
                var colorMix = clamp01(t * 1.15);
                var shellColor = lerpColor(midColor, coolColor, colorMix);
                var color = edge > 0.55 ? lerpColor(shellColor, coreColor, edge * 0.9) : shellColor;

                if (edge * fade > 0.12) {
                    Engine.drawDot(point.x, point.y, 0, color);
                }
            }
        }

        var sparks = Std.int(2 + power * 4);
        for (i in 0...sparks) {
            var sparkT = 0.45 + i / (sparks + 1);
            var sparkPos = origin.add(dir.multiply(flameLength * sparkT));
            var spread = (i - sparks / 2) * 0.9 + FastTrig.fastcos(time + i) * width;
            sparkPos = sparkPos.add(side.multiply(spread));
            Engine.drawDot(sparkPos.x, sparkPos.y, 0, 0xFFB347);
        }
    }
}