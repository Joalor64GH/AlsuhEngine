package;

#if MODS_ALLOWED
import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
#end

import haxe.Json;
import Type.ValueType;

import flixel.util.FlxColor;

using StringTools;

typedef WeekFile =
{
	var weekID:Null<String>;
	var weekName:String;

	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;

	var songs:Array<Dynamic>;

	var difficulties:Dynamic;
	var defaultDifficulty:String;

	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var itemFile:Null<String>;

	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var itemColor:Array<Int>;
}

typedef SongLabel =
{
	var songID:String;
	var songName:String;

	var character:String;
	var color:Array<Int>;

	var difficulties:Dynamic;
	var defaultDifficulty:String;
}

class WeekData
{
	public static var weeksList:Array<String> = [];

	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	public var folder:String = '';

	public var weekID:String;
	public var weekName:String;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var songs:Array<Dynamic>;
	public var difficulties:Dynamic;
	public var defaultDifficulty:String;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var itemFile:String;
	public var storyName:String;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var itemColor:Array<Int>;

	public var fileName:String;

	public function new(weekFile:WeekFile, fileName:String):Void
	{
		onLoadJson(weekFile, fileName);

		weekID = weekFile.weekID;
		weekName = weekFile.weekName;
		startUnlocked = weekFile.startUnlocked;
		hiddenUntilUnlocked = weekFile.hiddenUntilUnlocked;
		songs = weekFile.songs;
		difficulties = weekFile.difficulties;
		defaultDifficulty = weekFile.defaultDifficulty;
		weekCharacters = weekFile.weekCharacters;
		weekBackground = weekFile.weekBackground;
		weekBefore = weekFile.weekBefore;
		itemFile = weekFile.itemFile;
		storyName = weekFile.storyName;
		hideStoryMode = weekFile.hideStoryMode;
		hideFreeplay = weekFile.hideFreeplay;
		itemColor = weekFile.itemColor;

		this.fileName = fileName;
	}

	public static function onLoadJson(weekFile:WeekFile, fileName:String) {
		if(weekFile.weekID == null) {
			weekFile.weekID = fileName;
		}
		if(weekFile.itemFile == null) {
			weekFile.itemFile = fileName;
		}
		if(weekFile.itemColor == null || weekFile.itemColor.length < 2) {
			var col:FlxColor = MenuItem.DEFAULT_COLOR;
			weekFile.itemColor = [col.red, col.green, col.blue];
		}
		if(weekFile.defaultDifficulty == null || weekFile.defaultDifficulty.length < 1) {
			weekFile.defaultDifficulty = Paths.formatToSongPath(CoolUtil.defaultDifficulty);
		}
		var newSongs:Array<Dynamic> = [];
		var targetBool:Array<Bool> = [];
		for(i in 0...weekFile.songs.length) {
			var oldSongOrNot:Dynamic = weekFile.songs[i];
			targetBool[i] = false;
			if(Std.isOfType(oldSongOrNot, Array)) {
				targetBool[i] = true;
				var newSong:SongLabel = {
					songID: 'bopeebo',
					songName: 'Bopeebo',
					character: 'dad',
					color: [146, 113, 253],
					difficulties: [],
					defaultDifficulty: ''
				};
				newSong.songID = Paths.formatToSongPath(oldSongOrNot[0]);
				newSong.songName = CoolUtil.formatToName(oldSongOrNot[0]);
				newSong.character = oldSongOrNot[1];
				newSong.color = oldSongOrNot[2];
				var shit:Dynamic = weekFile.difficulties; // fucking HTML5
				if(Std.isOfType(shit,Array)){
					var arr:Array<Dynamic> = shit;
					newSong.difficulties = arr.copy();
				} else {
					newSong.difficulties = shit;
				}
				newSong.defaultDifficulty = weekFile.defaultDifficulty;
				newSongs[i] = newSong;
			} else {
				var song:SongLabel = weekFile.songs[i];
				if(song.difficulties == null || song.difficulties.length < 1) {
					var shit:Array<Dynamic> = weekFile.difficulties; // fucking HTML5
					song.difficulties = shit.copy();
				}
				if(song.defaultDifficulty == null || song.defaultDifficulty.length < 1) {
					song.defaultDifficulty = weekFile.defaultDifficulty;
				}
			}
		}
		for(i in 0...targetBool.length) {
			if(targetBool[i] == true) {
				weekFile.songs[i] = newSongs[i];
			}
		}
	}

