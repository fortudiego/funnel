package funnel {	import funnel.IOSystem;		/**	 * FioクラスはFunnel I/Oモジュールを扱うためのクラスです。	 * 	 */ 	public class Fio extends IOSystem {				/**		 * 全てのモジュールを表します。fio.module(ALL).port(10).value = xのようにすることで、全モジュールの10番目のポートの値をxに設定します。		 */		public static const ALL:uint = 0xFFFF;				/**		 * Fio用のデフォルトのコンフィギュレーションを取得します。		 * @return Configurationオブジェクト		 */		public static function get FIO():Configuration {			var k:Configuration = new Configuration();			k.config = [				AIN,  AIN,	AIN,  AIN,				DIN,  DIN,	DIN,  DIN, DIN, DIN,				AOUT, AOUT, AOUT, AOUT			];			k.ainPorts = [0, 1, 2, 3];			k.aoutPorts = [10, 11, 12, 13];			return k;		}				/**		 * @param nodes 利用するモジュールのID配列		 * @param host ホスト名		 * @param portNum ポート番号		 * @param samplingInterval サンプリング間隔(ms)		 */ 		public function Fio(nodes:Array = null, host:String = "localhost", portNum:Number = 9000, samplingInterval:int = 33) {			if (nodes == null) nodes = [];			nodes.push(ALL);			var configs:Array = [];			for each (var id:uint in nodes) {				var config:Configuration = Fio.FIO;				config.moduleID = id;				configs.push(config);			}			super(configs, host, portNum, samplingInterval);		}	}}