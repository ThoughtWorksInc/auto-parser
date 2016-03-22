package autoParser;

import haxe.unit.TestRunner;
import autoParser.UriTemplateLevel1ParserTest;
import haxe.ds.Vector;

class Main {

  public static function main(arguments:Vector<String>) {
    var runner = new TestRunner();
    runner.add(new AutoParserTest());
    runner.add(new UriTemplateLevel1ParserTest());
    if (!runner.run()) {
      throw runner.result.toString();
    }
  }

}