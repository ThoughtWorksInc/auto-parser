package com.dongxiguo.autoParser;

abstract Literal(Int) {
  public static inline function accept(c:Int):Bool return switch (c) {
    case "/".code : true;
    case c if (c >= "a".code && c <= "z".code): true;
    case c if (c >= "A".code && c <= "Z".code): true;
    case c if (c >= "0".code && c <= "9".code): true;
    default: false;
  }
}

@:repeat(1)
abstract Literals(Array<Literal>) {}

@:enum
abstract ExpressionBegin(Int) {
  var EXPRESSSION_BEGIN = "{".code;
}

@:enum
abstract ExpressionEnd(Int) {
  var EXPRESSSION_BEGIN = "}".code;
}

@:rewrite
abstract Variable(Literals) {
  public static function rewriteFrom(value:Expression):Variable return {
    cast switch value {
      case EXPRESSION(_, variable, _): variable;
    }
  }
}

enum Expression {
  EXPRESSION(begin:ExpressionBegin, variable:Literals, end:ExpressionEnd);
}

enum LiteralOrExpression {
  LITERALS(literals:Literals);
  Variable(variable:Variable);
}

@:repeat(1)
abstract UriTemplateLevel1(Array<LiteralOrExpression>) {}