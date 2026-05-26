package util;

import openal.ALC as Alc;
import openal.AL as Al;
import openal.ALC.Device;
import openal.ALC.Context;
import openal.AL.Buffer;
import openal.AL.Source;
import sys.io.File;
import format.wav.Reader;
import haxe.io.Bytes;
import util.Math.Vec3;

class SoundManager {
    static var device:Device;
    static var context:Context;
    static var source:Source;
    static var buffer:Buffer;
    
    static var isInitialized:Bool = false;
    static var lastVelocity:Vec3 = new Vec3(0, 0, 0);
    static var gForce:Float = 0.0;
    
    static var lastPlayTime:Float = -60.0;
    static var pendingDelay:Float = -1.0;
    static var stopTimer:Float = -1.0;
    static var currentTime:Float = 0.0;
    static var totalDuration:Float = 0.0;

    public static function init() {
        try {
            device = Alc.openDevice(null);
            if (device == null) return;
            
            context = Alc.createContext(device, null);
            Alc.makeContextCurrent(context);
            
            var b = new hl.Bytes(4);
            Al.genSources(1, b);
            source = Source.ofInt(b.getI32(0));
            
            Al.genBuffers(1, b);
            buffer = Buffer.ofInt(b.getI32(0));

            if (sys.FileSystem.exists("sound/stressmetal.wav")) {
                var bytes = File.getBytes("sound/stressmetal.wav");
                var input = new haxe.io.BytesInput(bytes);
                var reader = new Reader(input);
                var wav = reader.read();
                
                var format = 0;
                if (wav.header.channels == 1) {
                    format = (wav.header.bitsPerSample == 8) ? Al.FORMAT_MONO8 : Al.FORMAT_MONO16;
                } else {
                    format = (wav.header.bitsPerSample == 8) ? Al.FORMAT_STEREO8 : Al.FORMAT_STEREO16;
                }
                
                // Calculate total duration for randomization
                var bytesPerSample = Std.int(wav.header.bitsPerSample / 8);
                var totalSamples = wav.data.length / bytesPerSample / wav.header.channels;
                totalDuration = totalSamples / wav.header.samplingRate;

                var rawData = hl.Bytes.fromBytes(wav.data);
                Al.bufferData(buffer, format, rawData, wav.data.length, wav.header.samplingRate);
                Al.sourcei(source, Al.BUFFER, buffer.toInt());
                Al.sourcei(source, Al.LOOPING, Al.FALSE);
                
                isInitialized = true;
                trace('SoundManager initialized. WAV Duration: ${totalDuration}s');
            }
        } catch (e:Dynamic) {
            trace("Sound initialization failed: " + e);
        }
    }
    
    public static function update(dt:Float, currentVelocity:Vec3) {
        if (!isInitialized) return;
        currentTime += dt;
        
        var dv = currentVelocity.sub(lastVelocity);
        var acc = dv.length() / (dt > 0 ? dt : 0.016);
        lastVelocity = currentVelocity;
        
        gForce = gForce * 0.95 + (acc * 0.05);
        
        // Schedule new event
        if (currentTime - lastPlayTime > 10.0 && pendingDelay < 0 && gForce > 0.08) {
            pendingDelay = 2.0 + Math.random() * 3.0;
        }
        
        // Handle trigger
        if (pendingDelay > 0) {
            pendingDelay -= dt;
            if (pendingDelay <= 0) {
                // Randomize start offset and length
                var playLen = 0.5 + Math.random() * 2.5; // Play for 0.5 to 3.0 seconds
                if (playLen > totalDuration) playLen = totalDuration;
                
                var startOffset = Math.random() * (totalDuration - playLen);
                
                Al.sourcef(source, Al.SEC_OFFSET, startOffset);
                Al.sourcePlay(source);
                
                var intensity = Math.min(1.0, gForce * 10.0);
                Al.sourcef(source, Al.GAIN, 0.3 + intensity * 0.6);
                Al.sourcef(source, Al.PITCH, 0.85 + Math.random() * 0.3);
                
                stopTimer = playLen;
                lastPlayTime = currentTime;
                pendingDelay = -1.0;
                trace('Playing structural stress: offset ${startOffset}s, length ${playLen}s');
            }
        }

        // Handle early stop for varied length
        if (stopTimer > 0) {
            stopTimer -= dt;
            if (stopTimer <= 0) {
                // Fade out slightly before stopping to avoid clicks
                var currentGain = Al.getSourcef(source, Al.GAIN);
                if (currentGain > 0.05) {
                    Al.sourcef(source, Al.GAIN, currentGain * 0.5);
                    stopTimer = 0.02; // Small extra delay for fade
                } else {
                    Al.sourceStop(source);
                    stopTimer = -1.0;
                }
            }
        }
    }
}
