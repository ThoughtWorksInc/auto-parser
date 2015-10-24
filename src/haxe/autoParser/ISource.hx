package autoParser;

@:nativeGen
interface ISource<Element, Position> {

  var current(get, never):Null<Element>;

  function get_current():Null<Element>;

  function next():Void;

  var position(get, set):Position;

  function get_position():Position;

  function set_position(value:Position):Position;

}
