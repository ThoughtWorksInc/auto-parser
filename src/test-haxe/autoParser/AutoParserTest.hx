package autoParser;

import autoParser.AutoParserTestAst;
import haxe.unit.TestCase;

using autoParser.util.StringIterator;
class AutoParserTest extends TestCase {

  public function testCharacter():Void {
    var text = "B";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = AutoParserTestAstParser.parse_autoParser_CharacterB(source);
    assertEquals(CharacterB.CHARACTER, ast);
    assertEquals(null, source.current);
    assertEquals(text.length, source.position);
  }

  public function testNotAst():Void {
    var text = "BA";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = AutoParserTestAstParser.parse_autoParser_AutoParserTestAst(source);
    assertEquals(null, ast);
    assertEquals("A".code, source.current);
    assertEquals(1, source.position);
  }

  public function testAst():Void {
    var text = "B\000A";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = AutoParserTestAstParser.parse_autoParser_AutoParserTestAst(source);
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
    var ast = AutoParserTestAstParser.parse_autoParser_OptionalAst(source);
    assertEquals(null, ast.b);
    assertEquals(CharacterA.CHARACTER, ast.a);
    assertEquals(null, source.current);
    assertEquals(text.length, source.position);
  }


  public function testOptionalAst2():Void {
    var text = "BA";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = AutoParserTestAstParser.parse_autoParser_OptionalAst(source);
    assertEquals(CharacterB.CHARACTER, ast.b);
    assertEquals(CharacterA.CHARACTER, ast.a);
    assertEquals(null, source.current);
    assertEquals(text.length, source.position);
  }

  public function testOptionalSequence():Void {
    var text = "BANDA";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = AutoParserTestAstParser.parse_autoParser_OptionalAst(source);
    assertEquals(CharacterB.CHARACTER, ast.b);
    assertEquals(CharacterA.CHARACTER, ast.a);
    assertEquals(null, source.current);
    assertEquals(text.length, source.position);
    assertEquals(KeyWord.AND, ast.keyWord);

    var buffer = new StringBuffer();
    AutoParserTestAstFormatter.format_autoParser_OptionalAst(buffer, ast);
    assertEquals(text, buffer.toString());
  }

}


@:build(hamu.ExprEvaluator.evaluate(autoParser.AutoParser.BUILDER.build([
  "autoParser.AutoParserTestAst"
])))
class AutoParserTestAstParser {

}

@:build(hamu.ExprEvaluator.evaluate(autoParser.AutoFormatter.BUILDER.build([
  "autoParser.AutoParserTestAst"
])))
class AutoParserTestAstFormatter {

}