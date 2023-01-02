package wwise;

import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.Tools;

class Macros {

	#if macro

	public static dynamic function normalizeName(id: String) {
		var toks = id.split("_");
		return [for(t in toks) t.charAt(0) + t.toLowerCase().substr(1)].join("");
	}

	public static function buildTypes() {
		var pos = Context.currentPos();
		var r = Context.definedValue("wwiseIDs");
		var path = null;
		if( r != null ) {
			r = r.split("\\").join("/");
			try path = Context.resolvePath(r) catch( e : Dynamic ) null;
		}
		if( path == null )
			Context.error("Could not load " + r, pos);

		var types = new Array<haxe.macro.Expr.TypeDefinition>();
		var curMod = Context.getLocalModule().split(".");
		var modName = curMod.pop();

		var ids = readIDs(path);

		function buildEnum(ename: String, srcName: String) {
			var list = ids.get(srcName);
			var fields : Array<haxe.macro.Expr.Field> = [];
			var tstring = macro : String;
			var allids = [];
			var idmap = new Map<String, Bool>();

			if(list != null) {
				for(id in list) {
					if(idmap.exists(id))
						continue;
					idmap.set(id, true);
					var name = normalizeName(id);
					allids.push(macro $v{name} => $v{id});
					fields.push({
						name : name,
						pos : pos,
						kind : FVar(null, macro $v{id} )
					});
				}
			}

			fields.push( {
				name : "make",
				pos : pos,
				kind : FFun({
					args : [ { name : "v", type : tstring } ],
					ret : ename.toComplex(),
					expr : macro return cast v,
				}),
				access : [APublic, AStatic, AInline],
			});
			fields.push( {
				name : "name",
				pos : pos,
				kind : FFun( {
					args : [],
					ret : macro: hl.Bytes,
					expr : macro return @:privateAccess (this : String).bytes,
				}),
				access : [APublic, AInline],
			});
			fields.push( {
				name : "MAP",
				pos : pos,
				kind : FVar(null, macro $a{allids}),
				access : [APublic, AStatic],
			});
			types.push({
				pos : pos,
				name : ename,
				pack : curMod,
				kind : TDAbstract(tstring),
				meta : [{ name : ":enum", pos : pos },{ name : ":fakeEnum", pos : pos }],
				fields : fields,
			});
		}

		buildEnum("Event", "EVENTS");
		buildEnum("Param", "GAME_PARAMETERS");
		buildEnum("Trigger", "TRIGGERS");
		buildEnum("SwitchGroup", "SWITCHES_GROUPS");
		buildEnum("Switch", "SWITCHES_VALUES");
		buildEnum("StateGroup", "STATES_GROUPS");
		buildEnum("State", "STATES_VALUES");

		var mpath = Context.getLocalModule();
		Context.defineModule(mpath, types);
		Context.registerModuleDependency(mpath, path);

		return macro : Void;
	}

	static function typeDecl(t: ComplexType) : Expr {
		switch(t) {
			case TPath(p):
				var a = p.pack.copy();
				a.push(p.name);
				return macro $p{a};
			default:
				throw "Invalid type";
				return null;
		}
	}
	#end

	static function readIDs(path: String) {
		var lines = sys.io.File.getContent(path).split("\r\n");

		var secReg = ~/^[\s]*namespace ([\w]+)$/;
		var idReg = ~/^[\s]*static const AkUniqueID (\w+)/;
		var closeReg = ~/^[\s]+}/;

		var curList : Array<String> = null;
		var ids : Map<String, Array<String>> = new Map();
		var depth : Array<String> = [];

		inline function sectionHasGroups(section: String) {
			return section == "STATES" || section == "SWITCHES";
		}

		function getList(id: String) {
			var l = ids.get(id);
			if(l == null) {
				l = [];
				ids.set(id, l);
			}
			return l;
		}

		for(line in lines) {
			if(idReg.match(line)) {
				if(curList != null)
					curList.push(idReg.matched(1));
			}
			else if(secReg.match(line)) {
				depth.push(secReg.matched(1));
				var section = secReg.matched(1);
				switch(depth.length) {
				case 2:
					if(!sectionHasGroups(section))
						curList = getList(section);
				case 3:
					getList(depth[1] + "_GROUPS").push(section);
					curList = null;
				case 4: // group values
					curList = getList(depth[1] + "_VALUES");
				}
			}
			else if(closeReg.match(line)) {
				depth.pop();
			}
		}

		return ids;
	}

	static function readBankDefs(path: String) {
		var str = sys.io.File.getContent(path);
		var json = haxe.Json.parse(str);

		var defs = {
			events : [],
			params : [],
			switches: []
		};
		var banks : Array<Dynamic> = json.SoundBanksInfo.SoundBanks;
		for(bank in banks) {
			var evts : Array<Dynamic> = bank.IncludedEvents;
			if(evts != null) {
				for(evt in evts) {
					defs.events.push(evt.Name);
				}
			}
			var ps : Array<Dynamic> = bank.GameParameters;
			if(ps != null) {
				for(p in ps)
					defs.params.push(p.Name);
			}

			var ss : Array<Dynamic> = bank.SwitchGroups;
			if(ss != null) {
				for(s in ss)
					defs.switches.push(s.Name);
			}
		}
		return defs;
	}
}
