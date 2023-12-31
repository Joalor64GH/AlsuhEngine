package;

import Song.SwagSong;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

class Conductor
{
	public static var bpm:Float = 100;
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var songPosition:Float = 0;
	public static var lastSongPos:Float;
	public static var offset:Float = 0;

	public static var safeZoneOffset:Float = (OptionData.safeFrames / 60) * 1000; // is calculated in create(), is safeFrames in milliseconds

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static function getDefaultRatings():Array<Rating>
	{
		var good:Rating = new Rating('good');
		good.ratingMod = 0.7;
		good.score = 200;
		good.noteSplash = false;

		var bad:Rating = new Rating('bad');
		bad.ratingMod = 0.4;
		bad.score = 100;
		bad.noteSplash = false;

		var shit:Rating = new Rating('shit');
		shit.ratingMod = 0;
		shit.score = 50;
		shit.noteSplash = false;

		return [new Rating('sick'), good, bad, shit];
	}

	public static function judgeNote(ratingsData:Array<Rating>, note:Note, diff:Float = 0):Rating
	{
		var data:Array<Rating> = getDefaultRatings();

		if (ratingsData != null && ratingsData.length > 0) {
			data = ratingsData;
		}

		if ((ratingsData == null || ratingsData.length < 1) && PlayState.instance != null) {
			data = PlayState.instance.ratingsData;
		}

		for (i in 0...data.length - 1) // skips last window (Shit)
		{
			if (diff <= data[i].hitWindow) {
				return data[i];
			}
		}

		return data[data.length - 1];
	}

	public static function getRatingByName(ratingsData:Array<Rating>, name:String):Rating
	{
		if (ratingsData.length > 0)
		{
			for (rtg in ratingsData)
			{
				if (rtg != null && rtg.name == name) {
					return rtg;
				}
			}
		}

		return new Rating('sick');
	}

	public static function getCrotchetAtTime(time:Float):Float
	{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepCrochet * 4;
	}

	public static function getBPMFromSeconds(time:Float):BPMChangeEvent
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}

		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (time >= Conductor.bpmChangeMap[i].songTime) {
				lastChange = Conductor.bpmChangeMap[i];
			}
		}

		return lastChange;
	}

	public static function getBPMFromStep(step:Float):BPMChangeEvent
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}

		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.bpmChangeMap[i].stepTime <= step) {
				lastChange = Conductor.bpmChangeMap[i];
			}
		}

		return lastChange;
	}

	public static function beatToSeconds(beat:Float):Float
	{
		var step:Float = beat * 4;
		var lastChange:BPMChangeEvent = getBPMFromStep(step);

		return lastChange.songTime + ((step - lastChange.stepTime) / (lastChange.bpm / 60) / 4) * 1000; // TODO: make less shit and take BPM into account PROPERLY
	}

	public static function getStep(time:Float):Float
	{
		var lastChange:BPMChangeEvent = getBPMFromSeconds(time);
		return lastChange.stepTime + (time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getStepRounded(time:Float):Float
	{
		var lastChange:BPMChangeEvent = getBPMFromSeconds(time);
		return lastChange.stepTime + Math.floor(time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getBeat(time:Float):Float
	{
		return getStep(time) / 4;
	}

	public static function getBeatRounded(time:Float):Int
	{
		return Math.floor(getStepRounded(time) / 4);
	}

	public static function mapBPMChanges(song:SwagSong):Void
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;

		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;

				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: calculateCrochet(curBPM) / 4
				};

				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = Math.round(getSectionBeats(song, i) * 4);
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
	}

	static function getSectionBeats(song:SwagSong, section:Int):Float
	{
		var val:Null<Float> = song.notes[section] != null ? song.notes[section].sectionBeats : null;
		return val != null ? val : 4;
	}

	public static function calculateCrochet(bpm:Float):Float
	{
		return (60 / bpm) * 1000;
	}

	public static function changeBPM(newBpm:Float):Void
	{
		bpm = newBpm;

		crochet = calculateCrochet(bpm);
		stepCrochet = crochet / 4;
	}
}

class Rating
{
	public var name:String = '';
	public var defaultName:String = '';

	public var image:String = '';
	public var counter:String = '';

	public var hitWindow(get, null):Null<Int> = 0; //ms
	public var ratingMod:Float = 1;

	public var score:Int = 350;

	public var noteSplash:Bool = true;

	public function new(name:String):Void
	{
		this.name = name;
		this.defaultName = this.name;

		this.image = name;
		this.counter = defaultName + 's';

		if (hitWindow == null) {
			hitWindow = 0;
		}
	}

	public function get_hitWindow():Null<Int>
	{
		return Reflect.getProperty(OptionData, defaultName + 'Window');
	}

	public function increase(blah:Int = 1):Void
	{
		Reflect.setProperty(PlayState.instance, counter, Reflect.getProperty(PlayState.instance, counter) + blah);
	}
}