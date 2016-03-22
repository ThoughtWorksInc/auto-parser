package autoParser.util;
@:final
class StringIterator {
  public static function iterator(self:String) return {
    new StringIterator(self);
  }
  var i:Int = 0;
  var s:String;
  public inline function new(s:String) {
    this.s = s;
  }

  public inline function hasNext() return {
    i < s.length;
  }

  public inline function next() return {
    s.charCodeAt(i++);
  }
}
