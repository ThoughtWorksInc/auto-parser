package com.dongxiguo.autoParser;

import com.dongxiguo.autoParser.AutoParserTestAst;
import haxe.unit.TestCase;

class AutoParserTest extends TestCase {

  public function testCharacter():Void {
    var text = "B";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = AutoParserTestAstParser.parse_com_dongxiguo_autoParser_CharacterB(source);
    assertEquals(CharacterB.CHARACTER, ast);
    assertEquals(null, source.current);
    assertEquals(text.length, source.position);
  }

  public function testNotAst():Void {
    var text = "BA";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = AutoParserTestAstParser.parse_com_dongxiguo_autoParser_AutoParserTestAst(source);
    assertEquals(null, ast);
    assertEquals("A".code, source.current);
    assertEquals(1, source.position);
  }

  public function testAst():Void {
    var text = "B\000A";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = AutoParserTestAstParser.parse_com_dongxiguo_autoParser_AutoParserTestAst(source);
    assertEquals(CharacterB.CHARACTER, ast.b);
    assertEquals(CharacterZero.CHARACTER, ast.zero);
    assertEquals(CharacterA.CHARACTER, ast.a);
    assertEquals(null, source.current);
    assertEquals(text.length, source.position);
  }

  public function testOptionalAst():Void {
    var text = "A";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = AutoParserTestAstParser.parse_com_dongxiguo_autoParser_OptionalAst(source);
    assertEquals(null, ast.b);
    assertEquals(CharacterA.CHARACTER, ast.a);
    assertEquals(null, source.current);
    assertEquals(text.length, source.position);
  }


  public function testOptionalAst2():Void {
    var text = "BA";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = AutoParserTestAstParser.parse_com_dongxiguo_autoParser_OptionalAst(source);
    assertEquals(CharacterB.CHARACTER, ast.b);
    assertEquals(CharacterA.CHARACTER, ast.a);
    assertEquals(null, source.current);
    assertEquals(text.length, source.position);
  }

}


@:build(hamu.ExprEvaluator.evaluate(com.dongxiguo.autoParser.AutoParser.BUILDER.build([
  "com.dongxiguo.autoParser.AutoParserTestAst"
])))
class AutoParserTestAstParser {

}

@:build(hamu.ExprEvaluator.evaluate(com.dongxiguo.autoParser.AutoFormatter.BUILDER.build([
  "com.dongxiguo.autoParser.AutoParserTestAst"
])))
class AutoParserTestAstFormatter {

}