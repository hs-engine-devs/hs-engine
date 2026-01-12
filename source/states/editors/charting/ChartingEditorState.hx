package states.editors.charting;

import game.Event;
import game.Event.ChartEvent;
import game.Event.EventListData;
import game.Event.EventSection;
import system.Conductor.BPMChangeEvent;
import system.Section.SwagSection;
import system.Song.SwagSong;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

using StringTools;

class ChartingEditorState extends MusicBeatState
{
	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	var validEvents:Array<EventListData> = [
		{ eventName: "bpm change", var1Hint: "New BPM", var2Hint: null, info: "Changes the song's tempo" },
		{ eventName: "play animation", var1Hint: "Animation name", var2Hint: "Target (e.g., bf, dad)", info: "Plays a character's animation" },
		{ eventName: "camera follow pos", var1Hint: "X", var2Hint: "Y", info: "Sets camera follow position" },
		{ eventName: "change character", var1Hint: "Target (bf/dad/gf)", var2Hint: "Character name", info: "Changes the character during the song" },
		{ eventName: "screen shake", var1Hint: "Intensity", var2Hint: "Duration (seconds)", info: "Shakes the screen" },
		{ eventName: "flash", var1Hint: "Duration (seconds)", var2Hint: "Color (e.g., 'red', '#FF0000')", info: "Screen flash with specified color" },
		{ eventName: "add camera zoom", var1Hint: "Zoom value", var2Hint: null, info: "Adds zoom to the camera" },
		{ eventName: "tween hud alpha", var1Hint: "Alpha value (0-1)", var2Hint: "Duration (seconds)", info: "Animates HUD transparency" },
		{ eventName: "set hud alpha", var1Hint: "Alpha value (0-1)", var2Hint: null, info: "Sets HUD transparency" }
	];

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;

	public static var lastSection:Int = 0;

	var bpmTxt:FlxText;

	var strumLine:FlxSprite;
	var curSong:String = 'Dadbattle';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

	var GRID_SIZE:Int = 40;
	var gridSnap:Int = 16;

	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedEvents:FlxTypedGroup<Event>;
	var ignoreRenderShit:FlxGroup = new FlxGroup();

	var bg:FlxSprite;
	var gridBG:FlxSprite;
	var eventGridBG:FlxSprite;

	var sectionBGs:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();
	var eventSectionBGs:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();

	var funnyCamObj:FlxSprite;

	var _song:SwagSong;

	var typingShit:FlxInputText;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;
	var curSelectedEvents:Array<ChartEvent> = [];

	var curEditingEventIndex:Int = 0;

	var tempBpm:Float = 0;

	var vocals:FlxSound;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

    var selectionBox:FlxSprite;
    var startMousePos:FlxPoint = new FlxPoint();
    var isSelecting:Bool = false;

    var selectedNotesGroup:Array<Note> = [];
	var oldSelectionData:Array<{time:Float, data:Int}> = [];
	var selectShader:SelectionShader = new SelectionShader();

	var copyBuffer:Array<Array<Dynamic>> = [];

	override function create()
	{
		curSection = lastSection;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.scrollFactor.set(0, 0);
        bg.color = 0xFF303030;
		add(bg);

		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);

		eventGridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE, GRID_SIZE * 16);
		eventGridBG.x -= GRID_SIZE;

        var invisEventGridBG1 = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE, GRID_SIZE * 16);
		invisEventGridBG1.x -= GRID_SIZE;
        invisEventGridBG1.y = (eventGridBG.height * -1);
        invisEventGridBG1.alpha = 0.75;
        eventSectionBGs.add(invisEventGridBG1);

        eventSectionBGs.add(eventGridBG);

        var invisEventGridBG2 = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE, GRID_SIZE * 16);
		invisEventGridBG2.x -= GRID_SIZE;
        invisEventGridBG2.y = eventGridBG.height;
        invisEventGridBG2.alpha = 0.75;

        eventSectionBGs.add(invisEventGridBG2);
        add(eventSectionBGs);

		var invisGridBG1 = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		invisGridBG1.y = (gridBG.height * -1);
		invisGridBG1.alpha = 0.75;
		sectionBGs.add(invisGridBG1);

		sectionBGs.add(gridBG);

		var invisGridBG2 = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		invisGridBG2.y = gridBG.height;
		invisGridBG2.alpha = 0.75;
		
		sectionBGs.add(invisGridBG2);

		add(sectionBGs);

		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad');
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		leftIcon.setPosition(0, -100);
		rightIcon.setPosition(gridBG.width / 2, -100);

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width / 2, gridBG.height * -1).makeGraphic(2, Std.int(gridBG.height * 3), FlxColor.BLACK);
		add(gridBlackLine);

		var gridEventLine:FlxSprite = new FlxSprite(0, gridBG.height * -1).makeGraphic(2, Std.int(gridBG.height * 3), FlxColor.BLACK);
		add(gridEventLine);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedEvents = new FlxTypedGroup<Event>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
		{
			_song = {
				song: 'Test',
				notes: [],
				events: [],
				bpm: 150,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				speed: 1,
				validScore: false
			};
		}

		// psych chart
        if (_song != null && _song.notes != null)
        {
            for (section in _song.notes)
            {
                if (Reflect.hasField(section, "sectionBeats")) 
                {
                    var beats:Float = Reflect.field(section, "sectionBeats");
                    section.lengthInSteps = Std.int(beats * 4);
                    Reflect.deleteField(section, "sectionBeats");
                }
            }
        }

		FlxG.mouse.visible = true;
		FlxG.save.bind('funkin', 'ninjamuffin99');

		tempBpm = _song.bpm;

		addSection();
		addEventSection();

		// sections = _song.notes;

		updateGrid();

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(-40, 50).makeGraphic(Std.int(gridBG.width + eventGridBG.width), 4);
		add(strumLine);

		funnyCamObj = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4);
		funnyCamObj.alpha = 0;
		add(funnyCamObj);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2;
		UI_box.y = 20;
		add(UI_box);

		addSongUI();
		addSectionUI();
		addNoteUI();
		addEventsUI();
        updateHeads();
        changeSection();

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedEvents);
		add(ignoreRenderShit);

		add(leftIcon);
		add(rightIcon);

        selectionBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLUE);
        selectionBox.alpha = 0.3;
        selectionBox.visible = false;
        add(selectionBox);

		super.create();
	}

	var eventDropDown:FlxUIDropDownMenu;
	var eventVar1:FlxUIInputText;
	var eventVar2:FlxUIInputText;
	var loadCurEvent:Void -> Void;

	function addEventsUI():Void {
		var tab_events = new FlxUI(null, UI_box);
		tab_events.name = 'Events';

		var events:Array<EventListData> = [];
		var eventNames:Array<String> = [];

		for (array in validEvents) {
			if (array != null) {
				events.push(array);
				eventNames.push(array.eventName);
			}
		}

		#if sys
		for (modFolder in ModPaths.getModFolders()) {
			if (modFolder.enabled) {
				var modFolderPath = 'mods/' + modFolder.folder + '/data/events/';
				if (sys.FileSystem.isDirectory(modFolderPath)) {
					for (eventJson in sys.FileSystem.readDirectory(modFolderPath)) {
						if (eventJson != null && eventJson.endsWith('.json')) {
							var jsonContent = sys.io.File.getContent(modFolderPath + eventJson);
							var parsedData:Dynamic = haxe.Json.parse(jsonContent);
							if (Std.is(parsedData, Array)) {
								var eventArray:Array<Dynamic> = cast parsedData;
								for (event in eventArray) {
									var eventData:EventListData = {
										eventName: event.eventName,
										var1Hint: event.var1Hint,
										var2Hint: event.var2Hint,
										info: event.info
									};
									events.push(eventData);
									eventNames.push(eventData.eventName);
								}
							} else {
								var event = parsedData;
								var eventData:EventListData = {
									eventName: event.eventName,
									var1Hint: event.var1Hint,
									var2Hint: event.var2Hint,
									info: event.info
								};
								events.push(eventData);
								eventNames.push(eventData.eventName);
							}
						}
					}
				}
			}
		}
		#end

		eventVar1 = new FlxUIInputText(10, 70);
		var eventVar1InfoText = new FlxText(eventVar1.x, eventVar1.y - 20);

		eventVar2 = new FlxUIInputText(10, 120);
		var eventVar2InfoText = new FlxText(eventVar2.x, eventVar2.y - 20);

		var eventInstructionText = new FlxText(10, 170);
		eventInstructionText.text = "Left click to add or remove an event.\nRight click to edit events.\nClick 'Update' to save Event Changes.\nPlacing an event also saves.\n\nUse 'Add New Event' to\nadd multiple events to the same note.\n\nUse 'Next Event' to switch between\nevents of the same strumtime.\n\nUse 'Remove Event' to delete the current event.";

		eventDropDown = new FlxUIDropDownMenu(10, 20, FlxUIDropDownMenu.makeStrIdLabelArray(eventNames, true), function(selectedLabel:String) {
			if (curSelectedEvents.length > 0) {
				var selected = curSelectedEvents[curEditingEventIndex];
				selected.event = eventNames[Std.parseInt(selectedLabel)];

				for (event in events) {
					if (event != null && event.eventName.toLowerCase() == selected.event.toLowerCase()) {
						eventVar1InfoText.text = event.var1Hint;
						eventVar2InfoText.text = event.var2Hint;
						eventInstructionText.text = event.info;
						break;
					}
				}
			}
		});

		var saveButton:FlxButton = new FlxButton(200, 20, "Update", function() {
			if (curSelectedEvents.length > 0) {
				var selected = curSelectedEvents[curEditingEventIndex];
				selected.event = eventDropDown.selectedLabel;
				selected.variable1 = eventVar1.text;
				selected.variable2 = eventVar2.text;
			}
		});

		var addNewEventButton = new FlxButton(200, 60, "Add New Event", function() {
			if (curSelectedEvents.length > 0) {
				var selected = curSelectedEvents[curEditingEventIndex];
				selected.variable1 = eventVar1.text;
				selected.variable2 = eventVar2.text;
			}

            var noteStrum:Float = (curSelectedEvents.length > 0) 
                ? curSelectedEvents[curEditingEventIndex].strumtime 
                : getSnappedStrumTime(dummyArrow.y - gridBG.y) + sectionStartTime();

			var newEvent:ChartEvent = {
				strumtime: noteStrum,
				event: eventDropDown.selectedLabel,
				variable1: eventVar1.text,
				variable2: eventVar2.text
			};

			_song.events[curSection].eventNotes.push(newEvent);

			curSelectedEvents = _song.events[curSection].eventNotes.filter(function(e) return e.strumtime == noteStrum);
			curEditingEventIndex = curSelectedEvents.length - 1;

			updateGrid();
			autosaveSong();
			loadCurEvent();
		});

		var nextEventButton = new FlxButton(200, 100, "Next Event", function() {
			if (curSelectedEvents.length > 1) {
				curEditingEventIndex = (curEditingEventIndex + 1) % curSelectedEvents.length;
				loadCurEvent();
			}
		});

		var removeEventButton = new FlxButton(200, 140, "Remove Event", function() {
			if (curSelectedEvents.length > 0) {
				var selected = curSelectedEvents[curEditingEventIndex];
				_song.events[curSection].eventNotes.remove(selected);

				curSelectedEvents = _song.events[curSection].eventNotes.filter(function(e) return e.strumtime == selected.strumtime);

				if (curSelectedEvents.length > 0) {
					curEditingEventIndex = curEditingEventIndex % curSelectedEvents.length;
				} else {
					curEditingEventIndex = 0;
				}

				updateGrid();
				loadCurEvent();
			}
		});

		loadCurEvent = function() {
			if (curSelectedEvents.length > 0) {
				var selected = curSelectedEvents[curEditingEventIndex];
				eventDropDown.selectedLabel = selected.event;

				eventVar1.text = selected.variable1;
				eventVar2.text = selected.variable2;

				for (event in events) {
					if (event != null && event.eventName.toLowerCase() == eventNames[eventNames.indexOf(selected.event)].toLowerCase()) {
						eventVar1InfoText.text = event.var1Hint;
						eventVar2InfoText.text = event.var2Hint;
						eventInstructionText.text = event.info;
						break;
					}
				}
			}
		}

		tab_events.add(eventVar1);
		tab_events.add(eventVar2);
		tab_events.add(eventVar1InfoText);
		tab_events.add(eventVar2InfoText);
		tab_events.add(eventInstructionText);
		tab_events.add(saveButton);
		tab_events.add(addNewEventButton);
		tab_events.add(nextEventButton);
		tab_events.add(removeEventButton);
		tab_events.add(eventDropDown);

		UI_box.addGroup(tab_events);
		UI_box.scrollFactor.set();
	}

    var stageInput:FlxUIInputText;
	var gfInput:FlxUIInputText;

	function addSongUI():Void
	{
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
		};

		var check_mute_inst = new FlxUICheckBox(10, 200, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function()
		{
			loadSong(_song.song);
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			loadJson(_song.song.toLowerCase());
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'load autosave', loadAutosave);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 1, 1, 1, 339, 0);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		#if sys
 		var directories:Array<String> = [ModPaths.modFolder('data/characters/'), Paths.getPreloadPath('data/characters/')];
 		#else
 		var directories:Array<String> = [Paths.getPreloadPath('data/characters/')];
 		#end

 		var tempMap:Map<String, Bool> = new Map<String, Bool>();
 		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

 		for (i in 0...characters.length) {
 			tempMap.set(characters[i], true);
 		}

 		#if sys
 		for (i in 0...directories.length) {
 			var directory:String = directories[i];
 			if(sys.FileSystem.exists(directory)) {
 				for (file in sys.FileSystem.readDirectory(directory)) {
 					var path = haxe.io.Path.join([directory, file]);
 					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json')) {
 						var charToCheck:String = file.substr(0, file.length - 5);
 						if(!charToCheck.endsWith('-dead') && !tempMap.exists(charToCheck)) {
 							tempMap.set(charToCheck, true);
 							characters.push(charToCheck);
 						}
 					}
 				}
 			}
 		}
 		#end

		var player1DropDown = new FlxUIDropDownMenu(10, 120, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
            updateHeads();
		});
		player1DropDown.selectedLabel = _song.player1;

        var playerText:FlxText = new FlxText(player1DropDown.x, player1DropDown.y - 15, FlxG.width, "Player", 8);

		var player2DropDown = new FlxUIDropDownMenu(140, 120, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
            updateHeads();
		});

		player2DropDown.selectedLabel = _song.player2;

        var opponentText:FlxText = new FlxText(player2DropDown.x, player2DropDown.y - 15, FlxG.width, "Opponent", 8);

        stageInput = new FlxUIInputText(10, 160, 120, _song.stage != null ? _song.stage : "", 8);
		var opText:FlxText = new FlxText(stageInput.x, stageInput.y - 15, FlxG.width, "Stage", 8);

        gfInput = new FlxUIInputText(140, 160, 120, _song.gfVersion != null ? _song.gfVersion : "", 8);
		var opText2:FlxText = new FlxText(gfInput.x, gfInput.y - 15, FlxG.width, "Gf", 8);

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(check_mute_inst);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(stageInput);
		tab_group_song.add(opText);
		tab_group_song.add(gfInput);
		tab_group_song.add(opText2);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(playerText);
		tab_group_song.add(player2DropDown);
		tab_group_song.add(opponentText);

		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		FlxG.camera.follow(funnyCamObj);
	}

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSection].lengthInSteps;
		stepperLength.name = "section_length";

		stepperSectionBPM = new FlxUINumericStepper(10, 80, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);

		var copyButton:FlxButton = new FlxButton(10, 130, "Copy last section", function()
		{
			copySection(Std.int(stepperCopy.value));
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear Section", clearSection);
 		var clearSongButton:FlxButton = new FlxButton(10, 170, "Clear Song", clearSong);

		var swapSection:FlxButton = new FlxButton(10, 190, "Swap section", function()
		{
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				var note = _song.notes[curSection].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSection].sectionNotes[i] = note;
				updateGrid();
			}
		});

		check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = true;
		// _song.needsVoices = check_mustHit.checked;

		check_altAnim = new FlxUICheckBox(10, 400, null, null, "Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, 60, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		tab_group_section.add(stepperLength);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(clearSongButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(swapSection);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;
	var inputNoteType:FlxUIInputText;

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		var noteTypeLabel = new FlxText(10, 40, 100, "Note Type:");
		noteTypeLabel.setFormat(null, 8, 0xFFFFFF, "left");

		inputNoteType = new FlxUIInputText(10, 60, 100, "", 8);
		inputNoteType.name = 'note_type';

		var applyLength:FlxButton = new FlxButton(100, 10, 'Apply');

		tab_group_note.add(stepperSusLength);
		tab_group_note.add(noteTypeLabel);
		tab_group_note.add(inputNoteType);
		tab_group_note.add(applyLength);

		UI_box.addGroup(tab_group_note);
	}

	function loadSong(daSong:String):Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		FlxG.sound.playMusic(Paths.inst(daSong), 0.6);

		// WONT WORK FOR TUTORIAL OR TEST SONG!!! REDO LATER
		vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));
		FlxG.sound.list.add(vocals);

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.onComplete = function()
		{
			vocals.pause();
			vocals.time = 0;
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		};
	}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
		/* 
			var loopCheck = new FlxUICheckBox(UI_box.x + 10, UI_box.y + 50, null, null, "Loops", 100, ['loop check']);
			loopCheck.checked = curNoteSelected.doesLoop;
			tooltips.add(loopCheck, {title: 'Section looping', body: "Whether or not it's a simon says style section", style: tooltipType});
			bullshitUI.add(loopCheck);

		 */
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':
					_song.notes[curSection].mustHitSection = check.checked;

					updateHeads();

				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[curSection].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_length')
			{
				_song.notes[curSection].lengthInSteps = Std.int(nums.value);
				updateGrid();
			}
			else if (wname == 'song_speed')
			{
				_song.speed = nums.value;
			}
			else if (wname == 'song_bpm')
			{
				tempBpm = Std.int(nums.value);
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(Std.int(nums.value));
			}
			else if (wname == 'note_susLength')
			{
				curSelectedNote[2] = nums.value;
				updateGrid();
			}
			else if (wname == 'note_type')
			{
				curSelectedNote[3] = nums.value;
				updateGrid();
			}
			else if (wname == 'section_bpm')
			{
				_song.notes[curSection].bpm = Std.int(nums.value);
				updateGrid();
			}
		}
		else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == stageInput) {
				_song.stage = stageInput.text != "" ? stageInput.text : null;
			} else if (sender == gfInput) {
				_song.gfVersion = gfInput.text != "" ? gfInput.text : null;
			}
		}
		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	/* this function got owned LOL
		function lengthBpmBullshit():Float
		{
			if (_song.notes[curSection].changeBPM)
				return _song.notes[curSection].lengthInSteps * (_song.notes[curSection].bpm / _song.bpm);
			else
				return _song.notes[curSection].lengthInSteps;
	}*/
	function sectionStartTime(?section:Int):Float
	{
		if (section == null)
			section = curSection;

		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...section)
		{
			if (_song.notes[i].changeBPM)
			{
				daBPM = _song.notes[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();

		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = typingShit.text;

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps));
		funnyCamObj.y = strumLine.y;

		if (curBeat % 4 == 0 && curStep >= 16 * (curSection + 1))
		{
			if (_song.notes[curSection + 1] == null)
			{
				addSection();
			}

			changeSection(curSection + 1, false);
		}

		if (curStep < 16 * curSection && _song.notes[curSection - 1] != null) {
			changeSection(curSection - 1, false);
		}

		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

        if (FlxG.keys.pressed.SHIFT && FlxG.mouse.justPressed && FlxG.mouse.x >= 0 && FlxG.mouse.x <= gridBG.width) {
            isSelecting = true;
            startMousePos.set(FlxG.mouse.x, FlxG.mouse.y);
            selectionBox.visible = true;

            for (note in selectedNotesGroup) if (note != null) note.shader = null;
            selectedNotesGroup = []; 
            oldSelectionData = [];
        }

        if (FlxG.mouse.justPressed && !FlxG.keys.pressed.SHIFT && !isSelecting) 
        {
            var clickedOnNote:Bool = false;
            curRenderedNotes.forEachAlive(function(n:Note) {
                if (FlxG.mouse.overlaps(n)) clickedOnNote = true;
            });

            if (!clickedOnNote) {
                for (note in selectedNotesGroup) if (note != null) note.shader = null;
                selectedNotesGroup = [];
                oldSelectionData = [];
                updateGrid(); 
            }
        }

        if (isSelecting) {
            var minX = Math.min(FlxG.mouse.x, startMousePos.x);
            var minY = Math.min(FlxG.mouse.y, startMousePos.y);
            var maxX = Math.max(FlxG.mouse.x, startMousePos.x);
            var maxY = Math.max(FlxG.mouse.y, startMousePos.y);

            selectionBox.x = minX;
            selectionBox.y = minY;
            selectionBox.scale.set(Math.max(1, maxX - minX), Math.max(1, maxY - minY));
            selectionBox.updateHitbox();

            if (FlxG.mouse.justReleased) {
                isSelecting = false;
                selectionBox.visible = false;

                curRenderedNotes.forEachAlive(function(note:Note) {
                    if (selectionBox.getHitbox().overlaps(note.getHitbox())) {
                        if (!selectedNotesGroup.contains(note)) {
                            selectedNotesGroup.push(note);
                            note.shader = selectShader;
                        }
                    }
                });
            }
        }

        var movedSomething:Bool = false;
        if (selectedNotesGroup.length > 0 && !typingShit.hasFocus && !isSelecting) {
            var moveTime:Bool = FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN;
            var moveData:Bool = FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT;
            if (moveTime || moveData) {
                movedSomething = true;
                for (note in selectedNotesGroup) {
                    for (songNote in _song.notes[curSection].sectionNotes) {
                        if (Math.abs(songNote[0] - note.strumTime) < 2 && songNote[1] == note.noteData) {
                            if (moveTime) {
                                var multiplier:Int = (FlxG.keys.justPressed.UP) ? -1 : 1;
                                songNote[0] += Conductor.stepCrochet * multiplier;
                                note.strumTime = songNote[0];
                            }
                            if (moveData) {
                                var addCol:Int = (FlxG.keys.justPressed.RIGHT) ? 1 : -1;
                                songNote[1] = (Std.int(songNote[1]) + addCol) % 8;
                                if (songNote[1] < 0) songNote[1] = 7;
                                note.noteData = Std.int(songNote[1]);
                            }
                            break;
                        }
                    }
                }
                updateGrid();
            }
        }

        if (selectedNotesGroup.length > 0 && FlxG.keys.justPressed.BACKSPACE) {
            for (note in selectedNotesGroup) {
                for (songNote in _song.notes[curSection].sectionNotes) {
                    if (Math.abs(songNote[0] - note.strumTime) < 2 && songNote[1] == note.noteData) {
                        _song.notes[curSection].sectionNotes.remove(songNote);
                        break;
                    }
                }
            }
            selectedNotesGroup = [];
            oldSelectionData = [];
            updateGrid();
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C && selectedNotesGroup.length > 0) {
            copyBuffer = [];
            for (note in selectedNotesGroup) {
                for (songNote in _song.notes[curSection].sectionNotes) {
                    if (Math.abs(songNote[0] - note.strumTime) < 2 && Std.int(songNote[1] % 4) == note.noteData) {
                        var noteType:String = (songNote.length > 3) ? songNote[3] : "";
                        copyBuffer.push([songNote[0], songNote[1], songNote[2], noteType]);
                        break;
                    }
                }
            }
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V && copyBuffer.length > 0) {
            var minTime:Float = copyBuffer[0][0];
            for (n in copyBuffer) if (n[0] < minTime) minTime = n[0];

            for (n in copyBuffer) {
                var newTime:Float = curStep * Conductor.stepCrochet + (n[0] - minTime);
                var newData:Int = n[1];
                var newSus:Float = n[2];
                var newType:String = ""; 
                if (n.length > 3 && n[3] != null) {
                    newType = n[3];
                }
                _song.notes[curSection].sectionNotes.push([newTime, newData, newSus, newType]);
            }
            updateGrid();
        }

		var shiftThing:Int = 1;
		if (FlxG.keys.pressed.SHIFT)
			shiftThing = 4;

		if (FlxG.keys.justPressed.SPACE && !typingShit.hasFocus)
		{
			if (FlxG.sound.music.playing)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}
			else
			{
				vocals.play();
				FlxG.sound.music.play();
			}
		}

		if (!typingShit.hasFocus && !FlxG.mouse.overlaps(UI_box))
		{
			if (!FlxG.keys.pressed.SHIFT)
			{
				if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();
	
					var daTime:Float = 700 * FlxG.elapsed;
	
					if (FlxG.keys.pressed.W)
					{
						FlxG.sound.music.time -= daTime;
					}
					else
						FlxG.sound.music.time += daTime;
	
					vocals.time = FlxG.sound.music.time;
				}
			}
			else
			{
				if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();
	
					var daTime:Float = Conductor.stepCrochet * 2;
	
					if (FlxG.keys.justPressed.W)
					{
						FlxG.sound.music.time -= daTime;
					}
					else
						FlxG.sound.music.time += daTime;
	
					vocals.time = FlxG.sound.music.time;
					
				}
			}
		}

		if (!isSelecting && !FlxG.keys.pressed.SHIFT &&FlxG.mouse.x <= gridBG.width && FlxG.mouse.x >= 0)
		{
			if (FlxG.mouse.justPressed)
				{
					if (FlxG.mouse.overlaps(curRenderedNotes))
					{
						curRenderedNotes.forEach(function(note:Note)
						{
							if (FlxG.mouse.overlaps(note))
							{
								if (FlxG.keys.pressed.CONTROL)
								{
									selectNote(note);
								}
								else
								{
									deleteNote(note);
								}
							}
						});
					}
					else
					{
						if (FlxG.mouse.x > gridBG.x
							&& FlxG.mouse.x < gridBG.x + gridBG.width
							&& FlxG.mouse.y > gridBG.y
							&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
						{
							FlxG.log.add('added note');
							addNote();
						}
					}
				}

                if (FlxG.mouse.x > gridBG.x && FlxG.mouse.x < gridBG.x + gridBG.width &&
                    FlxG.mouse.y > gridBG.y && FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
                {
                    dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
                    if (FlxG.keys.pressed.SHIFT)
                        dummyArrow.y = FlxG.mouse.y;
                    else {
                        var snappedTime = getSnappedStrumTime(FlxG.mouse.y - gridBG.y);
                        dummyArrow.y = getYfromStrum(snappedTime);
                    }
                }

				if (FlxG.keys.justPressed.ENTER)
				{
					lastSection = curSection;
					PlayState.SONG = _song;
					FlxG.sound.music.stop();
					vocals.stop();
					FlxG.switchState(new PlayState());
				}

				if (FlxG.keys.justPressed.E)
				{
					changeNoteSustain(Conductor.stepCrochet);
				}
				if (FlxG.keys.justPressed.Q)
				{
					changeNoteSustain(-Conductor.stepCrochet);
				}

				if (FlxG.keys.justPressed.TAB)
				{
					if (FlxG.keys.pressed.SHIFT)
					{
						UI_box.selected_tab -= 1;
						if (UI_box.selected_tab < 0)
							UI_box.selected_tab = 2;
					}
					else
					{
						UI_box.selected_tab += 1;
						if (UI_box.selected_tab >= 3)
							UI_box.selected_tab = 0;
					}
				}

				if (!typingShit.hasFocus)
				{		
					if (FlxG.keys.justPressed.R)
					{
						if (FlxG.keys.pressed.SHIFT)
							resetSection(true);
						else
							resetSection();
					}
		
					if (FlxG.mouse.wheel != 0)
					{
						FlxG.sound.music.pause();
						vocals.pause();
		
						FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4);
						vocals.time = FlxG.sound.music.time;
					}
				}

                var shiftThing:Int = (FlxG.keys.pressed.SHIFT) ? 4 : 1;
                if (!movedSomething && !typingShit.hasFocus) {
                    if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
                        changeSection(curSection + shiftThing, true);
                    if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
                        changeSection(curSection - shiftThing, true);
                }
		}

		if (FlxG.mouse.x < 0 && FlxG.mouse.x >= -40 && FlxG.mouse.y >= eventGridBG.y && FlxG.mouse.y < eventGridBG.height) {
			dummyArrow.x = eventGridBG.x;

			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;

			if (FlxG.mouse.justPressed) {
				if (FlxG.mouse.overlaps(curRenderedEvents)) {
					curSelectedEvents = [];

					curRenderedEvents.forEach(function(event:Event) {
						if (FlxG.mouse.overlaps(event)) {
							if (FlxG.keys.pressed.CONTROL) {
								var strum = event.thisEvent.strumtime;
								curSelectedEvents = _song.events[curSection].eventNotes.filter(function(e) return e.strumtime == strum);
								curEditingEventIndex = 0;
								loadCurEvent();
							} else {
								deleteEvent(event);
							}
						}
					});
				} else {
					UI_box.selected_tab_id = 'Events';
					addEvent();
				}
			}

			if (FlxG.mouse.justPressedRight) {
				if (FlxG.mouse.overlaps(curRenderedEvents)) {
					curSelectedEvents = [];
					curRenderedEvents.forEach(function(event:Event) {
						if (FlxG.mouse.overlaps(event)) {
							var strum = event.thisEvent.strumtime;
							curSelectedEvents = _song.events[curSection].eventNotes.filter(function(e) return e.strumtime == strum);
							curEditingEventIndex = 0;
							loadCurEvent();
						}
					});
				}
			}
		}

		_song.bpm = tempBpm;

		bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
		    + " / "
		    + Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))
		    + "\nSection: "
		    + Std.string(curSection)
		    + "\nStep: "
		    + Std.string(curStep)
		    + "\nBeat: "
		    + Std.string(curBeat);
		super.update(elapsed);
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		vocals.pause();

		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		vocals.time = FlxG.sound.music.time;
		updateCurStep();

		updateGrid();
		updateSectionUI();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		if (_song.notes[sec] != null)
		{
			curSection = sec;

            if (_song.notes[curSection] != null) {
                var sectionData = _song.notes[curSection];
                if (Reflect.hasField(sectionData, "sectionBeats")) {
                    var beats = Reflect.field(sectionData, "sectionBeats");
                    if (sectionData.lengthInSteps == 0 || sectionData.lengthInSteps == -1) {
                         sectionData.lengthInSteps = Std.int(beats * 4);
                    }
                }
                stepperLength.value = sectionData.lengthInSteps;
            }

			updateGrid();

			if (updateMusic)
			{
				FlxG.sound.music.pause();
				vocals.pause();

				/*var daNum:Int = 0;
					var daLength:Float = 0;
					while (daNum <= sec)
					{
						daLength += lengthBpmBullshit();
						daNum++;
				}*/

				FlxG.sound.music.time = sectionStartTime();
				vocals.time = FlxG.sound.music.time;
				updateCurStep();
			}

			// updateGrid();
			updateSectionUI();
		}
	}

	function copySection(?sectionNum:Int = 1)
	{
		var daSec = FlxMath.maxInt(curSection, sectionNum);

		for (note in _song.notes[daSec - sectionNum].sectionNotes)
		{
			var strum = note[0] + Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * sectionNum);

			var copiedNote:Array<Dynamic> = [strum, note[1], note[2]];
			_song.notes[daSec].sectionNotes.push(copiedNote);
		}

		updateGrid();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSection];

		stepperLength.value = sec.lengthInSteps;
		check_mustHitSection.checked = sec.mustHitSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	function updateHeads():Void
	{
        var healthIconP1:String = loadHealthIconFromCharacter(_song.player1);
        var healthIconP2:String = loadHealthIconFromCharacter(_song.player2);

		if (check_mustHitSection.checked)
		{
			leftIcon.changeIcon(healthIconP1);
 			rightIcon.changeIcon(healthIconP2);
		}
		else
		{
			leftIcon.changeIcon(healthIconP2);
 			rightIcon.changeIcon(healthIconP1);
		}
	}

	function loadHealthIconFromCharacter(char:String) {
        var rawJson = null;

        #if sys
        var moddyFile:String = ModPaths.data("characters/" + char);
        if(sys.FileSystem.exists(moddyFile)) {
            rawJson = sys.io.File.getContent(moddyFile);
        }
        #end

        if(rawJson == null) {
            #if sys
            rawJson = sys.io.File.getContent(Paths.json("characters/" + char));
            #else
            rawJson = Assets.getText(Paths.json("characters/" + char));
            #end
        }

        var json:game.Character.CharJson = cast Json.parse(rawJson);
        return json.healthIcon;
    }

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
			stepperSusLength.value = curSelectedNote[2];
	}

	function updateGrid():Void
	{
        oldSelectionData = []; 

        for (note in selectedNotesGroup) {
            if (note != null) oldSelectionData.push({time: note.strumTime, data: note.noteData});
        }

        selectedNotesGroup = [];

		curRenderedNotes.clear();
		curRenderedSustains.clear();
		curRenderedEvents.clear();
		ignoreRenderShit.clear();

		var sectionInfo:Array<Dynamic> = _song.notes[curSection].sectionNotes;

		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}

		/* // PORT BULLSHIT, INCASE THERE'S NO SUSTAIN DATA FOR A NOTE
			for (sec in 0..._song.notes.length)
			{
				for (notesse in 0..._song.notes[sec].sectionNotes.length)
				{
					if (_song.notes[sec].sectionNotes[notesse][2] == null)
					{
						Logger.log('SUS NULL');
						_song.notes[sec].sectionNotes[notesse][2] = 0;
					}
				}
			}
		*/

        if ((curSection - 1) >= 0 && curSection < _song.notes.length - 1 && _song.notes[curSection - 1] != null)
	    {
	    	for (i in _song.notes[curSection - 1].sectionNotes)
	    	{
	    		generateSection(i, -1, curSection);
	    	}
	    	if (_song.events[curSection - 1] != null && _song.events[curSection - 1].eventNotes != null) {
	    		for (i in _song.events[curSection - 1].eventNotes) {
	    			if (i != null)
	    				generateEventSection(i, -1, curSection);
	    		}
	    	}
	    }

	    if (curSection < _song.notes.length - 1)
	    {
	    	for (i in _song.notes[curSection + 1].sectionNotes)
	    	{
	    		generateSection(i, 1, curSection);
	    	}
	    	if (_song.events[curSection + 1] != null && _song.events[curSection + 1].eventNotes != null) {
	    		for (i in _song.events[curSection + 1].eventNotes) {
	    			if (i != null)
	    				generateEventSection(i, 1, curSection);
	    		}
	    	}
	    }

	    for (i in sectionInfo)
	    {
	    	generateSection(i, 0, curSection);
	    }
	    if (_song.events[curSection] != null && _song.events[curSection].eventNotes != null) {
	    	for (i in _song.events[curSection].eventNotes) {
	    		if (i != null)
	    			generateEventSection(i, 0, curSection);
	    	}
	    } else if (_song.events[curSection] == null) {
	    	addEventSection();
	    }
	}

    function generateSection(i:Array<Dynamic>, ?addToSection:Int = 0, currentSection:Int) {
		var section:Int = currentSection + addToSection;

		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus = i[2];
		var noteType:String = "";
		if (i.length > 3)
			noteType = i[3];

		var note:Note = new Note(daStrumTime, daNoteInfo % 4, null, false, noteType);
		note.sustainLength = daSus;
		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.belongsToSection = section;
		note.x = Math.floor(daNoteInfo * GRID_SIZE);

        var sectionStart = sectionStartTime(section);
        var relTime = daStrumTime - sectionStart;

        note.y = Math.floor(getYfromStrum(relTime, sectionBGs.members[addToSection + 1]));

		if (daSus > 0) {
			if (addToSection == 0) {
				curRenderedSustains.add(setupSusNote(note, daSus, false));
			} else {
				ignoreRenderShit.add(setupSusNote(note, daSus, true));
			}
		}

        for (old in oldSelectionData) {
            if (Math.abs(old.time - note.strumTime) < 2 && old.data == daNoteInfo) {
                note.shader = selectShader; 
                if (!selectedNotesGroup.contains(note))
                    selectedNotesGroup.push(note);
            }
        }

		if (addToSection == 0) {
			curRenderedNotes.add(note);
		} else {
			note.alpha = 0.75;
			ignoreRenderShit.add(note);
		}
	}

	function setupSusNote(note:Note, daSus:Float, isNextSection:Bool):FlxSprite {
		var height:Int = Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, (gridBG.height)));
		var minHeight:Int = Std.int((GRID_SIZE / 2) + GRID_SIZE / 2);
		if(height < minHeight) height = minHeight;
		if(height < 1) height = 1;

		var spr:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 4, note.y + GRID_SIZE / 2).makeGraphic(8, height);
		if (isNextSection)
			spr.alpha = 0.75;
		return spr;
	}

	function generateEventSection(i:ChartEvent, ?addToSection:Int = 0, currentSection:Int) {
		var section:Int = currentSection + addToSection;

		var event:Event = new Event(i);
		event.setGraphicSize(GRID_SIZE, GRID_SIZE);
		event.updateHitbox();
		event.x = -40;

        var relTime = i.strumtime - sectionStartTime(section);
        event.y = Math.floor(getYfromStrum(relTime, eventSectionBGs.members[addToSection + 1]));

		if (addToSection == 0) {
			curRenderedEvents.add(event);
		} else {
			event.alpha = 0.75;
			ignoreRenderShit.add(event);
		}
	}

	private function addSection(lengthInSteps:Int = 16):Void
	{
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false
		};

		_song.notes.push(sec);
	}

	private function addEventSection(lengthInSteps:Int = 16):Void
	{
		var sec:EventSection = {
			lengthInSteps: lengthInSteps,
			eventNotes: [],
			typeOfSection: 0
		};

		if (_song.events != null)
			_song.events.push(sec);
		else{
			_song.events = [];
			_song.events.push(sec);
		}
	}

	function selectNote(note:Note):Void
	{
		var swagNum:Int = 0;

		for (i in _song.notes[curSection].sectionNotes)
		{
			if (i.strumTime == note.strumTime && i.noteData % 4 == note.noteData)
			{
				curSelectedNote = _song.notes[curSection].sectionNotes[swagNum];
			}

			swagNum += 1;
		}

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		for (i in _song.notes[curSection].sectionNotes)
		{
			if (i[0] == note.strumTime && i[1] % 4 == note.noteData)
			{
				FlxG.log.add('FOUND EVIL NUMBER');
				_song.notes[curSection].sectionNotes.remove(i);
			}
		}

		updateGrid();
	}

	function clearSection():Void
	{
		_song.notes[curSection].sectionNotes = [];

		updateGrid();
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNote():Void
	{
        var noteStrum = getSnappedStrumTime(dummyArrow.y - gridBG.y) + sectionStartTime();
        var noteData = Math.floor(FlxG.mouse.x / GRID_SIZE);
        var noteSus = 0;
        var noteType = inputNoteType.text;

		_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus, noteType]);

		curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

		if (FlxG.keys.pressed.CONTROL)
		{
			_song.notes[curSection].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, noteType]);
		}

		updateGrid();
		updateNoteUI();

		autosaveSong();
	}

	private function addEvent():Void {
		if (curSelectedEvents.length > 0) {
			var selected = curSelectedEvents[curEditingEventIndex];
			selected.variable1 = eventVar1.text;
			selected.variable2 = eventVar2.text;
		}

		var noteStrum = getSnappedStrumTime(dummyArrow.y - gridBG.y) + sectionStartTime();

		var newEvent:ChartEvent = {
			strumtime: noteStrum,
			event: eventDropDown.selectedLabel,
			variable1: eventVar1.text,
			variable2: eventVar2.text
		};

		_song.events[curSection].eventNotes.push(newEvent);
		curSelectedEvents = _song.events[curSection].eventNotes.filter(function(e) return e.strumtime == noteStrum);
		curEditingEventIndex = curSelectedEvents.length - 1;

		updateGrid();
		autosaveSong();
	}

    function deleteEvent(event:Event):Void
    {
        for (i in _song.events[curSection].eventNotes)
        {
            if (Math.abs(i.strumtime - event.strumTime) < 2 && i.event == event.thisEvent.event)
            {
                _song.events[curSection].eventNotes.remove(i);
                break;
            }
        }
        updateGrid();
    }

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, ?grid:FlxSprite):Float
	{
		if (grid == null)
			grid = gridBG;

		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, grid.y, grid.y + grid.height);
	}

    function getSnappedStrumTime(yPos:Float):Float
    {
        var rawTime:Float = getStrumTime(yPos);
        var snapInterval:Float = (16 * Conductor.stepCrochet) / gridSnap;
        return Math.floor(rawTime / snapInterval) * snapInterval;
    }

	/*
		function calculateSectionLengths(?sec:SwagSection):Int
		{
			var daLength:Int = 0;

			for (i in _song.notes)
			{
				var swagLength = i.lengthInSteps;

				if (i.typeOfSection == Section.COPYCAT)
					swagLength * 2;

				daLength += swagLength;

				if (sec != null && sec == i)
				{
				    Logger.log('swag loop??');
					break;
				}
			}

			return daLength;
	}*/
	private var daSpacing:Float = 0.3;

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void
	{
		PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
		FlxG.resetState();
	}

	function loadAutosave():Void
	{
		PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
		FlxG.resetState();
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	private function saveLevel()
	{
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(openfl.events.Event.COMPLETE, onSaveComplete);
			_file.addEventListener(openfl.events.Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(openfl.events.Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(openfl.events.Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(openfl.events.Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(openfl.events.Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(openfl.events.Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(openfl.events.Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
}
