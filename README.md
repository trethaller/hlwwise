# hlwwise
Basic Wwise bindings for Hasklink.

This is an initial release of code used in production at Shiro Games. 

## Usage
Wwise events can be constructed by name: 
```haxe
var evt = wwise.Api.Event.make("Game_End_Lose");
``` 

If the generated C++ header file is exported as part of the bank generation step, it is possible to use it to generate compile-time identifiers:

```
# build.hxml
-D wwiseIDs=data/Wwise_IDs.h
``` 
Events and other objects are then available at compile-time:
```haxe
var evt = wwise.Api.Event.GameEndLose;
``` 

Naming transformations from Wwise IDs to Haxe identifiers can be modified by replacing the dynamic function `normalizeName` in Macros.hx:

```haxe
	public static dynamic function normalizeName(id: String) {
		var toks = id.split("_");
		return [for(t in toks) t.charAt(0) + t.toLowerCase().substr(1)].join("");
	}
 ```
