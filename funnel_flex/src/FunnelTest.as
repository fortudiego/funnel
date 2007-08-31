package {
	import flash.display.*;	
	import flash.events.*;
	import flash.text.*;
	
	import funnel.*;
	import funnel.filter.*;
	import funnel.ioport.*;
	import funnel.event.*;
	
	public class FunnelTest extends Sprite
	{
		/*
		以下のファイルをメンバ変数の宣言箇所でincludeすると、
		DOUTやANALOG、enableといった定数が作成される
		(実体はstatic変数であり、グローバル変数ではないので注意)
		Flash CS3で利用する場合、flaファイルと同じ階層にalias.asを設置する
		*/
		include "alias.as"
		
		private var fio:Funnel;
		private var osc:Osc;
		
		public function FunnelTest()
		{
			/*
			//コンフィギュレーションを配列で渡す場合、例えば以下のように記述する
			var config:Array = [
		    	AIN,  AIN,  AIN,  AIN,
		    	DIN,  DIN,  DIN,  DIN,
		    	AOUT, AOUT, AOUT, AOUT,
		    	DOUT, DOUT, DOUT, DOUT,
		    	DOUT, DIN];
		    new Funnel(config);
			*/
			fio = new Funnel(GAINER_MODE1);
			fio.addEventListener(READY, onReady);
			//fio.addEventListener(SERVER_NOT_FOUND_ERROR, serverNotFound);
	
			var button:DigitalInput = fio.port(4) as DigitalInput;
			var cds:AnalogInput = fio.port(1) as AnalogInput;
			var led:AnalogOutput = fio.port(8) as AnalogOutput;
			
			button.addEventListener(RISING_EDGE, function(event:Event):void {
				//Osc.serviceInterval += 10;
				
				osc.update();
			});
			
			cds.filters = [new Threshold(0.5, 0.1)];
			cds.addEventListener(RISING_EDGE, onLightening);
			cds.addEventListener(FALLING_EDGE, onDarkening);
			
			/*
			Osc(波形, 周波数, 振幅, オフセット, 位相, 更新間隔, 繰り返し回数)
			波形、周波数、位相は正規化されている
			*/
			osc = new Osc(Osc.SQUARE, 1, 1, 0, 0, 5);
			osc.addEventListener(UPDATE, function():void {
				led.value = osc.value;
			});
			
			createView();
		}
		
		private function onReady(event:Event):void {
			trace("onReady");
		}
		
		private function serverNotFound(event:ErrorEvent):void {
			trace(event.text);
		}
		
		private function onLightening(event:Event):void {
			trace("onLightening");
		}
		
		private function onDarkening(event:Event):void {
			trace("onDarkening");
		}
		
		private function createView():void {
			//入力値を表示するテキストフィールドを作成
			var tf:TextField = new TextField();
			tf.autoSize = TextFieldAutoSize.LEFT;
			addChild(tf);
			
			//入力値の表示を更新するenterframeイベントハンドラを設定
			addEventListener(Event.ENTER_FRAME, function(event:Event):void {
				var inputInfo:String = "";
				for (var i:uint = 0; i < fio.portCount; ++i) {
					var aPort:Port = fio.port(i);
					if(aPort.direction == INPUT) {
						var pad:String = i < 10 ? "0" : "";
						inputInfo += "port[" + pad + i + "]: ";
						inputInfo += format(aPort.value, 3);
						inputInfo += "    ave: " + format(aPort.average, 3);
						inputInfo += "    min: " + format(aPort.minimum, 3);
						inputInfo += "    max: " + format(aPort.maximum, 3);
						inputInfo += "\n";
					}
				}
				tf.text = inputInfo;
			});
			
			//TODO:出力値を更新するテキストボックスを作成する
		}
		
		private static function format(num:Number, digits:Number):String {
 			if (digits <= 0) {
				return Math.round(num).toString();
			} 
			var tenToPower:Number = Math.pow(10, digits);
			var cropped:String = String(Math.round(num * tenToPower) / tenToPower);
			if (cropped.indexOf(".") == -1) {
				cropped += ".0";
			}

			var halves:Array = cropped.split(".");
			var zerosNeeded:Number = digits - halves[1].length;
			for (var i:uint = 1; i <= zerosNeeded; i++) {
				cropped += "0";
			}
			return(cropped);
		}
		
	}
}
