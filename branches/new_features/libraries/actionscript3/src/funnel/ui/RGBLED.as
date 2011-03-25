﻿package funnel.ui {	import funnel.*;	/**	 * This is the class to express a full color LED	 * 	 * @author Shigeru Kobayashi	 */	public class RGBLED {		public static const SOURCE_DRIVE:uint = 0;		public static const SYNC_DRIVE:uint = 1;		public static const COMMON_ANODE:uint = SYNC_DRIVE;		public static const COMMON_CATHODE:uint = SOURCE_DRIVE;		public static const COMMON_KATHODE:uint = SOURCE_DRIVE;        public static const ANODE_COMMON:uint = COMMON_ANODE;        public static const CATHODE_COMMON:uint = COMMON_CATHODE;        public static const KATHODE_COMMON:uint = COMMON_KATHODE;		private var _redLED:LED;		private var _greenLED:LED;		private var _blueLED:LED;		/**		 * 		 * @param redLEDPin the pin number of red		 * @param greenLEDPin the pin number of red		 * @param blueLEDPin the pin number of red		 * @param driveMode the drive mode		 * @see ANODE_COMMON		 * @see CATHODE_COMMON		 * @see KATHODE_COMMON		 */		public function RGBLED(redLEDPin:Pin, greenLEDPin:Pin, blueLEDPin:Pin, driveMode:uint = ANODE_COMMON) {			_redLED = new LED(redLEDPin, driveMode);			_greenLED = new LED(greenLEDPin, driveMode);			_blueLED = new LED(blueLEDPin, driveMode);		}		/**		 * 		 * @param red the new red value to set		 * @param green the new green value to set		 * @param blue the new blue value to set		 */		public function setColor(red:Number, green:Number, blue:Number):void {			_redLED.value = red;			_greenLED.value = green;			_blueLED.value = blue;		}		/**		 * 		 * @param time the fade-in time (in milliseconds)		 */		public function fadeIn(time:Number = 1000):void {			_redLED.fadeTo(1, time);			_greenLED.fadeTo(1, time);			_blueLED.fadeTo(1, time);		}		/**		 * 		 * @param time the fade-out time (in milliseconds)		 */		public function fadeOut(time:Number = 1000):void {			_redLED.fadeTo(0, time);			_greenLED.fadeTo(0, time);			_blueLED.fadeTo(0, time);		}		/**		 * 		 * @param red the new red value to set		 * @param green the new green value to set		 * @param blue the new blue value to set		 * @param time the fade time		 */		public function fadeTo(red:Number, green:Number, blue:Number, time:Number = 1):void {			_redLED.fadeTo(red, time);			_greenLED.fadeTo(green, time);			_blueLED.fadeTo(blue, time);		}	}}