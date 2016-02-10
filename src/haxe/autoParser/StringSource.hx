package autoParser;

#if (!cpp)
@:nativeGen
#end
@:final
class StringSource implements ISource<Int, Int> {
  var data:String;
  var index:Int;

  public function next():Void {
    index += 1;
  }

  public function get_current():Null<Int> {
    if (index < data.length) {
      return data.charCodeAt(index);
    } else {
      return null;
    }
  }

  public var current(get, never):Null<Int>;

  public var position(get, set):Int;

  public function get_position():Dynamic {
    return index;
  }

  public function set_position(value:Int):Int {
    return this.index = value;
  }

  public function new(s:String) {
    data = s;
    index = 0;
  }

}