	public static function createWeekFile():WeekFile
	{
		return {
			itemColor: [],
			songs: [
				{
					songID: 'bopeebo',
					songName: 'Bopeebo',
					character: 'dad',
					color: [146, 113, 253],
					difficulties: [],
					defaultDifficulty: ''
				},
				{
					songID: 'fresh',
					songName: 'Fresh',
					character: 'dad',
					color: [146, 113, 253],
					difficulties: [],
					defaultDifficulty: ''
				},
				{
					songID: 'dad-battle',
					songName: 'Dad Battle',
					character: 'dad',
					color: [146, 113, 253],
					difficulties: [],
					defaultDifficulty: ''
				}
			],
			weekCharacters: ['dad', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			itemFile: 'week1',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			weekID: 'custom-week',
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: [],
			defaultDifficulty: ''
		};
	}

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false):Void
	{
		weeksList = [];
		weeksLoaded.clear();

		#if MODS_ALLOWED
		var disabledMods:Array<String> = [];
		var modsListPath:String = 'modsList.txt';
		var directories:Array<String> = [Paths.mods(), Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
	
		if (FileSystem.exists(modsListPath))
		{
			var stuff:Array<String> = CoolUtil.coolTextFile(modsListPath, false, true);
	
			for (i in 0...stuff.length)
			{
				var splitName:Array<String> = stuff[i].trim().split('|');
		
				if (splitName[1] == '0') { // Disable mod
					disabledMods.push(splitName[0]);
				}
				else // Sort mod loading order based on modsList.txt file
				{
					var path:String = Path.join([Paths.mods(), splitName[0]]);

					if (FileSystem.isDirectory(path) && !Paths.ignoreModFolders.contains(splitName[0]) && !disabledMods.contains(splitName[0]) && !directories.contains(path + '/')) {
						directories.push(path + '/');
					}
				}
			}
		}

		var modsDirectories:Array<String> = Paths.getModDirectories();
	
		for (folder in modsDirectories)
		{
			var pathThing:String = Path.join([Paths.mods(), folder]) + '/';
		
			if (!disabledMods.contains(folder) && !directories.contains(pathThing)) {
				directories.push(pathThing);
			}
		}
		#else
		var directories:Array<String> = [Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
		#end

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('weeks/weekList.txt'), true, true);
	
		for (i in 0...sexList.length) 
		{
			for (j in 0...directories.length)
			{
				var fileToCheck:String = directories[j] + 'weeks/' + sexList[i] + '.json';
			
				if (!weeksLoaded.exists(sexList[i]))
				{
					var week:WeekFile = getWeekFile(fileToCheck, true);
				
					if (week != null)
					{
						var weekFile:WeekData = new WeekData(week, sexList[i]);

						#if MODS_ALLOWED
						if (j >= originalLength) {
							weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length - 1);
						}
						#end

						if (weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay)))
						{
							weeksLoaded.set(sexList[i], weekFile);
							weeksList.push(sexList[i]);
						}
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) 
		{
			var directory:String = directories[i] + 'weeks/';

			if (FileSystem.exists(directory))
			{
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt', true, true);

				if (listOfWeeks.length > 0)
				{
					for (daWeek in listOfWeeks)
					{
						var path:String = directory + daWeek + '.json';

						if (FileSystem.exists(path)) {
							addWeek(daWeek, path, directories[i], i, originalLength);
						}
					}
				}

				for (file in FileSystem.readDirectory(directory))
				{
					var path:String = Path.join([directory, file]);

					if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
						addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength);
					}
				}
			}
		}
		#end
	}

	private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int):Void
	{
		if (!weeksLoaded.exists(weekToCheck))
		{
			var week:WeekFile = getWeekFile(path, true);
		
			if (week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);
			
				if (i >= originalLength)
				{
					#if MODS_ALLOWED
					weekFile.folder = directory.substring(Paths.mods().length, directory.length - 1);
					#end
				}
		
				if ((PlayState.gameMode == 'story' && PlayState.isStoryMode && !weekFile.hideStoryMode) || (PlayState.gameMode == 'freeplay' && !PlayState.isStoryMode && !weekFile.hideFreeplay))
				{
					weeksLoaded.set(weekToCheck, weekFile);
					weeksList.push(weekToCheck);
				}
			}
		}
	}

	public static function getWeekFile(path:String, ?absolute:Bool = false):WeekFile
	{
		var rawJson:String = null;

		if (Paths.fileExists(path, TEXT, absolute)) {
			rawJson = Paths.getTextFromFile(path);
		}

		if (rawJson != null && rawJson.length > 0) {
			return cast Json.parse(rawJson);
		}

		return null;
	}

	public static function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	@:deprecated("`WeekData.getWeekFileName()` is deprecated. use `PlayState.storyWeekID` instead.")
	public static function getWeekFileName():String
	{
		Debug.logWarn("`WeekData.getWeekFileName()` is deprecated! use `PlayState.storyWeekID` instead.");
		return weeksList[PlayState.storyWeek];
	}

	public static function getCurrentWeek():WeekData
	{
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null):Void
	{
		Paths.currentModDirectory = '';

		if (data != null && data.folder != null && data.folder.length > 0) {
			Paths.currentModDirectory = data.folder;
		}
	}

	public static function loadTheFirstEnabledMod():Void
	{
		Paths.currentModDirectory = '';
		
		#if MODS_ALLOWED
		if (FileSystem.exists('modsList.txt'))
		{
			var list:Array<String> = CoolUtil.listFromString(File.getContent('modsList.txt'));
			var foundTheTop:Bool = false;

			for (i in list)
			{
				var dat:Array<String> = i.split("|");
	
				if (dat[1] == "1" && !foundTheTop)
				{
					foundTheTop = true;
					Paths.currentModDirectory = dat[0];
				}
			}
		}
		#end
	}
}