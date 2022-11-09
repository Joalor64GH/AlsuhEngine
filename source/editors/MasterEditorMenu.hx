package editors;

#if desktop
import Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;

using StringTools;

class MasterEditorMenu extends TransitionableState
{
	private var curSelected:Int = 0;
	private var curDirectory:Int = 0;

	private var editorsArray:Array<String> =
	[
		'Week Editor',
		'Menu Character Editor',
		'Dialogue Editor',
		'Dialogue Portrait Editor',
		'Character Editor',
		// 'Stage Editor', Alan is here, we need your pull request with stage editor for StageSpriteData.hx.
		'Chart Editor',
	];
	private var directories:Array<String> = [null];

	private var grpEditors:FlxTypedGroup<Alphabet>;
	private var directoryTxt:FlxText;

	public override function create():Void
	{
		super.create();

		FlxG.camera.bgColor = FlxColor.BLACK;

		if (FlxG.sound.music.playing == false || FlxG.sound.music.volume == 0) {
			FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
		}

		FlxG.mouse.visible = false;

		#if desktop
		DiscordClient.changePresence("In the Editors Menu", null); // Updating Discord Rich Presence
		#end

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.getImage('bg/menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		grpEditors = new FlxTypedGroup<Alphabet>();
		add(grpEditors);

		for (i in 0...editorsArray.length)
		{
			var editorText:Alphabet = new Alphabet(0, (70 * i) + 30, editorsArray[i], true);
			editorText.isMenuItem = true;
			editorText.targetY = i;
			grpEditors.add(editorText);
		}

		#if MODS_ALLOWED
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42);
		textBG.makeGraphic(FlxG.width, 42, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		directoryTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, '', 32);
		directoryTxt.setFormat(Paths.getFont("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		directoryTxt.scrollFactor.set();
		add(directoryTxt);
		
		for (folder in Paths.getModDirectories())
		{
			directories.push(folder);
		}

		var found:Int = directories.indexOf(Paths.currentModDirectory);
		if (found > -1) curDirectory = found;

		changeDirectory();
		#end

		changeSelection();
	}

	var holdTime:Float = 0;
	var holdTimeMod:Float = 0;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.getSound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}

		#if MODS_ALLOWED
		if (directories.length > 1)
		{
			if (controls.UI_LEFT_P)
			{
				changeDirectory(-1);

				holdTimeMod = 0;
			}

			if (controls.UI_RIGHT_P)
			{
				changeDirectory(1);

				holdTimeMod = 0;
			}

			if (controls.UI_LEFT || controls.UI_RIGHT)
			{
				var checkLastHold:Int = Math.floor((holdTimeMod - 0.5) * 10);
				holdTimeMod += elapsed;
				var checkNewHold:Int = Math.floor((holdTimeMod - 0.5) * 10);

				if (holdTimeMod > 0.5 && checkNewHold - checkLastHold > 0) {
					changeDirectory((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
				}
			}
		}
		#end

		if (editorsArray.length > 1)
		{
			if (controls.UI_UP_P)
			{
				changeSelection(-1);

				holdTime = 0;
			}

			if (controls.UI_DOWN_P)
			{
				changeSelection(1);

				holdTime = 0;
			}

			if (controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
				}
			}

			if (FlxG.mouse.wheel != 0)
			{
				changeSelection(-1 * FlxG.mouse.wheel);
			}
		}

		if (controls.ACCEPT || FlxG.mouse.justPressed) {
			goToState(editorsArray[curSelected]);
		}
	}

	function goToState(label:String):Void
	{
		switch (label)
		{
			case 'Week Editor':
			{
				if (!OptionData.loadingScreen) {
					FreeplayMenuState.destroyFreeplayVocals();
				}

				FlxG.switchState(new WeekEditorState());
			}
			case 'Menu Character Editor':
			{
				if (!OptionData.loadingScreen) {
					FreeplayMenuState.destroyFreeplayVocals();
				}

				FlxG.switchState(new MenuCharacterEditorState());
			}
			case 'Character Editor':
			{
				LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false), true);
				return;
			}
			case 'Dialogue Editor':
			{
				LoadingState.loadAndSwitchState(new DialogueEditorState(), true);
				return;
			}
			case 'Dialogue Portrait Editor':
			{
				LoadingState.loadAndSwitchState(new DialogueCharacterEditorState(), true);
				return;
			}
			case 'Stage Editor': // Alan is here, we need your pull request with stage editor for StageSpriteData.hx.
			{
				LoadingState.loadAndSwitchState(new StageEditorState(), true);
				return;
			}
			case 'Chart Editor':
			{
				PlayState.SONG = Song.loadFromJson('test', 'test');
				LoadingState.loadAndSwitchState(new ChartingState(), true);

				return;
			}
		}

		if (!OptionData.loadingScreen)
		{
			FlxG.sound.music.volume = 0;

			FreeplayMenuState.destroyFreeplayVocals();
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = editorsArray.length - 1;
		if (curSelected >= editorsArray.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpEditors.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}

		FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
	}

	#if MODS_ALLOWED
	function changeDirectory(change:Int = 0):Void
	{
		curDirectory += change;

		if (curDirectory < 0)
			curDirectory = directories.length - 1;
		if (curDirectory >= directories.length)
			curDirectory = 0;
	
		WeekData.setDirectoryFromWeek();

		if (directories[curDirectory] == null || directories[curDirectory].length < 1)
		{
			directoryTxt.text = '< No Mod Directory Loaded >';
		}
		else
		{
			Paths.currentModDirectory = directories[curDirectory];
			directoryTxt.text = '< Loaded Mod Directory: ' + Paths.currentModDirectory + ' >';
		}

		directoryTxt.text = directoryTxt.text.toUpperCase();

		FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
	}
	#end
}