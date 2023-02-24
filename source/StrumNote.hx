package;

import flixel.FlxG;
import flixel.FlxSprite;
import shaderslmfao.ColorSwap;
import flixel.graphics.FlxGraphic;

using StringTools;

class StrumNote extends FlxSprite
{
	public var colorSwap:ColorSwap;

	public var noteData:Int = 0;
	public var resetAnim:Float = 0;

	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;

	public var player:Int;

	public function new(x:Float, y:Float, leData:Int, player:Int):Void
	{
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		this.player = player;
		this.noteData = leData;

		super(x, y);

		var skin:String = 'NOTE_assets';

		if (player == 1)
		{
			if (PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) {
				skin = PlayState.SONG.arrowSkin;
			}
		}
		else
		{
			if (PlayState.SONG.arrowSkin2 != null && PlayState.SONG.arrowSkin2.length > 1) {
				skin = PlayState.SONG.arrowSkin2;
			}
		}

		if (PlayState.isPixelStage)
		{
			var ourGraphic:FlxGraphic = Paths.getImage('notes/' + skin);

			if (Paths.fileExists('images/' + skin + '.png', IMAGE)) {
				ourGraphic = Paths.getImage(skin);
			}
			else if (Paths.fileExists('images/pixelUI/' + skin + '.png', IMAGE)) {
				ourGraphic = Paths.getImage('pixelUI/' + skin);
			}
			else if (Paths.fileExists('images/notes/pixel/' + skin + '.png', IMAGE)) {
				ourGraphic = Paths.getImage('notes/pixel/' + skin);
			}

			loadGraphic(ourGraphic);

			width = width / Note.maxNote;
			height = height / 5;

			loadGraphic(ourGraphic, true, Math.floor(width), Math.floor(height));
			loadPixelNoteAnims();

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
		}
		else
		{
			if (Paths.fileExists('images/' + skin + '.png', IMAGE)) {
				frames = Paths.getSparrowAtlas(skin);
			}
			else {
				frames = Paths.getSparrowAtlas('notes/' + skin);
			}

			loadNoteAnims();

			antialiasing = OptionData.globalAntialiasing;
			setGraphicSize(Std.int(width * 0.7));
		}

		updateHitbox();
		scrollFactor.set();
	}

	function loadNoteAnims():Void
	{
		var vanillaInt:Array<Int> = [1, 2, 4, 3];

		var vanillaShit:String = ' static instance ' + vanillaInt[noteData];
		var shitMyPants:String = 'arrow' + vanillaShit + '0000';
		var vanillaAllowed:Bool = frames.getByName(shitMyPants) != null;

		var pointers:Array<String> = Note.pointers.copy();

		if (vanillaAllowed) {
			pointers[noteData] = vanillaShit;
		}

		animation.addByPrefix(Note.colArray[noteData], 'arrow' + pointers[noteData]);
		animation.addByPrefix('static', 'arrow' + pointers[noteData]);

		var lowCol:String = Note.pointers[noteData].toLowerCase();
		animation.addByPrefix('pressed', lowCol + ' press', 24, false);
		animation.addByPrefix('confirm', lowCol + ' confirm', 24, false);
	}

	function loadPixelNoteAnims():Void
	{
		var pixelInt:Int = Note.pixelInt[noteData];
		animation.add(Note.colArray[noteData], [pixelInt + Note.maxNote]);

		animation.add('static', [pixelInt]);
		animation.add('pressed', [pixelInt + Note.maxNote, pixelInt + (Note.maxNote * 2)], 12, false);
		animation.add('confirm', [pixelInt + (Note.maxNote * 3), pixelInt + (Note.maxNote * 4)], 24, false);
	}

	public function postAddedToGroup():Void
	{
		playAnim('static');

		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);

		ID = noteData;
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (resetAnim > 0)
		{
			resetAnim -= elapsed;

			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}

		if (animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
			centerOrigin();
		}
	}

	public function playAnim(anim:String, ?force:Bool = false, ?finishCallback:Null<(name:String)->Void>):Void
	{
		animation.play(anim, force);

		if (finishCallback != null) {
			animation.finishCallback = finishCallback;
		}

		centerOffsets();
		centerOrigin();

		if (animation.curAnim == null || animation.curAnim.name == 'static') 
		{
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		}
		else
		{
			if (noteData > -1 && noteData < OptionData.arrowHSV.length)
			{
				colorSwap.hue = OptionData.arrowHSV[noteData][0] / 360;
				colorSwap.saturation = OptionData.arrowHSV[noteData][1] / 100;
				colorSwap.brightness = OptionData.arrowHSV[noteData][2] / 100;
			}

			if (animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
				centerOrigin();
			}
		}
	}

	function updateConfirmOffset():Void // TO DO: Find a calc to make the offset work fine on other angles
	{
		centerOffsets();

		offset.x -= 13;
		offset.y -= 13;
	}
}