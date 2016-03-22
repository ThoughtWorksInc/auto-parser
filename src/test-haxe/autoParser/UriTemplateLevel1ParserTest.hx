package autoParser;

import haxe.unit.TestCase;

class UriTemplateLevel1ParserTest extends TestCase {

  public function test1():Void {
    var text = "/prefix/123/456/";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = UriTemplateLevel1Parser.parse_autoParser_Literal(source);
    assertEquals("47", Std.string(ast));
    var buffer = new StringBuffer();
    UriTemplateLevel1Formatter.format_autoParser_Literal(buffer, ast);
    assertEquals("/", buffer.toString());
  }

  public function test2():Void {
    var text = "/prefix/123/456/";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = UriTemplateLevel1Parser.parse_autoParser_Literals(source);
    assertEquals("[47,112,114,101,102,105,120,47,49,50,51,47,52,53,54,47]", Std.string(ast));
    var buffer = new StringBuffer();
    UriTemplateLevel1Formatter.format_autoParser_Literals(buffer, ast);
    assertEquals(text, buffer.toString());
  }

  public function test3():Void {
    var text = "/prefix/123/456/";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = UriTemplateLevel1Parser.parse_autoParser_LiteralOrExpression(source);
    assertEquals("LITERALS([47,112,114,101,102,105,120,47,49,50,51,47,52,53,54,47])", Std.string(ast));
    var buffer = new StringBuffer();
    UriTemplateLevel1Formatter.format_autoParser_LiteralOrExpression(buffer, ast);
    assertEquals(text, buffer.toString());
  }

  public function test4():Void {
    var text = "{category}";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = UriTemplateLevel1Parser.parse_autoParser_LiteralOrExpression(source);
    assertEquals("VARIABLE([99,97,116,101,103,111,114,121])", Std.string(ast));
    var buffer = new StringBuffer();
    UriTemplateLevel1Formatter.format_autoParser_LiteralOrExpression(buffer, ast);
    assertEquals(text, buffer.toString());
  }

  public function test5():Void {
    var text = "/prefix/{category}/{userId}";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = UriTemplateLevel1Parser.parse_autoParser_UriTemplateLevel1(source);
    assertEquals("[LITERALS([47,112,114,101,102,105,120,47]),VARIABLE([99,97,116,101,103,111,114,121]),LITERALS([47]),VARIABLE([117,115,101,114,73,100])]", Std.string(ast));
    var buffer = new StringBuffer();
    UriTemplateLevel1Formatter.format_autoParser_UriTemplateLevel1(buffer, ast);
    assertEquals(text, buffer.toString());
  }

  public function testDefine():Void {
    var text = "/prefix/{category}/{userId}";
    trace('Parsing $text...');
    var source = new StringSource(text);
    var ast = MacroParser.parse_autoParser_UriTemplateLevel1(source);
    assertEquals("[LITERALS([47,112,114,101,102,105,120,47]),VARIABLE([99,97,116,101,103,111,114,121]),LITERALS([47]),VARIABLE([117,115,101,114,73,100])]", Std.string(ast));
  }

}

@:build(hamu.ExprEvaluator.evaluate(autoParser.AutoFormatter.BUILDER.build([
  "autoParser.UriTemplateLevel1"
])))
class UriTemplateLevel1Formatter {}

@:build(hamu.ExprEvaluator.evaluate(autoParser.AutoParser.BUILDER.build([
  "autoParser.UriTemplateLevel1"
])))
class UriTemplateLevel1Parser {}