package system;

import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.util.FlxSignal;
import flixel.group.FlxGroup;

typedef CutsceneEvent = {
    time:Float,
    callback:Void->Void
};

class CutsceneManager extends FlxGroup {
    private var events:Array<CutsceneEvent> = [];
    private var elapsedTime:Float = 0;
    private var isPlaying:Bool = false;

    public var onComplete:FlxSignal = new FlxSignal();

    public function new() {
        super();
    }

    public function addEvent(time:Float, callback:Void->Void):Void {
        events.push({ time: time, callback: callback });
        events.sort(function(a, b) return Reflect.compare(a.time, b.time));
    }

    public function start():Void {
        elapsedTime = 0;
        isPlaying = true;
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        if (!isPlaying) return;

        elapsedTime += elapsed;

        while (events.length > 0 && elapsedTime >= events[0].time) {
            var event = events.shift();
            event.callback();
        }

        if (events.length == 0) {
            isPlaying = false;
            onComplete.dispatch();
        }
    }
}
