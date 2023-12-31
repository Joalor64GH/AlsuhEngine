package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;

using StringTools;

class SwagCamera extends FlxCamera
{
	/**
	 * properly follow framerate
	 * most of this just copied from FlxCamera,
	 * only lines 96 and 97 are changed
	 */
	override public function updateFollow():Void
	{
		// Either follow the object closely,
		// or double check our deadzone and update accordingly.
		if (deadzone == null)
		{
			target.getMidpoint(_point);
			_point.addPoint(targetOffset);
			focusOn(_point);
		}
		else
		{
			var edge:Float;
			var targetX:Float = target.x + targetOffset.x;
			var targetY:Float = target.y + targetOffset.y;

			if (style == SCREEN_BY_SCREEN)
			{
				if (targetX >= (scroll.x + width))
				{
					_scrollTarget.x += width;
				}
				else if (targetX < scroll.x)
				{
					_scrollTarget.x -= width;
				}

				if (targetY >= (scroll.y + height))
				{
					_scrollTarget.y += height;
				}
				else if (targetY < scroll.y)
				{
					_scrollTarget.y -= height;
				}
			}
			else
			{
				edge = targetX - deadzone.x;
				if (_scrollTarget.x > edge)
				{
					_scrollTarget.x = edge;
				}
				edge = targetX + target.width - deadzone.x - deadzone.width;
				if (_scrollTarget.x < edge)
				{
					_scrollTarget.x = edge;
				}

				edge = targetY - deadzone.y;
				if (_scrollTarget.y > edge)
				{
					_scrollTarget.y = edge;
				}
				edge = targetY + target.height - deadzone.y - deadzone.height;
				if (_scrollTarget.y < edge)
				{
					_scrollTarget.y = edge;
				}
			}

			if ((target is FlxSprite))
			{
				if (_lastTargetPosition == null)
				{
					_lastTargetPosition = FlxPoint.get(target.x, target.y); // Creates this point.
				}
				_scrollTarget.x += (target.x - _lastTargetPosition.x) * followLead.x;
				_scrollTarget.y += (target.y - _lastTargetPosition.y) * followLead.y;

				_lastTargetPosition.x = target.x;
				_lastTargetPosition.y = target.y;
			}

			if (followLerp >= 60)
			{
				scroll.copyFrom(_scrollTarget); // no easing
			}
			else
			{
				// THIS THE PART THAT ACTUALLY MATTERS LOL
				scroll.x += (_scrollTarget.x - scroll.x) * followLerp;
				scroll.y += (_scrollTarget.y - scroll.y) * followLerp;
			}
		}
	}

	/**
	 * Tells this camera object what `FlxObject` to track.
	 *
	 * @param   Target   The object you want the camera to track. Set to `null` to not follow anything.
	 * @param   Style    Leverage one of the existing "deadzone" presets. Default is `LOCKON`.
	 *                   If you use a custom deadzone, ignore this parameter and
	 *                   manually specify the deadzone after calling `follow()`.
	 * @param   Lerp     How much lag the camera should have (can help smooth out the camera movement).
	 */
	override public function follow(Target:FlxObject, ?Style:FlxCameraFollowStyle, ?Lerp:Float):Void
	{
		if (Style == null)
			Style = LOCKON;

		if (Lerp == null)
			Lerp = 60;

		style = Style;
		target = Target;
		followLerp = Lerp;
		var helper:Float;
		var w:Float = 0;
		var h:Float = 0;
		_lastTargetPosition = null;

		switch (Style)
		{
			case LOCKON:
				if (target != null)
				{
					w = target.width;
					h = target.height;
				}
				deadzone = FlxRect.get((width - w) / 2, (height - h) / 2 - h * 0.25, w, h);

			case PLATFORMER:
				var w:Float = (width / 8);
				var h:Float = (height / 3);
				deadzone = FlxRect.get((width - w) / 2, (height - h) / 2 - h * 0.25, w, h);

			case TOPDOWN:
				helper = Math.max(width, height) / 4;
				deadzone = FlxRect.get((width - helper) / 2, (height - helper) / 2, helper, helper);

			case TOPDOWN_TIGHT:
				helper = Math.max(width, height) / 8;
				deadzone = FlxRect.get((width - helper) / 2, (height - helper) / 2, helper, helper);

			case SCREEN_BY_SCREEN:
				deadzone = FlxRect.get(0, 0, width, height);

			case NO_DEAD_ZONE:
				deadzone = null;
		}
	}

	override function set_followLerp(Value:Float):Float
	{
		return followLerp = FlxMath.bound(Value, 0, 60);
	}
}