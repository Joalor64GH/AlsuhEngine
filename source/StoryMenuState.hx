package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import MenuCharacter;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	private static var curSelected:Int = 0;
	private static var lastDifficultyName:String = '';

	private var curDifficulty:Int = -1;

	private var weeksArray:Array<WeekData> = [];
	private var curWeek:WeekData;

	var bgYellow:FlxSprite;
	var bgSprite:FlxSprite;

	var grpWeeks:FlxTypedGroup<MenuItem>;
	var grpLocks:FlxTypedGroup<FlxSprite>;

	var txtTracklist:FlxText;
	var txtWeekTitle:FlxText;
	var scoreText:FlxText;

	var sprDifficulty:FlxSprite;

	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	public override function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		super.create();

		PlayState.gameMode = 'story';
		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Story Menu", null); // Updating Discord Rich Presence
		#end

		persistentUpdate = persistentDraw = true;

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0) {
				FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
			}
		}

		Conductor.changeBPM(102);

		grpWeeks = new FlxTypedGroup<MenuItem>();
		add(grpWeeks);

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		var blackBarThingie:FlxSprite = new FlxSprite();
		blackBarThingie.makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		bgYellow = new FlxSprite(0, 56);
		bgYellow.makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		add(bgYellow);

		bgSprite = new FlxSprite(0, 56);
		bgSprite.antialiasing = OptionData.globalAntialiasing;
		add(bgSprite);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		add(grpWeekCharacters);

		var pathy:String = 'storymenu/campaign_menu_UI_assets';

		if (Paths.fileExists('images/campaign_menu_UI_assets.png', IMAGE)) {
			pathy = 'campaign_menu_UI_assets';
		}

		var ui_tex:FlxAtlasFrames = Paths.getSparrowAtlas(pathy);
		var num:Int = 0;

		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = WeekData.weekIsLocked(WeekData.weeksList[i]);

			if (!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				weeksArray.push(weekFile);

				WeekData.setDirectoryFromWeek(weekFile);
	
				var leWeek:WeekData = weeksArray[i];

				var weekThing:MenuItem = new MenuItem(0, bgYellow.y + 396, leWeek.itemFile);
				weekThing.y += ((weekThing.height + 20) * num);
				weekThing.targetY = num;
				weekThing.screenCenter(X);
				weekThing.antialiasing = OptionData.globalAntialiasing;
				grpWeeks.add(weekThing);

				var col:Array<Int> = leWeek.itemColor.copy();
				weekThing.itemColor = FlxColor.fromRGB(col[0], col[1], col[2]);

				if (isLocked)
				{
					var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
					lock.frames = ui_tex;
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.ID = i;
					lock.antialiasing = OptionData.globalAntialiasing;
					grpLocks.add(lock);
				}

				num++;
			}
		}

		if (curSelected >= weeksArray.length) curSelected = 0;

		WeekData.setDirectoryFromWeek(weeksArray[0]);

		var charArray:Array<String> = weeksArray[0].weekCharacters;

		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		leftArrow = new FlxSprite(872, 462);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left", 24, false);
		leftArrow.animation.addByPrefix('press', "arrow push left", 24, false);
		leftArrow.animation.play('idle');
		leftArrow.antialiasing = OptionData.globalAntialiasing;
		add(leftArrow);

		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = OptionData.globalAntialiasing;
		add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right', 24, false);
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.antialiasing = OptionData.globalAntialiasing;
		add(rightArrow);

		var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.07, bgYellow.y + 425);

		if (Paths.fileExists('images/Menu_Tracks.png', IMAGE)) {
			tracksSprite.loadGraphic(Paths.getImage('Menu_Tracks'));
		}
		else {
			tracksSprite.loadGraphic(Paths.getImage('storymenu/Menu_Tracks'));
		}

		tracksSprite.antialiasing = OptionData.globalAntialiasing;
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, '', 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = Paths.getFont('vcr.ttf');
		txtTracklist.color = 0xFFE55777;
		add(txtTracklist);

		scoreText = new FlxText(10, 10, 0, '', 36);
		scoreText.setFormat(Paths.getFont('vcr.ttf'), 32);
		add(scoreText);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, '', 32);
		txtWeekTitle.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;
		add(txtWeekTitle);

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height);
		textBG.makeGraphic(FlxG.width, 26, FlxColor.BLACK);
		textBG.alpha = 0.6;
		add(textBG);

		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, "Press CTRL to open the Gameplay Changers Menu | Press RESET to Reset your Score.", 18);
		text.setFormat(Paths.getFont('vcr.ttf'), 18, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		FlxTween.tween(textBG, {y: FlxG.height - 26}, 2, {ease: FlxEase.circOut});
		FlxTween.tween(text, {y: FlxG.height - 26 + 4}, 2, {ease: FlxEase.circOut});

		curWeek = weeksArray[curSelected];

		CoolUtil.loadDifficultiesFromLevel(curWeek);

		if (lastDifficultyName == '') {
			lastDifficultyName = curWeek.defaultDifficulty;
		}

		curDifficulty = Math.round(Math.max(0, CoolUtil.getDifficultyIndex(lastDifficultyName)));

		changeSelection();
		changeDifficulty();
	}

	var lerpScore:Float = 0;
	var intendedScore:Int = 0;

	var selectedWeek:Bool = false;

	var holdTime:Float = 0;
	var holdTimeHos:Float = 0;

	public override function update(elapsed:Float):Void
	{
		if (FlxG.sound.music != null) {
			Conductor.songPosition = FlxG.sound.music.time;
		}

		lerpScore = FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1));
		scoreText.text = "WEEK SCORE:" + Math.round(lerpScore);

		var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

		if (!selectedWeek)
		{
			if (controls.BACK || FlxG.mouse.justPressedRight)
			{
				FlxG.sound.play(Paths.getSound('cancelMenu'));
				FlxG.switchState(new MainMenuState());
			}

			if (weeksArray.length > 1)
			{
				if (controls.UI_UP_P)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'));
					changeSelection(-shiftMult);

					holdTime = 0;
				}

				if (controls.UI_DOWN_P)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'));
					changeSelection(shiftMult);

					holdTime = 0;
				}
	
				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
	
					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						FlxG.sound.play(Paths.getSound('scrollMenu'));
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
	
				if (FlxG.mouse.wheel != 0 && !FlxG.keys.pressed.ALT)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'));
					changeSelection(-shiftMult * FlxG.mouse.wheel);
				}
			}

			var diffUnlocked:Bool = CoolUtil.difficultyStuff.length > 1 && !WeekData.weekIsLocked(curWeek.weekID);

			leftArrow.visible = diffUnlocked;
			rightArrow.visible = diffUnlocked;

			if (diffUnlocked)
			{
				if (controls.UI_LEFT_P)
				{
					leftArrow.animation.play('press');

					changeDifficulty(-1);
					holdTimeHos = 0;
				}
				else if (controls.UI_LEFT_R) leftArrow.animation.play('idle');

				if (controls.UI_RIGHT_P)
				{
					rightArrow.animation.play('press');

					changeDifficulty(1);
					holdTimeHos = 0;
				}
				else if (controls.UI_RIGHT_R) rightArrow.animation.play('idle');

				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					var checkLastHold:Int = Math.floor((holdTimeHos - 0.5) * 10);
					holdTimeHos += elapsed;
					var checkNewHold:Int = Math.floor((holdTimeHos - 0.5) * 10);
	
					if (holdTimeHos > 0.5 && checkNewHold - checkLastHold > 0) {
						changeDifficulty((checkNewHold - checkLastHold) * (controls.UI_LEFT ? -1 : 1));
					}
				}

				if (FlxG.mouse.wheel != 0 && FlxG.keys.pressed.ALT) {
					changeDifficulty(-1 * FlxG.mouse.wheel);
				}
			}

			if (FlxG.keys.justPressed.CONTROL)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubState());
			}
			else if (controls.RESET)
			{
				persistentUpdate = false;

				openSubState(new ResetScoreSubState('story', curWeek.weekName, curWeek.weekID, CoolUtil.difficultyStuff[curDifficulty][1], lastDifficultyName));
			}
			else if (controls.ACCEPT || FlxG.mouse.justPressed)
			{
				var songID:String = curWeek.songs[0].songID;
				var ourPath:String = songID + CoolUtil.difficultyStuff[curDifficulty][2];

				if (!WeekData.weekIsLocked(curWeek.weekID))
				{
					if (Paths.fileExists('data/' + songID + '/' + ourPath + '.json', TEXT))
					{
						try
						{
							selectedWeek = true;

							if (grpWeekCharacters.length > 0)
							{
								for (i in 0...grpWeekCharacters.length)
								{
									var char:MenuCharacter = grpWeekCharacters.members[i];

									if (char.character != '' && char.hasConfirmAnimation) {
										char.hey();
									}
								}
							}

							grpWeeks.members[curSelected].startFlashing();

							PlayState.SONG = Song.loadFromJson(ourPath, songID);
							PlayState.firstSong = songID;

							var songArray:Array<String> = [];

							for (i in 0...curWeek.songs.length) {
								songArray.push(curWeek.songs[i].songID);
							}

							PlayState.storyPlaylist = songArray;
							PlayState.weekLength = songArray.length;
							PlayState.storyWeekID = curWeek.weekID;
							PlayState.storyWeekName = curWeek.weekName;

							PlayState.campaignScore = 0;
							PlayState.campaignMisses = 0;
							PlayState.campaignAccuracy = 0;

							PlayState.seenCutscene = false;

							FlxG.sound.play(Paths.getSound('confirmMenu'));

							Debug.logInfo('Loading song "${PlayState.SONG.songName}" and week "${PlayState.storyWeekName}" into Story...');

							new FlxTimer().start(1, function(tmr:FlxTimer):Void
							{
								LoadingState.loadAndSwitchState(new PlayState(), true);

								if (!OptionData.loadingScreen) {
									FreeplayMenuState.destroyFreeplayVocals();
								}

								persistentUpdate = true;
							});
						}
						catch (e:Dynamic) {
							Debug.logError('Error on loading file "' + songID + '/' + ourPath + '.json' + '": ' + e);
						}
					}
					else {
						Debug.logError('File "' + songID + '/' + ourPath + '.json' + '" does not exist!');
					}
				}
				else
				{
					/*if (FlxG.random.bool(0.00001)) { // never gonna give you up never gonna let you down
						CoolUtil.browserLoad('https://youtu.be/dQw4w9WgXcQ'); // lololololololol
					}
					else {*/
						FlxG.sound.play(Paths.getSound('cancelMenu'));
					//}
				}
			}
		}

		super.update(elapsed);

		grpLocks.forEach(function(lock:FlxSprite):Void
		{
			lock.y = grpWeeks.members[lock.ID].y;
			lock.visible = (lock.y > FlxG.height / 2);
		});
	}

	public override function closeSubState():Void
	{
		super.closeSubState();

		#if !switch
		intendedScore = Highscore.getWeekScore(CoolUtil.formatSong(curWeek.weekID, lastDifficultyName));
		#end
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = CoolUtil.boundSelection(curSelected + change, weeksArray.length);

		curWeek = weeksArray[curSelected];

		WeekData.setDirectoryFromWeek(curWeek);
		PlayState.storyWeekID = curWeek.weekID;

		var unlocked:Bool = !WeekData.weekIsLocked(curWeek.weekID);
		var bullShit:Int = 0;

		for (item in grpWeeks.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0 && unlocked) {
				item.alpha = 1;
			}
		}

		updateText();

		CoolUtil.loadDifficultiesFromLevel(curWeek);

		if (CoolUtil.difficultyExists(curWeek.defaultDifficulty)) {
			curDifficulty = Math.round(Math.max(0, CoolUtil.getDifficultyIndex(curWeek.defaultDifficulty)));
		}
		else {
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.getDifficultyIndex(lastDifficultyName);

		if (newPos > -1) {
			curDifficulty = newPos;
		}

		changeDifficulty();
	}

	var tweenDifficulty:FlxTween;

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty = CoolUtil.boundSelection(curDifficulty + change, CoolUtil.difficultyStuff.length);

		WeekData.setDirectoryFromWeek(curWeek);

		var diff:String = CoolUtil.difficultyStuff[curDifficulty][0];
		var diffPath:String = 'storymenu/menudifficulties/' + diff;

		if (Paths.fileExists('images/menudifficulties/' + diff + '.png', IMAGE)) {
			diffPath = 'menudifficulties/' + diff;
		}

		var newImage:FlxGraphic = Paths.getImage(diffPath);

		if (sprDifficulty.graphic != newImage)
		{
			sprDifficulty.loadGraphic(newImage);
			sprDifficulty.x = leftArrow.x + 60;
			sprDifficulty.x += (308 - sprDifficulty.width) / 2;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - 15;

			if (tweenDifficulty != null) tweenDifficulty.cancel();

			tweenDifficulty = FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07,
			{
				onComplete: function(twn:FlxTween) {
					tweenDifficulty = null;
				}
			});
		}

		lastDifficultyName = diff;

		PlayState.lastDifficulty = curDifficulty;
		PlayState.storyDifficulty = curDifficulty;

		#if !switch
		intendedScore = Highscore.getWeekScore(CoolUtil.formatSong(curWeek.weekID, lastDifficultyName));
		#end
	}

	function updateText():Void
	{
		if (grpWeekCharacters.length > 0)
		{
			for (i in 0...grpWeekCharacters.length) {
				grpWeekCharacters.members[i].changeCharacter(curWeek.weekCharacters[i]);
			}
		}

		var leName:String = curWeek.storyName;

		txtWeekTitle.text = leName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		txtTracklist.text = '';

		var stringThing:Array<String> = [];

		for (i in 0...curWeek.songs.length) {
			stringThing.push(curWeek.songs[i].songName);
		}

		for (i in 0...stringThing.length) {
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		bgSprite.visible = true;

		var assetName:String = curWeek.weekBackground;

		if (assetName == null || assetName.length < 1) {
			bgSprite.visible = false;
		}
		else
		{
			if (Paths.fileExists('images/menubackgrounds/menu_' + assetName + '.png', IMAGE)) {
				bgSprite.loadGraphic(Paths.getImage('menubackgrounds/menu_' + assetName));
			}
			else if (Paths.fileExists('images/storymenu/menubackgrounds/menu_' + assetName + '.png', IMAGE)) {
				bgSprite.loadGraphic(Paths.getImage('storymenu/menubackgrounds/menu_' + assetName));
			}
			else {
				bgSprite.visible = false;
			}
		}
	}

	public override function beatHit():Void
	{
		super.beatHit();

		if (grpWeekCharacters.length > 0)
		{
			for (i in 0...grpWeekCharacters.length)
			{
				var leChar:MenuCharacter = grpWeekCharacters.members[i];

				if (leChar.isDanced && !leChar.heyed) {
					leChar.dance();
				}
				else
				{
					if (curBeat % OptionData.danceOffset == 0 && !leChar.heyed) {
						leChar.dance();
					}
				}
			}
		}
	}
}