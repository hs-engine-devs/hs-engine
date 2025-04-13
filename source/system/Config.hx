package system;

import flixel.FlxG;
import sys.io.File;
import sys.FileSystem;

using StringTools;

class Config {
	public static var botplay:Bool = false;
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var noteSplashes:Bool = true;
	public static var ghostTapping:Bool = true;
	public static var flashingMenu:Bool = true;
	public static var camZooms:Bool = true;
    public static var showFPS:Bool = true;
    public static var keyBinds:Array<String> = ['A','S','W','D','R'];
    public static var customOptions:Array<Option> = [];

	public static function save() {
		FlxG.save.data.botplay = botplay;
		FlxG.save.data.downScroll = downScroll;
		FlxG.save.data.middleScroll = middleScroll;
		FlxG.save.data.noteSplashes = noteSplashes;
		FlxG.save.data.ghostTapping = ghostTapping;
		FlxG.save.data.flashingMenu = flashingMenu;
		FlxG.save.data.camZooms = camZooms;
		FlxG.save.data.showFPS = showFPS;
		FlxG.save.flush();
    }

	public static function load() {
		if(FlxG.save.data.botplay != null)
			botplay = FlxG.save.data.botplay;
		if(FlxG.save.data.downScroll != null)
			downScroll = FlxG.save.data.downScroll;
		if(FlxG.save.data.middleScroll != null)
			middleScroll = FlxG.save.data.middleScroll;
		if(FlxG.save.data.noteSplashes != null)
			noteSplashes = FlxG.save.data.noteSplashes;
		if(FlxG.save.data.ghostTapping != null)
			ghostTapping = FlxG.save.data.ghostTapping;
		if(FlxG.save.data.flashingMenu != null)
			flashingMenu = FlxG.save.data.flashingMenu;
		if(FlxG.save.data.camZooms != null)
			camZooms = FlxG.save.data.camZooms;
		if(FlxG.save.data.showFPS != null) {
			showFPS = FlxG.save.data.showFPS;
			if(Main.fpsVar != null) {
				Main.fpsVar.visible = showFPS;
			}
		}
		loadCustomOptions();
    }

    public static function saveCustomOptions() {
        #if sys
        var optionsFilePath:String = ModPaths.data("options");
		if (FileSystem.exists(optionsFilePath)) {
			var optionsToSave:Array<{name:String, value:Bool, isUnselectable:Bool}> = [];
			for (option in customOptions) {
				optionsToSave.push({
					name: option.name,
					value: option.value,
					isUnselectable: option.isUnselectable
				});
			}
			var jsonData:String = haxe.Json.stringify({ options: optionsToSave }, "\t");
			var file:sys.io.FileOutput = sys.io.File.write(optionsFilePath, false);
			file.writeString(jsonData);
			file.close();
	    }
        #end
    }

	public static function loadCustomOptions() {
		#if sys
		var optionsFilePath:String = ModPaths.data("options");
		if (FileSystem.exists(optionsFilePath)) {
			var fileContents:String = File.getContent(optionsFilePath);
			parseCustomOption(fileContents);
		}
		#end
	}

    private static function parseCustomOption(data:String) {
		var jsonData:OptionsData = haxe.Json.parse(data);
        if (jsonData != null) {
            for (item in jsonData.options) {
                var option:Option = {
                    name: item.name,
                    value: item.value,
					isUnselectable: item.isUnselectable
                };
                customOptions.push(option);
            }
        }
    }
}

typedef OptionsData = {
    var options:Array<Option>;
}

typedef Option = {
	var name:String;
	var value:Bool;
	var isUnselectable:Bool;
}
