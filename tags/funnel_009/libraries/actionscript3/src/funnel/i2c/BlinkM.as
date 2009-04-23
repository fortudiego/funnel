﻿package funnel.i2c {	import funnel.i2c.I2CDevice;	/**	 * This is the class to express BlinkM devices	 */	public class BlinkM extends I2CDevice {		public function BlinkM(ioModule:*, address:uint = 0x09) {			super(ioModule, address);		}		public function goToRGBColorNow(color:Array):void {			_io.sendSysex(I2C_REQUEST, [WRITE, address, 'n'.charCodeAt(0), color[0], color[1], color[2]]);		}		public function fadeToRGBColor(color:Array, speed:int = -1):void {			if (speed >= 0) {				_io.sendSysex(I2C_REQUEST, [WRITE, address, 'f'.charCodeAt(0), speed]);			}			_io.sendSysex(I2C_REQUEST, [WRITE, address, 'c'.charCodeAt(0), color[0], color[1], color[2]]);		}		public function fadeToRandomRGBColor(color:Array, speed:int = -1):void {			if (speed >= 0) {				_io.sendSysex(I2C_REQUEST, [WRITE, address, 'f'.charCodeAt(0), speed]);			}			_io.sendSysex(I2C_REQUEST, [WRITE, address, 'C'.charCodeAt(0), color[0], color[1], color[2]]);		}		public function fadeToHSBColor(color:Array, speed:int = -1):void {			if (speed >= 0) {				_io.sendSysex(I2C_REQUEST, [WRITE, address, 'f'.charCodeAt(0), speed]);			}			_io.sendSysex(I2C_REQUEST, [WRITE, address, 'h'.charCodeAt(0), color[0], color[1], color[2]]);		}		public function fadeToRandomHSBColor(color:Array, speed:int = -1):void {			if (speed >= 0) {				_io.sendSysex(I2C_REQUEST, [WRITE, address, 'f'.charCodeAt(0), speed]);			}			_io.sendSysex(I2C_REQUEST, [WRITE, address, 'H'.charCodeAt(0), color[0], color[1], color[2]]);		}		public function setFadeSpeed(speed:uint):void {			_io.sendSysex(I2C_REQUEST, [WRITE, address, 'f'.charCodeAt(0), speed]);		}		public function playLightScript(scriptId:uint, theNumberOfRepeats:uint = 1, lineNumber:uint = 0):void {			_io.sendSysex(I2C_REQUEST, [WRITE, address, 'p'.charCodeAt(0), scriptId, theNumberOfRepeats, lineNumber]);		}		public function stopScript():void {			_io.sendSysex(I2C_REQUEST, [WRITE, address, 'o'.charCodeAt(0)]);		}		public override function handleSysex(command:uint, data:Array):void {			// TODO: implement if needed			trace("BlinkM: " + data);		}	}}