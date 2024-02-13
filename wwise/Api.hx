package wwise;

#if wwiseIDs
private typedef Init = haxe.macro.MacroType < [wwise.Macros.buildTypes()] > ;
#else

abstract Event(String) from String to String {
	static inline public function make(s: String) : Event { return cast s; }
	inline public function name() { return @:privateAccess this.bytes; };
}

abstract Trigger(String) from String to String {
	static inline public function make(s: String) : Trigger { return cast s; }
	inline public function name() { return @:privateAccess this.bytes; };
}

abstract Switch(String) from String to String {
	static inline public function make(s: String) : Switch { return cast s; }
	inline public function name() { return @:privateAccess this.bytes; };
}

abstract SwitchGroup(String) from String to String {
	static inline public function make(s: String) : SwitchGroup { return cast s; }
	inline public function name() { return @:privateAccess this.bytes; };
}

abstract State(String) from String to String {
	static inline public function make(s: String) : State { return cast s; }
	inline public function name() { return @:privateAccess this.bytes; };
}

abstract StateGroup(String) from String to String {
	static inline public function make(s: String) : StateGroup { return cast s; }
	inline public function name() { return @:privateAccess this.bytes; };
}

abstract Param(String) from String to String {
	static inline public function make(s: String) : Param { return cast s; }
	inline public function name() { return @:privateAccess this.bytes; };
}
#end

abstract AkPlayingID(Int)
{
	inline public function new(i:Int)
	{
		this = i;
	}

	public static var InvalidID: AkPlayingID = cast 0;
}


enum abstract AkCallbackType(Int) from Int to Int {
	var EndOfEvent					= 0x0001;	///< Callback triggered when reaching the end of an event. AkCallbackInfo can be cast to AkEventCallbackInfo.
	var EndOfDynamicSequenceItem	= 0x0002;	///< Callback triggered when reaching the end of a dynamic sequence item. AkCallbackInfo can be cast to AkDynamicSequenceItemCallbackInfo.
	var Marker						= 0x0004;	///< Callback triggered when encountering a marker during playback. AkCallbackInfo can be cast to AkMarkerCallbackInfo.
	var Duration					= 0x0008;	///< Callback triggered when the duration of the sound is known by the sound engine. AkCallbackInfo can be cast to AkDurationCallbackInfo.

	var SpeakerVolumeMatrix			= 0x0010;   ///< Callback triggered at each frame, letting the client modify the speaker volume matrix. AkCallbackInfo can be cast to AkSpeakerVolumeMatrixCallbackInfo.

	var Starvation					= 0x0020;	///< Callback triggered when playback skips a frame due to stream starvation. AkCallbackInfo can be cast to AkEventCallbackInfo.

	var MusicPlaylistSelect			= 0x0040;	///< Callback triggered when music playlist container must select the next item to play. AkCallbackInfo can be cast to AkMusicPlaylistCallbackInfo.
	var MusicPlayStarted			= 0x0080;	///< Callback triggered when a "Play" or "Seek" command has been executed ("Seek" commands are issued from AK::SoundEngine::SeekOnEvent()). Applies to objects of the Interactive-Music Hierarchy only. AkCallbackInfo can be cast to AkEventCallbackInfo.

	var MusicSyncBeat				= 0x0100;	///< Enable notifications on Music Beat. AkCallbackInfo can be cast to AkMusicSyncCallbackInfo.
	var MusicSyncBar				= 0x0200;	///< Enable notifications on Music Bar. AkCallbackInfo can be cast to AkMusicSyncCallbackInfo.
	var MusicSyncEntry				= 0x0400;	///< Enable notifications on Music Entry Cue. AkCallbackInfo can be cast to AkMusicSyncCallbackInfo.
	var MusicSyncExit				= 0x0800;	///< Enable notifications on Music Exit Cue. AkCallbackInfo can be cast to AkMusicSyncCallbackInfo.
	var MusicSyncGrid				= 0x1000;	///< Enable notifications on Music Grid. AkCallbackInfo can be cast to AkMusicSyncCallbackInfo.
	var MusicSyncUserCue			= 0x2000;	///< Enable notifications on Music Custom Cue. AkCallbackInfo can be cast to AkMusicSyncCallbackInfo.
	var MusicSyncPoint				= 0x4000;	///< Enable notifications on Music switch transition synchronization point. AkCallbackInfo can be cast to AkMusicSyncCallbackInfo.
	var MusicSyncAll				= 0x7f00;	///< Use this flag if you want to receive all notifications concerning AK_MusicSync registration.

