package funnel
{
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.events.*;
	import funnel.osc.*;
	
	/**
	 * FunnelServerのコマンドポートと通信を行うクラスです。
	 * @private
	 */	
	public class CommandPort extends NetPort
	{
		private static const ERROR_EVENTS:Array = [
			null,
			FunnelErrorEvent.ERROR,
			FunnelErrorEvent.REBOOT_ERROR,
			FunnelErrorEvent.CONFIGURATION_ERROR];

		public function CommandPort() {
			super();
		}

		public function writeCommand(command:OSCMessage):Task {
			var task:Task = new Task();
			Task.waitEvent(_socket, ProgressEvent.SOCKET_DATA).addCallback(checkError, task);
			_socket.writeBytes(command.toBytes());
			_socket.flush();
			return task;
		}
		
		private function checkError(task:Task):void {
			var response:ByteArray = new ByteArray();
			_socket.readBytes(response);
			var args:Array = OSCPacket.createWithBytes(response).value;
			if (args[0] is OSCInt && args[0].value < 0) {
				var errorCode:uint = -args[0].value;
				var message:String = '';
				if (args[1] != null) message = args[1].value;
				task.fail(new FunnelErrorEvent(ERROR_EVENTS[errorCode], false, false, message));
			} else {
				task.complete();
			}
		}
	}
}