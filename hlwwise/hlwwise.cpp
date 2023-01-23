#include "hlwwise.h"


#include <AK/SoundEngine/Common/AkSoundEngine.h>
#include <AK/SoundEngine/Common/AkModule.h>
#include <AK/SoundEngine/Common/AkTypes.h>
#include <AK/SoundEngine/Common/IAkStreamMgr.h>                 // Streaming Manager
#include <AK/SoundEngine/Common/AkStreamMgrModule.h>            // Streaming Manager
#include <AK/SoundEngine/Common/AkCallback.h>
#include <AK/MusicEngine/Common/AkMusicEngine.h>                // Music Engine
#include <AK/SpatialAudio/Common/AkSpatialAudio.h>              // Spatial Audio
#include <AK/Tools/Common/AkPlatformFuncs.h>                    // Thread defines
#include <AK/Comm/AkCommunication.h>
//#include <AkDefaultIOHookBlocking.h>
#include <AkDefaultIOHookDeferred.h>
#include <AK/Plugin/AkOpusDecoderFactory.h>
#include <AK/Plugin/AkVorbisDecoderFactory.h>
#include <AK/Plugin/AkSilenceSourceFactory.h>
#include <AK/Plugin/AkSoundSeedGrainSourceFactory.h>
#include <AK/Plugin/AkSoundSeedWindSourceFactory.h>
#include <AK/Plugin/AkParametricEQFXFactory.h>
#include <AK/Plugin/AkRoomVerbFXFactory.h>
#include <AK/Plugin/AkDelayFXFactory.h>
#include <AK/Plugin/AkPeakLimiterFXFactory.h>

HL_PRIM void hl_sys_print(vbyte* msg);


wchar_t* hlbytes_to_wchar(vbyte* bytes) {
	return (wchar_t*)bytes;
}


char tmp_hlbytes_to_utf8[256];
const char * hlbytes_to_utf8(vbyte* bytes) {
	wcstombs(tmp_hlbytes_to_utf8, (wchar_t*)bytes, 256);
	return tmp_hlbytes_to_utf8;
}

//CAkDefaultIOHookBlocking g_lowLevelIO;
CAkDefaultIOHookDeferred g_lowLevelIO;

HL_PRIM bool HL_NAME(init)(vbyte* basePath, bool useComm)
{
	AkMemSettings memSettings;
	AK::MemoryMgr::GetDefaultSettings(memSettings);
	if (AK::MemoryMgr::Init(&memSettings) != AK_Success) {
		return false;
	}

	AkStreamMgrSettings stmSettings;
	AK::StreamMgr::GetDefaultSettings(stmSettings);
	if (!AK::StreamMgr::Create(stmSettings)) {
		return false;
	}

	AkDeviceSettings deviceSettings;
	AK::StreamMgr::GetDefaultDeviceSettings(deviceSettings);
	deviceSettings.uSchedulerTypeFlags = AK_SCHEDULER_DEFERRED_LINED_UP;


	g_lowLevelIO.SetBasePath(hlbytes_to_wchar(basePath));
	if (g_lowLevelIO.Init(deviceSettings) != AK_Success) {
		return false;
	}

	AkInitSettings initSettings;
	AkPlatformInitSettings platformInitSettings;
	AK::SoundEngine::GetDefaultInitSettings(initSettings);
	AK::SoundEngine::GetDefaultPlatformInitSettings(platformInitSettings);
	initSettings.uCommandQueueSize = 2 * 1024 * 1024;
	platformInitSettings.threadLEngine.nPriority = 2;
	if (AK::SoundEngine::Init(&initSettings, &platformInitSettings) != AK_Success)
	{
		return false;
	}

	AkMusicSettings musicInit;
	AK::MusicEngine::GetDefaultInitSettings(musicInit);
	if (AK::MusicEngine::Init(&musicInit) != AK_Success)
	{
		return false;
	}

	if (useComm) {
		AkCommSettings commSettings;
		AK::Comm::GetDefaultInitSettings(commSettings);
		if (AK::Comm::Init(commSettings) != AK_Success) {
			return false;
		}
	}

	return true;
}
DEFINE_PRIM(_BOOL, init, _BYTES _BOOL);


HL_PRIM void HL_NAME(render)() {
	AK::SoundEngine::RenderAudio();
}
DEFINE_PRIM(_VOID, render, );

HL_PRIM void HL_NAME(terminate)() {
	AK::Comm::Term();
	AK::MusicEngine::Term();
	AK::SoundEngine::Term();
	//AK::MemoryMgr::Term();  // Causes crash

	g_lowLevelIO.Term();

	if (AK::IAkStreamMgr::Get())
		AK::IAkStreamMgr::Get()->Destroy();
}
DEFINE_PRIM(_VOID, terminate, );


HL_PRIM void HL_NAME(register_obj)(int id, vbyte* name) {
	AK::SoundEngine::RegisterGameObj(id, name != NULL ? hlbytes_to_utf8(name) : NULL);
}
DEFINE_PRIM(_VOID, register_obj, _I32 _BYTES);

