package substates;

import system.KeyBinds;
import flixel.FlxSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;

using StringTools;

class KeyBindMenu extends FlxSubState {
    var keyLabels:Array<String> = ["LEFT", "DOWN", "UP", "RIGHT"];
    var defaultKeys:Array<String> = ["A", "S", "W", "D"];
    var keys:Array<String> = [];

    var selected:Int = 0;
    var state:String = "select";
    var tempKey:String = "";
    var blacklist:Array<String> = ["ESCAPE", "ENTER", "BACKSPACE", "SPACE", "TAB"];

    var displayText:FlxText;
    var infoText:FlxText;
    var warningText:FlxText;
    var blackBox:FlxSprite;

    override function create() {
        persistentUpdate = true;

        keys = [
            CoolUtil.coalesce(FlxG.save.data.leftBind, defaultKeys[0]),
            CoolUtil.coalesce(FlxG.save.data.downBind, defaultKeys[1]),
            CoolUtil.coalesce(FlxG.save.data.upBind, defaultKeys[2]),
            CoolUtil.coalesce(FlxG.save.data.rightBind, defaultKeys[3])
        ];

        blackBox = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        blackBox.alpha = 0.7;
        add(blackBox);

        displayText = new FlxText(-25, 0, FlxG.width, "", 46);
        displayText.setFormat("VCR OSD Mono", 48, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        displayText.y = (FlxG.height - displayText.height) / 3.5;
        displayText.scrollFactor.set();
        displayText.borderSize = 3;
        displayText.borderQuality = 1;
        add(displayText);

        infoText = new FlxText(0, FlxG.height - 80, FlxG.width, "ESC = Save | BACKSPACE = Reset | ENTER = Change", 16);
        infoText.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        infoText.scrollFactor.set();
        add(infoText);

        warningText = new FlxText(0, FlxG.height - 150, FlxG.width, "", 16);
        warningText.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        warningText.scrollFactor.set();
        warningText.alpha = 0;
        add(warningText);

        updateText();
        super.create();
    }

    override function update(elapsed:Float) {
        switch(state) {
            case "select":
                if (FlxG.keys.justPressed.UP) changeSelection(-1);
                else if (FlxG.keys.justPressed.DOWN) changeSelection(1);
                else if (FlxG.keys.justPressed.ENTER) enterKeyChange();
                else if (FlxG.keys.justPressed.ESCAPE) saveAndExit();
                else if (FlxG.keys.justPressed.BACKSPACE) resetKeys();
            case "waiting":
                if (FlxG.keys.justPressed.ESCAPE) {
                    keys[selected] = tempKey;
                    state = "select";
                    FlxG.sound.play(Paths.sound("confirmMenu"));
                } else if (FlxG.keys.justPressed.ENTER) {
                    applyKey(defaultKeys[selected]);
                    saveAndContinue();
                } else if (FlxG.keys.justPressed.ANY) {
                    applyKey(FlxG.keys.getIsDown()[0].ID.toString());
                    saveAndContinue();
                }
        }
        super.update(elapsed);
    }

    function changeSelection(offset:Int) {
        selected = (selected + offset + 4) % 4;
        FlxG.sound.play(Paths.sound("scrollMenu"));
        updateText();
    }

    function enterKeyChange() {
        tempKey = keys[selected];
        keys[selected] = "?";
        state = "waiting";
        updateText();
    }

    function applyKey(key:String) {
        for (i in 0...keys.length) {
            if (keys[i] == key) keys[i] = defaultKeys[i];
        }
        keys[selected] = key;
        FlxG.sound.play(Paths.sound("scrollMenu"));
        state = "select";
        updateText();
    }

    function updateText() {
        displayText.text = "  Controls:\n\n";
        for (i in 0...keyLabels.length) {
            var prefix = (i == selected ? "> " : "  ");
            displayText.text += prefix + keyLabels[i] + ": " + keys[i] + "\n";
        }
    }

    function saveAndExit() {
        FlxG.save.data.leftBind = keys[0];
        FlxG.save.data.downBind = keys[1];
        FlxG.save.data.upBind = keys[2];
        FlxG.save.data.rightBind = keys[3];
        FlxG.save.flush();
        PlayerSettings.player1.controls.loadKeyBinds();
        close();
    }

    function saveAndContinue() {
        FlxG.save.data.leftBind = keys[0];
        FlxG.save.data.downBind = keys[1];
        FlxG.save.data.upBind = keys[2];
        FlxG.save.data.rightBind = keys[3];
        FlxG.save.flush();
        PlayerSettings.player1.controls.loadKeyBinds();

        state = "select";
        FlxG.sound.play(Paths.sound("confirmMenu"));
    }

    function resetKeys() {
        keys = defaultKeys.copy();
        updateText();
        showWarning("Bindings reset to default.");
    }

    function showWarning(msg:String) {
        warningText.text = msg;
        warningText.alpha = 1;
        FlxTween.cancelTweensOf(warningText);
        FlxTween.tween(warningText, { alpha: 0 }, 3, { ease: FlxEase.quadInOut, startDelay: 0.5 });
    }
}
