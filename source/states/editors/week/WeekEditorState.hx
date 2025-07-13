package states.editors.week;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flash.net.FileFilter;
import states.StoryMenuState.WeekData;

using StringTools;

class WeekEditorState extends MusicBeatState {
    var weekFile:WeekData;
    var txtWeekTitle:FlxText;
    var txtTracklist:FlxText;
    var uiBox:FlxUITabMenu;
    var grpWeekText:FlxTypedGroup<MenuItem>;
    var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
    var characterFile:MenuChar = null;
    var txtOffsets:FlxText;

    override function create() {
        FlxG.mouse.visible = true;

        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();

        loadWeekFile();

		characterFile = {
            spritePath: "dad",
            offsets: [
                0,
                0
            ],
            scale: 1,
            idle: "idle",
            confirm: "idle"
		};

        txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
        txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
        txtWeekTitle.alpha = 0.7;

        grpWeekText = new FlxTypedGroup<MenuItem>();
        add(grpWeekText);

        var yellowBG:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFF9CF51);

        grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

        var weekThing:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, weekFile.texture);
        weekThing.y += ((weekThing.height + 20) * 0);
        weekThing.targetY = 0;
        grpWeekText.add(weekThing);

        weekThing.screenCenter(X);
        weekThing.antialiasing = true;

        var charArray:Array<String> = weekFile.characters;
        for (char in 0...3) {
            var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
            weekCharacterThing.y += 70;
            grpWeekCharacters.add(weekCharacterThing);
        }

        add(yellowBG);
        add(grpWeekCharacters);

		txtOffsets = new FlxText(20, 10, 0, "[0, 0]", 32);
		txtOffsets.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		txtOffsets.alpha = 0.7;
		add(txtOffsets);

        txtTracklist = new FlxText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 0, "Tracks", 32);
        txtTracklist.alignment = CENTER;
        txtTracklist.setFormat(Paths.font("vcr.ttf"), 32);
        txtTracklist.color = 0xFFe55777;
        add(txtTracklist);

        add(txtWeekTitle);

        addUIBox();
        addWeekUI();
        addMenuCharacterUI();
        updateInformations();
        changeCharacters();
        updateCharTypeBox();
        updateText();

        super.create();
    }

    override function update(elapsed:Float) {
		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;

				if(FlxG.keys.justPressed.ENTER) inputText.hasFocus = false;
				break;
			}
		}

		if(!blockInput) {
            if (FlxG.keys.justPressed.ESCAPE) {
                FlxG.mouse.visible = false;
                FlxG.switchState(new states.editors.EditorMenuState());
                FlxG.sound.playMusic(TitleState.freakyMenu);
            }

            if (uiBox.selected_tab == 0) {
			    var shiftMult:Int = 1;
			    if(FlxG.keys.pressed.SHIFT) shiftMult = 10;

			    if(FlxG.keys.justPressed.LEFT) {
			    	characterFile.offsets[0] += shiftMult;
			    	updateOffset();
			    }
			    if(FlxG.keys.justPressed.RIGHT) {
			    	characterFile.offsets[0] -= shiftMult;
			    	updateOffset();
			    }
			    if(FlxG.keys.justPressed.UP) {
			    	characterFile.offsets[1] += shiftMult;
			    	updateOffset();
			    }
			    if(FlxG.keys.justPressed.DOWN) {
			    	characterFile.offsets[1] -= shiftMult;
			    	updateOffset();
			    }

			    if(FlxG.keys.justPressed.SPACE && curTypeSelected == 1) {
			    	grpWeekCharacters.members[curTypeSelected].animation.play('confirm', true);
			    }
            }
		}

        if (uiBox.selected_tab == 1) {
            for (i in 0...grpWeekCharacters.length) {
                var char:MenuCharacter = grpWeekCharacters.members[i];
                char.alpha = 1;
            }
    
            dadCheckbox.checked = false;
            boyfriendCheckbox.checked = false;
            girlfriendCheckbox.checked = false;
        } else {
            for (i in 0...grpWeekCharacters.length) {
                var char:MenuCharacter = grpWeekCharacters.members[i];
                char.alpha = (i == curTypeSelected) ? 1 : 0.2;
            }

            dadCheckbox.checked = false;
            boyfriendCheckbox.checked = false;
            girlfriendCheckbox.checked = false;

            switch(curTypeSelected) {
                case 0:
                    dadCheckbox.checked = true;
                case 1:
                    boyfriendCheckbox.checked = true;
                case 2:
                    girlfriendCheckbox.checked = true;
            }
        }

		var char:MenuCharacter = grpWeekCharacters.members[1];
		if(char.animation.curAnim != null && char.animation.curAnim.name == 'confirm' && char.animation.curAnim.finished) {
			char.animation.play('idle', true);
		}

        txtWeekTitle.text = weekFile.name.toUpperCase();
        txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

        super.update(elapsed);
    }

    function updateText() {
        txtTracklist.text = "Tracks\n";

        var stringThing:Array<String> = input_weekSongs.text.trim().split(',');

        for (i in stringThing)
            txtTracklist.text += "\n" + i;

        txtTracklist.text = txtTracklist.text.toUpperCase();

        txtTracklist.screenCenter(X);
        txtTracklist.x -= FlxG.width * 0.35;

        txtTracklist.text += "\n";
    }

    function changeCharacters() {
        for (i in 0...grpWeekCharacters.length) {
            grpWeekCharacters.members[i].changeCharacter(weekFile.characters[i]);
        }
    }

    function loadWeekFile(?data:WeekData = null) {
        if (data == null) {
            weekFile = {
                name: "Daddy Dearest",
                texture: "week1",
                songs: ["Bopeebo", "Fresh", "Dadbattle"],
                characters: ["dad", "bf", "gf"],
                difficulties: ["easy", "normal", "hard"]
            }
        } else {
            weekFile = data;
        }
    }

    function addUIBox() {
        var tabs = [{ name: "Week", label: 'Week'}, {name: "Character", label: 'Character'}];
        uiBox = new FlxUITabMenu(null, tabs, true);
        uiBox.resize(400, 200);
        uiBox.x = FlxG.width - uiBox.width - 20;
        uiBox.y = FlxG.height - uiBox.height - 20;
        uiBox.scrollFactor.set();
        add(uiBox);
    }

    var input_texturePath:FlxUIInputText;
    var input_weekName:FlxUIInputText;
    var input_weekSongs:FlxUIInputText;
    var input_weekCharacters:FlxUIInputText;
	var input_weekDifficulties:FlxUIInputText;

    function addWeekUI() {
        var tab_group_week = new FlxUI(null, uiBox);
        tab_group_week.name = "Week";

        input_texturePath = new FlxUIInputText(10, 20, 200, '', 8);
        tab_group_week.add(input_texturePath);

        var opText:FlxText = new FlxText(input_texturePath.x, input_texturePath.y - 15, FlxG.width, "Week texture path", 8);
        tab_group_week.add(opText);

        input_weekName = new FlxUIInputText(10, 50, 200, '', 8);
        tab_group_week.add(input_weekName);

        var opText:FlxText = new FlxText(input_weekName.x, input_weekName.y - 15, FlxG.width, "Week Name", 8);
        tab_group_week.add(opText);

        input_weekSongs = new FlxUIInputText(10, 80, 200, '', 8);
        tab_group_week.add(input_weekSongs);

        var opText:FlxText = new FlxText(input_weekSongs.x, input_weekSongs.y - 15, FlxG.width, "Week Songs", 8);
        tab_group_week.add(opText);

        input_weekCharacters = new FlxUIInputText(10, 110, 200, '', 8);
        tab_group_week.add(input_weekCharacters);

        var opText:FlxText = new FlxText(input_weekCharacters.x, input_weekCharacters.y - 15, FlxG.width, "Week Characters", 8);
        tab_group_week.add(opText);

		input_weekDifficulties = new FlxUIInputText(10, 140, 200, '', 8);
		tab_group_week.add(input_weekDifficulties);

		var opText:FlxText = new FlxText(input_weekDifficulties.x, input_weekDifficulties.y - 15, FlxG.width, "Week Difficulties", 8);
		tab_group_week.add(opText);

        var button:FlxButton = new FlxButton(260, 20, 'Save Week', function() {
            saveWeek(weekFile);
        });
        tab_group_week.add(button);

        var button2:FlxButton = new FlxButton(260, button.y + button.height + 10, 'Load Week', function() {
            loadWeek();
        });
        tab_group_week.add(button2);

        uiBox.addGroup(tab_group_week);
        uiBox.scrollFactor.set();
    }

	var dadCheckbox:FlxUICheckBox;
	var boyfriendCheckbox:FlxUICheckBox;
	var girlfriendCheckbox:FlxUICheckBox;

	var imageInputText:FlxUIInputText;
	var idleInputText:FlxUIInputText;
	var confirmInputText:FlxUIInputText;
	var confirmDescText:FlxText;
	var scaleStepper:FlxUINumericStepper;

	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];

	var curTypeSelected:Int = 0;

    function addMenuCharacterUI() {
        var tab_group_characters = new FlxUI(null, uiBox);
        tab_group_characters.name = "Character";

		dadCheckbox = new FlxUICheckBox(140, 45, null, null, "Dad", 100);
		dadCheckbox.callback = function()
		{
			curTypeSelected = 0;
			updateCharTypeBox();
		};

		boyfriendCheckbox = new FlxUICheckBox(dadCheckbox.x, dadCheckbox.y + 40, null, null, "Boyfriend", 100);
		boyfriendCheckbox.callback = function()
		{
			curTypeSelected = 1;
			updateCharTypeBox();
		};

		girlfriendCheckbox = new FlxUICheckBox(boyfriendCheckbox.x, boyfriendCheckbox.y + 40, null, null, "Girlfriend", 100);
		girlfriendCheckbox.callback = function()
		{
			curTypeSelected = 2;
			updateCharTypeBox();
		};

		imageInputText = new FlxUIInputText(10, 20, 80, characterFile.spritePath, 8);
		imageInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(imageInputText);
		idleInputText = new FlxUIInputText(10, imageInputText.y + 35, 100, characterFile.idle, 8);
		idleInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(idleInputText);
		confirmInputText = new FlxUIInputText(10, idleInputText.y + 35, 100, characterFile.confirm, 8);
		confirmInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(confirmInputText);

		var reloadImageButton:FlxButton = new FlxButton(10, confirmInputText.y + 30, "Reload Char", function() {
			reloadSelectedCharacter();
		});

		scaleStepper = new FlxUINumericStepper(140, imageInputText.y, 0.05, 1, 0.1, 30, 2);

		confirmDescText = new FlxText(10, confirmInputText.y - 18, 0, 'Start Press animation:');

        var button:FlxButton = new FlxButton(260, 20, 'Save Character', function() {
            saveCharacter();
        });
        tab_group_characters.add(button);

        var button2:FlxButton = new FlxButton(260, button.y + button.height + 10, 'Load Character', function() {
            loadCharacter();
        });
        tab_group_characters.add(button2);

		tab_group_characters.add(dadCheckbox);
		tab_group_characters.add(boyfriendCheckbox);
		tab_group_characters.add(girlfriendCheckbox);

		tab_group_characters.add(new FlxText(10, imageInputText.y - 18, 0, 'Sprite file name:'));
		tab_group_characters.add(new FlxText(10, idleInputText.y - 18, 0, 'Idle animation:'));
		tab_group_characters.add(new FlxText(scaleStepper.x, scaleStepper.y - 18, 0, 'Scale:'));

		tab_group_characters.add(reloadImageButton);
		tab_group_characters.add(confirmDescText);
		tab_group_characters.add(imageInputText);
		tab_group_characters.add(idleInputText);
		tab_group_characters.add(confirmInputText);
		tab_group_characters.add(scaleStepper);

        uiBox.addGroup(tab_group_characters);
        uiBox.scrollFactor.set();
    }

	function updateCharTypeBox() {
		dadCheckbox.checked = false;
		boyfriendCheckbox.checked = false;
		girlfriendCheckbox.checked = false;

		switch(curTypeSelected) {
			case 0:
				dadCheckbox.checked = true;
			case 1:
				boyfriendCheckbox.checked = true;
			case 2:
				girlfriendCheckbox.checked = true;
		}

		updateCharacters();
	}

	function updateCharacters() {
        for (i in 0...grpWeekCharacters.length) {
			var char:MenuCharacter = grpWeekCharacters.members[i];
			char.alpha = 0.2;
			char.character = '';
			char.changeCharacter(weekFile.characters[i]);
		}
		reloadSelectedCharacter();
	}

    function reloadSelectedCharacter() {
        var char:MenuCharacter = grpWeekCharacters.members[curTypeSelected];

        char.alpha = 1;
        char.frames = Paths.getSparrowAtlas('week-characters/' + characterFile.spritePath);
        char.animation.addByPrefix('idle', characterFile.idle, 24);
        if(curTypeSelected == 1) char.animation.addByPrefix('confirm', characterFile.confirm, 24, false);

        char.scale.set(characterFile.scale, characterFile.scale);
        char.updateHitbox();
        char.animation.play('idle');

        confirmDescText.visible = (curTypeSelected == 1);
        confirmInputText.visible = (curTypeSelected == 1);
        updateOffset();
    }

	function updateOffset() {
		var char:MenuCharacter = grpWeekCharacters.members[curTypeSelected];
		char.offset.set(characterFile.offsets[0], characterFile.offsets[1]);
		txtOffsets.text = '' + characterFile.offsets;
	}

    function updateInformations() {
        input_texturePath.text = weekFile.texture;
        input_weekName.text = weekFile.name;
        var str:String = weekFile.songs.toString();
        input_weekSongs.text = str.substr(1, str.length - 2);
        var strr:String = weekFile.characters.toString();
        input_weekCharacters.text = strr.substr(1, strr.length - 2);
		var strrr:String = weekFile.difficulties.toString();
		input_weekDifficulties.text = strrr.substr(1, strrr.length - 2);
    }

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
        if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
            if (sender == input_texturePath) {
                grpWeekText.members[0].changeGraphic(input_texturePath.text);
                weekFile.texture = input_texturePath.text;
            } else if (sender == input_weekName) {
                weekFile.name = input_weekName.text;
            } else if (sender == input_weekSongs) {
                weekFile.songs = input_weekSongs.text.trim().split(',');
                updateText();
            } else if (sender == input_weekCharacters) {
                var sex:Array<String> = input_weekCharacters.text.trim().split(',');
                weekFile.characters = [sex[0], sex[1], sex[2]];
                changeCharacters();
            } else if (sender == input_weekDifficulties) {
				weekFile.difficulties = input_weekDifficulties.text.trim().split(',');
			} else if(sender == imageInputText) {
				characterFile.spritePath = imageInputText.text;
			} else if(sender == idleInputText) {
				characterFile.idle = idleInputText.text;
			} else if(sender == confirmInputText) {
				characterFile.confirm = confirmInputText.text;
			}
		} else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			if (sender == scaleStepper) {
				characterFile.scale = scaleStepper.value;
				reloadSelectedCharacter();
			}
		}
    }

    var _file:FileReference;

    function loadWeek() {
        var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
        _file = new FileReference();
        _file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
        _file.addEventListener(Event.CANCEL, onLoadCancel);
        _file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        _file.browse([jsonFilter]);
    }

    function loadCharacter() {
        var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
        _file = new FileReference();
        _file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onCharacterLoadSelect);
        _file.addEventListener(Event.CANCEL, onLoadCancel);
        _file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        _file.browse([jsonFilter]);
    }

    function onCharacterLoadSelect(event:Event):Void {
        _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onCharacterLoadSelect);
        _file.removeEventListener(Event.CANCEL, onLoadCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
    
        _file.addEventListener(Event.COMPLETE, onCharacterLoadComplete);
        _file.load();
    }

    function onCharacterLoadComplete(event:Event):Void {
        _file.removeEventListener(Event.COMPLETE, onCharacterLoadComplete);
        _file.removeEventListener(Event.CANCEL, onLoadCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

        var rawJson:String = _file.data.readUTFBytes(_file.data.length);
        var loadedCharacter:MenuChar = cast haxe.Json.parse(rawJson);

        if (loadedCharacter != null) {
            characterFile.spritePath = loadedCharacter.spritePath;
            characterFile.idle = loadedCharacter.idle;
            characterFile.confirm = loadedCharacter.confirm;
            characterFile.scale = loadedCharacter.scale;
            characterFile.offsets = loadedCharacter.offsets;

            imageInputText.text = characterFile.spritePath;
            idleInputText.text = characterFile.idle;
            confirmInputText.text = characterFile.confirm;
            scaleStepper.value = characterFile.scale;

            reloadSelectedCharacter();
            Logger.log("Character loaded successfully.");
        } else {
            Logger.log("Error: Loaded character data is invalid.");
        }
    }

    var loadedWeek:WeekData = null;
    var loadError:Bool = false;

    function onLoadComplete(_):Void {
        _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
        _file.removeEventListener(Event.CANCEL, onLoadCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

        #if sys
        var fullPath:String = null;
        var jsonLoaded = cast haxe.Json.parse(haxe.Json.stringify(_file));
        if (jsonLoaded.__path != null)
            fullPath = jsonLoaded.__path;

        if(fullPath != null) {
            var rawJson:String = sys.io.File.getContent(fullPath);
            if(rawJson != null) {
                loadedWeek = cast haxe.Json.parse(rawJson);
                if(loadedWeek.characters != null && loadedWeek.name != null) {
                    var cutName:String = _file.name.substr(0, _file.name.length - 5);
                    Logger.log("Successfully loaded file: " + cutName);
                    loadError = false;
                    _file = null;

                    checkJson();
                    updateInformations();
                    changeCharacters();
                    updateText();
                    grpWeekText.members[0].changeGraphic(input_texturePath.text);

                    return;
                }
            }
        }
        loadError = true;
        loadedWeek = null;
        _file = null;
        #else
        Logger.log("Error: File couldn't be loaded! You aren't on Desktop, are you?");
        #end
    }

    function checkJson() {
        weekFile = {
            name: loadedWeek.name,
            texture: loadedWeek.texture,
            songs: loadedWeek.songs,
            characters: loadedWeek.characters,
            difficulties: loadedWeek.difficulties
        }
    }

    /**
    * Called when the save file dialog is cancelled.
    */
    function onLoadCancel(_):Void {
        _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
        _file.removeEventListener(Event.CANCEL, onLoadCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        _file = null;
        Logger.log("Cancelled file loading.");
    }

    /**
    * Called if there is an error while saving the gameplay recording.
    */
    function onLoadError(_):Void {
        _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
        _file.removeEventListener(Event.CANCEL, onLoadCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        _file = null;
        Logger.log("Error: Problem loading file");
    }

    function saveWeek(weekFile:WeekData) {
        var data:String = haxe.Json.stringify(weekFile, "\t");
        if (data.length > 0) {
            _file = new FileReference();
            _file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
            _file.addEventListener(Event.CANCEL, onSaveCancel);
            _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
            _file.save(data, "week.json");
        }
    }

	function saveCharacter() {
		var data:String = haxe.Json.stringify(characterFile, "\t");

		openfl.system.System.setClipboard(data.trim());

		if (data.length > 0) {
			var splittedImage:Array<String> = imageInputText.text.trim().split('_');
			var characterName:String = splittedImage[splittedImage.length-1].toLowerCase().replace(' ', '');

			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, characterName + ".json");
		}
	}

    function onSaveComplete(_):Void {
        _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        Logger.log("Successfully saved file.");
    }

    function onSaveCancel(_):Void {
        _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
    }

    function onSaveError(_):Void {
        _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        Logger.log("Error: Problem saving file");
    }
}