HL_PRIM void HL_NAME(unregister_obj)(int id) {
	AK::SoundEngine::UnregisterGameObj(id);
}
DEFINE_PRIM(_VOID, unregister_obj, _I32);

HL_PRIM void HL_NAME(set_default_listener)(int id) {
	AkGameObjectID obj = id;
	AK::SoundEngine::SetDefaultListeners(&obj, 1);
}
DEFINE_PRIM(_VOID, set_default_listener, _I32);

HL_PRIM void HL_NAME(set_listener)(int emitterId, int listenerId) {
	AkGameObjectID emitter = emitterId;
	AkGameObjectID listener = listenerId;
	AK::SoundEngine::SetListeners(emitter, &listener, 1);
}
DEFINE_PRIM(_VOID, set_listener, _I32 _I32);

HL_PRIM bool HL_NAME(load_bank)(vbyte* name) {
	AkBankID bankID;
	hl_blocking(true);
	AKRESULT res = AK::SoundEngine::LoadBank(hlbytes_to_wchar(name), bankID);
	hl_blocking(false);
	if (res != AK_Success)
		return false;
	return true;
}
DEFINE_PRIM(_BOOL, load_bank, _BYTES);

HL_PRIM bool HL_NAME(unload_bank)(vbyte* name) {
	return AK::SoundEngine::UnloadBank(hlbytes_to_wchar(name), NULL) == AK_Success;
}
DEFINE_PRIM(_VOID, unload_bank, _BYTES);

// Callback wrapper
static void PostEventCallbackWrapper(AkCallbackType in_eType, AkCallbackInfo* data)
{
	vdynamic* ret;
	vclosure* vcallback = (vclosure*)data->pCookie;
	if (vcallback == nullptr) return;

	hl_register_thread(&ret);

	((int(*)(AkCallbackType, AkCallbackInfo*))vcallback->fun)(in_eType, data);

	hl_unregister_thread();
}

HL_PRIM int HL_NAME(post_event)(vbyte* name, int gameObject, AkCallbackType cbType, vclosure* callback) {
	return AK::SoundEngine::PostEvent(hlbytes_to_utf8(name), gameObject, cbType, PostEventCallbackWrapper, callback );
}
DEFINE_PRIM(_VOID, post_event, _BYTES _I32 _I32 _FUN(_VOID, _I32 _STRUCT));

HL_PRIM int HL_NAME(post_trigger)(vbyte* name, int gameObject) {
	return AK::SoundEngine::PostTrigger(hlbytes_to_utf8(name), gameObject);
}
DEFINE_PRIM(_VOID, post_trigger, _BYTES _I32);


HL_PRIM void HL_NAME(set_position)(int objectId, double x, double y, double z) {
	AkSoundPosition soundPos;
	soundPos.Set(x, y, z, 0, 0, 1, 0, 1, 0);
	AK::SoundEngine::SetPosition(objectId, soundPos);
}
DEFINE_PRIM(_VOID, set_position, _I32 _F64 _F64 _F64 );

HL_PRIM void HL_NAME(set_position_orientation)(int objectId,
	double x, double y, double z,
	double frontX, double frontY, double frontZ,
	double topX, double topY, double topZ) {
	AkSoundPosition soundPos;
	soundPos.Set(x, y, z, frontX, frontY, frontZ, topX, topY, topZ);
	AKRESULT res = AK::SoundEngine::SetPosition(objectId, soundPos);
	/*if (res != AK_Success)
		throw "!";*/
}
DEFINE_PRIM(_VOID, set_position_orientation, _I32 _F64 _F64 _F64 _F64 _F64 _F64 _F64 _F64 _F64);


HL_PRIM void HL_NAME(set_rtpc)(vbyte* name, double value, int object) {
	AK::SoundEngine::SetRTPCValue(hlbytes_to_wchar(name), value, object >= 0 ? object : AK_INVALID_GAME_OBJECT);
}
DEFINE_PRIM(_VOID, set_rtpc, _BYTES _F64 _I32);


HL_PRIM void HL_NAME(set_switch)(vbyte* group, vbyte* state, int object) {
	AK::SoundEngine::SetSwitch(hlbytes_to_wchar(group), hlbytes_to_wchar(state), object);
}
DEFINE_PRIM(_VOID, set_switch, _BYTES _BYTES _I32);

HL_PRIM void HL_NAME(set_state)(vbyte* group, vbyte* state) {
	AK::SoundEngine::SetState(hlbytes_to_wchar(group), hlbytes_to_wchar(state));
}
DEFINE_PRIM(_VOID, set_state, _BYTES _BYTES);

HL_PRIM void HL_NAME(stop_all)(int object) {
	AK::SoundEngine::StopAll(object);
}
DEFINE_PRIM(_VOID, stop_all, _I32);

HL_PRIM void HL_NAME(set_language)(vbyte* language) {
	AK::StreamMgr::SetCurrentLanguage(hlbytes_to_wchar(language));
}
DEFINE_PRIM(_VOID, set_language, _BYTES);


#include "AkDefaultIOHookDeferred.cpp"
//#include "AkDefaultIOHookBlocking.cpp"
#include "AkMultipleFileLocation.cpp"
