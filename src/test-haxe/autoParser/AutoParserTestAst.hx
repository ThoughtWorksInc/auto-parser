package autoParser;

@:enum
@:sequence
abstract KeyWord(String) {
  var AND = "AND";
  var OR = "OR";
}

@:enum
abstract CharacterA(Int) {
  var CHARACTER = "A".code;
}
@:enum
abstract CharacterZero(Int) {
  var CHARACTER = "\000".code;
}
@:enum
abstract CharacterB(Int) {
  var CHARACTER = "B".code;
}

class AutoParserTestAst {
  public function new() {}

  public var b:CharacterB;
  public var zero:CharacterZero;
  public var a(get, set):CharacterA;

  public function get_a():CharacterA {
    return cast "A".code;
  }

  public function set_a(value:CharacterA):CharacterA return {
    value;
  }

}

class OptionalAst {
  public function new() {}

  public var b:Null<CharacterB>;

  public var keyWord:Null<KeyWord>;

  public var a(get, set):CharacterA;

  public function get_a():CharacterA {
    return cast "A".code;
  }

  public function set_a(value:CharacterA):CharacterA return {
    value;
  }

}