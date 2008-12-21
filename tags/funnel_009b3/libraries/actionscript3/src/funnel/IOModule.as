package funnel
{
	import flash.events.Event;
	import funnel.osc.*;

	/**
	 * PCに接続されたI/Oモジュールを抽象化して共通の方法でアクセスするためのクラスです。
	 *
	 */
	public class IOModule
	{
		private var _system:IOSystem;
		private var _id:uint;
		private var _ioPins:Array;
		private var _updatedValues:Array;
		private var _pinCount:uint;
		private var _config:Configuration;

		private var _sysexListeners:Array;

		/**
		 *
		 * @param system FunnelServerと通信をするIOSystemオブジェクト
		 * @param id IOModuleオブジェクトのID
		 * @param configuration コンフィギュレーション
		 *
		 */
		public function IOModule(system:IOSystem, configuration:Configuration) {
			_system = system;
			_config = configuration;
			_id = configuration.moduleID;

			var pinTypes:Array = _config.config;
			_pinCount = pinTypes.length;
			_ioPins = new Array(_pinCount);
			_updatedValues = new Array(_pinCount);
			for (var i:uint = 0; i < _pinCount; ++i) {
				var aPin:Pin = new Pin(i, pinTypes[i]);
				var type:uint = aPin.type;
				if (type == Pin.AOUT || type == Pin.DOUT) {
					aPin.addEventListener(PinEvent.CHANGE, handleChange);
				}
				_ioPins[i] = aPin;
			}
			
			_sysexListeners = new Array();
		}

		/**
		 * pinNumで指定したPinオブジェクトを取得します。
		 * @param pinNum ピン番号
		 * @return Pinオブジェクト
		 * @see Pin
		 */
		public function pin(pinNum:uint):Pin {
			return _ioPins[pinNum];
		}

		/**
		 * pinNumで指定したアナログピンのPinオブジェクトを取得します。
		 * @param pinNum アナログピン番号
		 * @return Pinオブジェクト
		 * @see Pin
		 */
		public function analogPin(pinNum:uint):Pin {
			if (_config.analogPins == null) throw new ArgumentError("analog pins are not available");
			if (_config.analogPins[pinNum] == null) throw new ArgumentError("analog pin is not available at " + pinNum);
			return _ioPins[_config.analogPins[pinNum]];
		}

		/**
		 * pinNumで指定したデジタルピンのPinオブジェクトを取得します。
		 * @param pinNum デジタルピン番号
		 * @return Pinオブジェクト
		 * @see Pin
		 */
		public function digitalPin(pinNum:uint):Pin {
			if (_config.digitalPins == null) throw new ArgumentError("digital pins are not available");
			if (_config.digitalPins[pinNum] == null) throw new ArgumentError("digital pin is not available at " + pinNum);
			return _ioPins[_config.digitalPins[pinNum]];
		}

		public function sendSysex(command:uint, message:Array):void {
			_system.sendSysex(_id, command, message);
		}

		public function addSysexListener(device:I2CDevice):void {
			_sysexListeners[device.address] = device;
		}

		public function handleSysex(command:uint, data:Array):void {
			// data should be: slave address, register, data0, data1...
			_sysexListeners[data[0]].handleSysex(command, data);
		}

		/**
		 * @return ピン数
		 *
		 */
		public function get pinCount():uint {
			return _pinCount;
		}

		private function handleChange(event:PinEvent):void {
			var pin:Pin = event.target as Pin;
			var index:uint = pin.number;
			if (_system.autoUpdate) {
				_system.sendOut(_id, index, [pin.value]);
			} else {
				_updatedValues[index] = pin.value;
			}
		}

		/**
		 * @private
		 *
		 */
		internal function update():void {
			var value:Number;
			var adjoiningValues:Array;
			var startIndex:uint;
			for (var i:uint = 0; i < _pinCount; ++i) {
				if (_updatedValues[i] != null) {
					if (adjoiningValues == null) {
						adjoiningValues = [];
						startIndex = i;
					}
					adjoiningValues.push(_updatedValues[i]);
					_updatedValues[i] = null;
				} else if (adjoiningValues != null) {
					_system.sendOut(_id, startIndex, adjoiningValues);
					adjoiningValues = null;
				}
			}
			if (adjoiningValues != null) {
				_system.sendOut(_id, startIndex, adjoiningValues);
			}
		}

	}
}