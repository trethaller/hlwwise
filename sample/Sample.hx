import wwise.Api as Wwise;

class Sample extends hxd.App {

    var obj : h3d.scene.Object;
    var time = 0.0;

    override function init() {
        obj = new h3d.scene.Box(s3d);
        new h3d.scene.CameraController(10, s3d);

        Wwise.init("data", true);
        Wwise.loadBank("UI");

        // Auto-follow camera
        Wwise.setCamera(s3d.camera);

        // Post event on game object
        var wobj = new wwise.Api.GameObject("Test Object");
        wobj.postEvent(wwise.Api.Event.GameEndLose);

        // Hook-up Wwise object on heaps object
        wobj.follow = obj.getAbsPos();

        // Play global events
        Wwise.postEvent(wwise.Api.Event.GameEndLose);

        // Without using macro-generated IDs, events can be created from string:
        // Wwise.postEvent(wwise.Api.Event.make("Game_End_Lose"));
    }

    override function update(dt: Float) {
        obj.setPosition(Math.sin(time) * 10, Math.cos(time) * 10, 0);
        time += dt;
        Wwise.update();
    }

    static function main() {
        new Sample();
    }
}