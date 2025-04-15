package system;

import flixel.FlxG;

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
	public static var customOptions:Array<{name:String, value:Bool, isUnselectable:Bool}> = [];

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
		for (modFolder in ModPaths.getModFolders()) {
			if (modFolder.enabled) {
				var optionsDirPath:String = 'mods/' + modFolder.folder + '/data/options/';
				var optionsToSave:Array<{name:String, value:Bool, isUnselectable:Bool}> = [];
				for (option in customOptions) {
					if (sys.FileSystem.isDirectory(optionsDirPath)) {
						for (optionJson in sys.FileSystem.readDirectory(optionsDirPath)) {
							if (optionJson != null && optionJson.endsWith('.json')) {
								optionsToSave.push({
									name: option.name,
									value: option.value,
									isUnselectable: option.isUnselectable
								});

					            var jsonData:String = haxe.Json.stringify({ options: optionsToSave }, "\t");
					            var optionFilePath:String = optionsDirPath + optionJson;

					            var file:sys.io.FileOutput = sys.io.File.write(optionFilePath, false);
					            file.writeString(jsonData);
					            file.close();
							}
						}
					}
				}
			}
		}
		#end
	}

	public static function loadCustomOptions() {
		#if sys
		customOptions = [];
	
		for (modFolder in ModPaths.getModFolders()) {
			if (modFolder.enabled) {
				var modFolderPath:String = 'mods/' + modFolder.folder + '/data/options/';
				if (sys.FileSystem.isDirectory(modFolderPath)) {
					for (optionJson in sys.FileSystem.readDirectory(modFolderPath)) {
						if (optionJson != null && optionJson.endsWith('.json')) {
							var jsonContent:String = sys.io.File.getContent(modFolderPath + optionJson);
							parseCustomOption(jsonContent);
						}
					}
				}
			}
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

	public static function isCustomOption(name:String):Bool {
		for (opt in customOptions) {
			if (opt.name == name) return true;
		}
		return false;
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