	var MIDIEvent					= 0x10000;	///< Enable notifications for MIDI events. AkCallbackInfo can be cast to AkMIDIEventCallbackInfo.

	var CallbackBits				= 0xfffff;	///< Bitmask for all callback types.
}

@:keep
@:struct
class AkEventCallbackInfo
{
	var ptr: hl.Bytes; // pCookie
	public var gameObjId: hl.I64;
	public var playingId: AkPlayingID; ///< Playing ID of Event, returned by PostEvent()
	public var eventId: Int; ///< Unique ID of Event, passed to PostEvent()
}

typedef AkEventCallbackFunc = ( Int, AkEventCallbackInfo ) -> Void;


@:access(wwise.Api)
@:allow(wwise.Api)
class GameObject {
	var id : Int;
	var name : String;
	var switchCache : Map<SwitchGroup, Switch>;
	var posX = 0.0;
	var posY = 0.0;
	var posZ = 0.0;
	var frontX = 0.0;
	var frontY = 0.0;
	var frontZ = 0.0;
	var upX = 0.0;
	var upY = 0.0;
	var upZ = 0.0;


	public function new(?name: String) {
		id = Api.OBJID++;
		this.name = name;
		Api.register(this);
	}

	public function remove() {
		stopAll();
		Api.unregister(this);
	}

	public function postEvent(evt: Event, callbackType: Int = 0, ?callback: AkEventCallbackFunc ): AkPlayingID {
		if(!Api.initialized) return AkPlayingID.InvalidID;
		return cast Native.post_event(evt.name(), id, callbackType, callback);
	}

	public function postTrigger(evt: Trigger) {
		if(!Api.initialized) return;
		Native.post_trigger(evt.name(), id);
	}

	public function stopAll() {
		if(!Api.initialized) return;
		Native.stop_all(id);
	}

	public function setListener(listener : GameObject) {
		if(!Api.initialized) return;
		Native.set_listener(id, listener.id);
	}

	/** Wwise is left-handed Y-UP **/
	public function setPosition(x: Float, y: Float, z: Float) {
		if(!Api.initialized) return;
		if(posX == x && posY == y && posZ == z)
			return;
		Native.set_position(id, y, z, x);
		posX = x;
		posY = y;
		posZ = z;
	}

	public function setParam(p: Param, value: Float) {
		if(!Api.initialized) return;
		Native.set_rtpc(p.name(), value, id);
	}

	public function setSwitch(s: SwitchGroup, value: Switch) {
		if(!Api.initialized) return;
		if(switchCache == null) switchCache = new Map();
		if(switchCache.get(s) == value) return;
		Native.set_switch(s.name(), value.name(), id);
		switchCache.set(s, value);
	}

	public function update() {
		#if heaps
		if(follow != null)
			setTransform(follow);
		#end
	}

	#if heaps
	public var follow : h3d.Matrix;

	public function setTransform(mat: h3d.Matrix) {
		if(!Api.initialized) return;
		var front = mat.front();
		var up = mat.up();
		if(posX == mat.tx && posY == mat.ty && posZ == mat.tz &&
			frontX == front.x && frontY == front.y && frontZ == front.z &&
			upX == up.x && upY == up.y && upZ == up.z)
			return;
		Native.set_position_orientation(id, mat.ty, mat.tz, mat.tx, front.y, front.z, front.x, up.y, up.z, up.x);
		posX = mat.tx;
		posY = mat.ty;
		posZ = mat.tz;
		frontX = front.x;
		frontY = front.y;
		frontZ = front.z;
		upX = up.x;
		upY = up.y;
		upZ = up.z;
	}
	#end
}

private typedef AsyncLoad = { f: Void->Void };
class Api {

	static var OBJID = 100;
	static var DEFAULT_OBJECT : GameObject;
	static var DEFAULT_LISTENER : GameObject;

	static var initialized = false;

	static var objects : Array<GameObject> = [];
	static var loadingQueue = new sys.thread.Deque();

