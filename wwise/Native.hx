package wwise;

import wwise.Api.AkEventCallbackFunc;

@:publicFields
#if !disable_sound
@:hlNative("?hlwwise")
#end
class Native {
	
	static function init(basePath : hl.Bytes, useComm: Bool) : Bool {
		return false;
	}

	static function render() {}
	static function terminate() {}

	static function register_obj(id: Int, name: hl.Bytes) {}
	static function unregister_obj(id: Int) {}
	static function set_default_listener(obj: Int) {}
	static function set_listener(emitter: Int, listener: Int) {}
	static function load_bank(name: hl.Bytes) : Bool {
		return false;
	}
	static function unload_bank(name: hl.Bytes) {}
	static function post_event(name: hl.Bytes, obj: Int, callbackType: Int, callback: AkEventCallbackFunc) {}
	static function post_trigger(name: hl.Bytes, obj: Int) {}
	static function set_position(id: Int, x: Float, y: Float, z: Float) {}
	static function set_position_orientation(id: Int, x: Float, y: Float, z: Float, fx: Float, fy: Float, fz: Float, tx: Float, ty: Float, tz: Float) {}
	static function set_rtpc(name: hl.Bytes, value: Float, obj: Int) {}
	static function set_switch(group: hl.Bytes, state: hl.Bytes, obj: Int) {}
	static function set_state(group: hl.Bytes, state: hl.Bytes) {}
	static function stop_all(obj: Int) {}
	static function set_language(lang: hl.Bytes) {}
}