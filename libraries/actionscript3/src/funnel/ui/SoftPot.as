package funnel.ui {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import funnel.*;

	/**
	 * @copy SoftPotEvent2#PRESS
	 */
	[Event(name="press",type="SoftPotEvent2")]

	/**
	 * @copy SoftPotEvent2#RELEASE
	 */
	[Event(name="release",type="SoftPotEvent2")]

	/**
	 * @copy SoftPotEvent2#DRAG
	 */
	[Event(name="drag",type="SoftPotEvent2")]

	/**
	 * @copy SoftPotEvent2#FLICK_UP
	 */
	[Event(name="flickUp",type="SoftPotEvent2")]
	
	/**
	 * @copy SoftPotEvent2#FLICK_DOWN
	 */
	[Event(name="flickDown",type="SoftPotEvent2")]	

	/**
	 * @copy SoftPotEvent2#TAP
	 */
	[Event(name="tap",type="SoftPotEvent2")]
	

	/**
	 * This is the class to express a SoftPot
	 *
	 * @author Shigeru Kobayashi
	 * @author Jeff Hoefs
	 * @author Ben Chao
	 */
	public class SoftPot2 extends PhysicalInput {
	
		private var _pin:Pin;
		
		// milliseconds 
		static private var TAP_TIMEOUT:uint = 200;  
		// flick is before, drag is after this time 
		static private var FLICK_TIMEOUT:uint = 200; 
		static private var PRESS_TIMER_INTERVAL:uint = 10; 
		static private var PRESS_MIN_TIME:uint = 200; 
		static private var DEBOUNCE_TIMEOUT:uint = 20;
	
		// drag 	 
		private var _isDrag:Boolean; 
		
		// flick 
		private var _flickTimer:Timer;
		private var _flickDir:Number;
		private var _flick_distance:Number;
		
		private var _dispatchedPress:Boolean = false; 
		private var _pressTimer:Timer;		
		private var _touchPoint:Number; 	
		private var _lastMovePoint:Number; 
		private var _isTouched:Boolean = false;
		private var _distanceFromPressed:Number;
		
		private var _minFlickMovement:Number;
		private var _minDragMovement:Number;
	
		// debug mode 		
		private var _debugMode : Boolean = false;	
	
		/**
		 *
		 * @param potPin the pin number for a SoftPot
		 * @param length length of the softpot in mm 
		 */
		public function SoftPot2(potPin:Pin, softPotLength:Number = 100) {
			super();
			
			// play with these settings to fine tune
			_minFlickMovement = 1.0/softPotLength * 5.0;
			_minDragMovement = 1.0/softPotLength * 2.0; // 2.5

			_pin = potPin;
			
			_pin.addEventListener(PinEvent.CHANGE, onChange);		
			
			_pressTimer = new Timer(PRESS_TIMER_INTERVAL,0);
			_pressTimer.addEventListener(TimerEvent.TIMER,onTimerTick);
						 
			_flickTimer = new Timer(FLICK_TIMEOUT,1); 			
			
		}
		
		private function onChange(evt:PinEvent):void {
			if(evt.currentTarget.value == 0) {
				onRelease();
			} else {
				if(!_isTouched) {
					start_touch(evt.currentTarget.value);
					_lastMovePoint = evt.currentTarget.value; 
				} else {
					onMove(evt.currentTarget.value);
				}
			}
		}
		
		public function setMinFlickMovement ( num:Number ) : void {
			_minFlickMovement = num;
		}
		
		private function onTimerTick(evt:TimerEvent):void {
			if ( _isTouched && _pressTimer.running && ! _dispatchedPress ) {
				if ( _pressTimer.currentCount == PRESS_MIN_TIME / PRESS_TIMER_INTERVAL ) {
					dispatch(SoftPotEvent2.PRESS);
					_dispatchedPress = true; 
				}
			}	
		}
		
		private function start_touch(touchPoint:Number) : void {

			// button press 
			_pressTimer.reset();
			_pressTimer.start();
						
			// where we pressed  
			_touchPoint = touchPoint; 	
			_dispatchedPress = false; 			
					
			_isTouched = true;		
			_isDrag = false; 		
		}
		
		private function onRelease():void {		

			var _dispatched_flick:Boolean = false; 
			
			// discard unintentional touch / noise
			if(_pressTimer.currentCount > DEBOUNCE_TIMEOUT / PRESS_TIMER_INTERVAL) {
				// must meet minimum time requirement for flick  
				if ( _flickTimer.running ) {
					if (_flickDir > 0) {
						dispatch(SoftPotEvent2.FLICK_DOWN);
					} else {
						dispatch(SoftPotEvent2.FLICK_UP);
					}	
					_dispatched_flick = true; 
					
				} 
							
				if ( ! _dispatched_flick ) {
			
					// check for presses  
					if( _pressTimer.running ) {
				
						// if less than tap timeout, then it is a tap 
						if(!_isDrag && _pressTimer.currentCount <= TAP_TIMEOUT / PRESS_TIMER_INTERVAL ) {
							dispatch(SoftPotEvent2.TAP);
						}
						else {				
							dispatch(SoftPotEvent2.RELEASE);
						}
						
					} else {
						// if press timer is not running, we didn't initiate mouse down on this object
						// instead moved over it (while holding mouse down)
						dispatch(SoftPotEvent2.RELEASE);
						// for this class, should never get here - keep this to be safe?
						debug("Dispatch: Released - Rare");
					}
				}
			}

			reset_for_next(); 
		}
		
		private function onMove(touchPoint:Number):void {		
		
			_touchPoint = touchPoint;		
						
			// save current point 		
			var _curMovePoint:Number = touchPoint; 
			
			// flick handeling 			
			_flick_distance = Math.abs(_curMovePoint - _lastMovePoint) 
			
			
			if (!_isDrag && _flick_distance > _minFlickMovement ) {
				// this is checked at mouse up
				_flickTimer.reset(); 
				_flickTimer.start(); 
				
				if(_curMovePoint - _lastMovePoint > 0) {
					_flickDir = 1;
				} else {
					_flickDir = -1;
				}
				
				_isDrag = false; 
			}			
			
			var _drag_distance:Number = Math.abs(_curMovePoint - _lastMovePoint);				

			// dragging handler 
			// dont check when flick timer is running 
			if ( ( _drag_distance > _minDragMovement) && ( _flickTimer.running == false ) ) {
				_isDrag = true; 
			}
			
			// ensure we fired press event 
			// since we could have started dragging before press is done 
			if (_isDrag && _pressTimer.running && ! _dispatchedPress ) {
				dispatch(SoftPotEvent2.PRESS);
				debug("Dispatch: Pressed - Forced");
				_dispatchedPress = true; 				
			}
	
			if ( _isDrag ) {
				dispatch(SoftPotEvent2.DRAG);
				_distanceFromPressed = _curMovePoint - _lastMovePoint;
			}
									
			debug("SoftPot: distance traveled flick is " + _flick_distance); 
			debug("SoftPot: distance traveled drag is " + _drag_distance); 

			
			// reuse for next 
			_lastMovePoint = _curMovePoint; 
				
		}		

		/**
		 *
		 * @return the current value
		 */
		public function get value():Number {
			return _touchPoint;
		}

		/**
		 * 
		 * @return whether pressed or not pressed
		 */
		public function get isPressed():Boolean {
			return _dispatchedPress;
		}

		/**
		 * 
		 * @return the current distance from the pressed point
		 */
		public function get distanceFromPressed():Number {
			return _distanceFromPressed;
		}

		/**
		 *
		 * @param minimum the minimum value
		 * @param maximum the minimum value
		 */
		public function setRange(minimum:Number, maximum:Number):void {
			_pin.removeAllFilters();
			_pin.addFilter(new Scaler(minimum, maximum, 0, 1, Scaler.LINEAR));
		}

		// how to dispatch the event 
		private function dispatch(type:String):void {
			debug("SoftPot dispatch " + type);
			dispatchEvent(new SoftPotEvent2(type, _touchPoint));
		}		
		
		// reset whatever you need for the next Touch event 
		private function reset_for_next () : void {
		
			_flickTimer.stop();  
			_pressTimer.stop(); 
			_dispatchedPress = false; 
			
			_isTouched = false; 		
			_isDrag = false; 
		}		
		
		// for debugging 
		private function debug ( str:String ) : void {
			if ( _debugMode ) {
				trace(str); 
			}
		}
		
	}
}