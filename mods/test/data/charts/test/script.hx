function createPost() {
    this.camHUD.alpha = 0;
}

function noteMiss(note) {
    this.camHUD.shake(0.009,0.2);
}

function goodNoteHit(note) {
    if (!note.isSustainNote) {
        if (FlxG.save.data.downscroll) {
            this.playerStrums.members[Math.round(Math.abs(note.noteData))].y += 20;
        } else {
            this.playerStrums.members[Math.round(Math.abs(note.noteData))].y -= 20;  
        }
    }
}

function dadNoteHit(daNote) {
    if (!daNote.isSustainNote) {
        if (FlxG.save.data.downscroll) {
            this.dadStrums.members[Math.round(Math.abs(daNote.noteData))].y += 20;
        } else {
            this.dadStrums.members[Math.round(Math.abs(daNote.noteData))].y -= 20;  
        }
    }
}

function update(elapsed) {
    for (i in 0...this.playerStrums.members.length) {
        if (Config.downScroll) {
            this.playerStrums.members[i].y = FlxMath.lerp(FlxG.height - 160, this.playerStrums.members[i].y, FlxMath.bound(1 - (elapsed * 6), 0 , 1));
        } else {
            this.playerStrums.members[i].y = FlxMath.lerp(70, this.playerStrums.members[i].y, FlxMath.bound(1 - (elapsed * 6), 0 , 1));
        }
    }

    for (i in 0...this.dadStrums.members.length) {
        if (Config.downScroll) {
            this.dadStrums.members[i].y = FlxMath.lerp(FlxG.height - 160, this.dadStrums.members[i].y, FlxMath.bound(1 - (elapsed * 6), 0 , 1));
        } else {
            this.dadStrums.members[i].y = FlxMath.lerp(70, this.dadStrums.members[i].y, FlxMath.bound(1 - (elapsed * 6), 0 , 1));
        }
    }
}

function stepHit(curStep) {
    switch (curStep){
        case 632:
            this.defaultCamZoom += 0.2;
        case 636:
            this.defaultCamZoom += 0.4;
        case 640:
            this.defaultCamZoom -= 0.6;
    }
}

function beatHit(curBeat) {
    if (curBeat == 32){
        FlxTween.tween(this.camHUD, {alpha: 1}, 1, {ease: FlxEase.linear});
    }

    if (Config.camZooms && curBeat > 96 && curBeat <= 112){
        FlxG.camera.zoom += 0.020;
        this.camHUD.zoom += 0.01;
    }

    if (curBeat % 4 == 0 && curBeat >= 64 && curBeat <= 128) {
        FlxTween.tween(this.camHUD, {zoom: 1.05}, 0.12, {
            ease: FlxEase.sineInOut,
            onComplete: function(_) {
                FlxTween.tween(this.camHUD, {zoom: 0.98}, 0.12, {
                    ease: FlxEase.sineInOut,
                    onComplete: function(_) {
                        FlxTween.tween(this.camHUD, {zoom: 1}, 0.08, {ease: FlxEase.sineInOut});
                    }
                });
            }
        });
    }

    switch (curBeat){
        case 64:
            this.camHUD.flash(0xffffffff, 1);
        case 72:
            this.camHUD.flash(0xffffffff, 1);
        case 112, 114, 116:
            this.defaultCamZoom += 0.2;
        case 119:
            this.defaultCamZoom -= 0.6;
        case 120, 122, 124:
            this.defaultCamZoom += 0.2;
        case 127:
            this.defaultCamZoom -= 0.6;
    }

	this.dad.dance();
}
