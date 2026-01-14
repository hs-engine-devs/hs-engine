package game;

import flixel.FlxSprite;

class Event extends FlxSprite {
    public var strumTime:Float;
    public var thisEvent:ChartEvent;

    public function new(event:ChartEvent) {
        super();

        this.strumTime = event.strumtime;
        this.thisEvent = event;

        loadGraphic(Paths.image('event'));
    }
}

typedef ChartEvent = {
    var strumtime:Float;
    var event:String;
    var ?variable1:String;
    var ?variable2:String;
}

typedef EventListData = {
    var eventName:String;
    var ?var1Hint:String;
    var ?var2Hint:String;
    var ?info:String;
}