	public static function init(basePath: String, useComm: Bool) {
		if(!Native.init(@:privateAccess basePath.bytes, useComm)) {
			trace("Failed to init Wwise");
			return false;
		}
		initialized = true;
		DEFAULT_OBJECT = new GameObject("DefaultObject");
		DEFAULT_LISTENER = new GameObject("DefaultListener");
		Native.set_default_listener(DEFAULT_LISTENER.id);

		loadBank("Init.bnk");

		return true;
	}

	/** Can be called when switching between scenes **/
	public static function clearObjects() {
		if(!initialized) return;
		var keepList = [DEFAULT_OBJECT, DEFAULT_LISTENER];
		for(o in objects) {
			if(keepList.indexOf(o) >= 0) continue;
			o.stopAll();
			Native.unregister_obj(o.id);
		}
		objects = keepList;
	}

	public static function terminate() {
		if(!initialized) return;
		Native.terminate();
		initialized = false;
	}

	/** Loads asynchronously if a callback is passed **/
	public static function loadBank(name: String, callback: Bool->Void=null) {
		if(!initialized) return false;
		if(callback == null)
			return Native.load_bank(@:privateAccess name.bytes);
		else {
			sys.thread.Thread.create(function() {
				var success = Native.load_bank(@:privateAccess name.bytes);
				sys.thread.Thread.current().sendMessage(success);
				if(callback != null) {
					var res : AsyncLoad = {
						f: callback.bind(success)
					};
					loadingQueue.push(res);
				}
			});
		}
		return true;
	}

	static function dispatchCallbacks() {
		var res : AsyncLoad = loadingQueue.pop(false);
		if(res != null)
			res.f();
	}

	public static function postEvent(evt: Event, callbackType = 0, callback: AkEventCallbackFunc = null): AkPlayingID {
		if(!initialized) return AkPlayingID.InvalidID;
		return DEFAULT_OBJECT.postEvent(evt, callbackType, callback);
	}

	public static function postTrigger(evt: Trigger) {
		if(!initialized) return;
		DEFAULT_OBJECT.postTrigger(evt);
	}

	public static function setParam(p: Param, value: Float) {
		if(!initialized) return;
		Native.set_rtpc(p.name(), value, -1);
	}

	public static function setState(s: StateGroup, value: State) {
		if(!initialized) return;
		Native.set_state(s.name(), value.name());
	}

	public static function setLanguage(lang: String) {
		if(!initialized) return;
		Native.set_language(@:privateAccess lang.bytes);
	}

	#if heaps
	static var camera : h3d.Camera;
	static var cameraDistance : Float = 0.;

	/** Make default listener follow camera automatically **/
	public static function setCamera(c: h3d.Camera, distance=0.) {
		camera = c;
		cameraDistance = distance;
	}

	/** Can be used to manually set additional listeners **/
	static public function setCameraListenerPosition( id : Int, camera : h3d.Camera, camDistance : Float ) {
		if(!initialized) return;
		var front = camera.target.sub(camera.pos).normalized();
		var right = front.cross(new h3d.Vector(0,0,1));
		if( right.lengthSq() > 0.1 ) {
			var up = right.cross(front).normalized();
			Native.set_position_orientation(id,
				camera.pos.y + front.y * camDistance,
				camera.pos.z + front.z * camDistance,
				camera.pos.x + front.x * camDistance,
				front.y, front.z, front.x,
				up.y, up.z, up.x
			);
		}
	}
	#end

	/** Needs to be called once per frame **/
	public static function update() {
		if(!initialized) return;

		dispatchCallbacks();

		for(o in objects) {
			o.update();
		}

		#if heaps
		if(camera != null)
			setCameraListenerPosition(DEFAULT_LISTENER.id, camera, cameraDistance);
		#end


		Native.render();
	}

	static function register(o: GameObject) {
		if(!initialized) return;
		Native.register_obj(o.id, o.name != null ? @:privateAccess o.name.bytes : null);
		objects.push(o);

	}
	static function unregister(o: GameObject) {
		if(!initialized) return false;
		Native.unregister_obj(o.id);

		// Remove-swap
		var i = objects.length;
		var found = false;
		while (i-- > 0) {
			if(objects[i] == o) {
				if(i == objects.length-1)
					objects.pop();
				else {
					var last = objects.pop();
					objects[i] = last;
				}
				found = true;
				break;
			}
		}
		return found;
	}
}
