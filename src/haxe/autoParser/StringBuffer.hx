package autoParser;

class StringBuffer implements IBuffer<Int> {

  var underlying:StringBuf;

  public function new() {
    this.underlying = new StringBuf();
  }

  public function toString() return {
    underlying.toString();
  }

  public function append(value:Int):Void {
    underlying.addChar(value);
  }

}
