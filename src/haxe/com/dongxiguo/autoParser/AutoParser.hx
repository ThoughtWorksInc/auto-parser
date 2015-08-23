package com.dongxiguo.autoParser;

import haxe.macro.Type.AbstractType;
import haxe.macro.Printer;
import haxe.macro.TypeTools;
import haxe.macro.PositionTools;
import haxe.ds.StringMap;
import haxe.macro.MacroStringTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;

class AutoParser {

  static function processName(sb:StringBuf, s:String):Void {
    var i = 0;
    while (true) {
      var prev = i;
      var found = s.indexOf("_", prev);
      if (found != -1) {
        sb.addSub(s, prev, i - prev);
        sb.add("__");
        i = found + 1;
      }
      else {
        sb.addSub(s, prev);
        break;
      }
    }
  }

  static function generatedMethodName(pack:Array<String>, name:String):String {
    var sb = new StringBuf();
    sb.add("parse_");
    for (p in pack) {
      processName(sb, p);
      sb.add("_");
    }
    processName(sb, name);
    return sb.toString();
  }

#if macro

  static function fields(includeModules:Array<String>, parserModule:String, parserName:String):Array<Field> return {
    var modulePath = MacroStringTools.toFieldExpr(parserModule.split("."));
    var className = parserName;
    var thisClassExpr = macro $modulePath.$className;
    var dataTypesByGeneratedMethodName = new StringMap<BaseType>();
    var methodArgs = [
      {
        name : "__source",
        type : null
      }
    ];

// ADT的序列化必须放在最后，因为它们需要类型推断。
    var elementParseFields:Array<Field> = [];
    var repeatParseFields:Array<Field> = [];
    var enumParseFields:Array<Field> = [];

    function hasStatic(abstractType:AbstractType, methodName:String):Bool return {
      switch abstractType {
        case { impl: null }: false;
        case { impl: _.get() => { statics: _.get() => statics }}:
          for (staticMethod in statics) {
            if (staticMethod.name == methodName) {
              return true;
            }
          }
          false;
        default:
          false;
      }
    }

    function tryAddParseMethod(type:Type):Null<String> return {
      switch Context.follow(type) {
        case TAbstract(_.get() => abstractType, _) if (abstractType.meta.has(":enum")):
          var methodName = generatedMethodName(abstractType.pack, abstractType.name);
          if (dataTypesByGeneratedMethodName.get(methodName) == null) {
            dataTypesByGeneratedMethodName.set(methodName, abstractType);
            var abstractPath = abstractType.module.split(".");
            abstractPath.push(abstractType.name);
            var abstractFieldExpr = MacroStringTools.toFieldExpr(abstractPath);
            var staticFieldExprs = [];
            if (abstractType.impl != null) {
              for (field in abstractType.impl.get().statics.get()) {
                switch field.kind {
                  case FVar(VarAccess.AccInline, VarAccess.AccNever) if (Context.unify(field.type, type)):
                    var fieldName = field.name;
                    staticFieldExprs.push(macro $abstractFieldExpr.$fieldName);
                  default:
                    continue;
                }
              }
            }
            var switchExpr = {
              pos: PositionTools.here(),
              expr: ESwitch(
                macro __current,
                [
                  {
                    values: staticFieldExprs,
                    expr: macro { __source.next(); cast __current; }
                  }
                ],
                macro null)
            }
            var abstractComplexType = TypeTools.toComplexType(type);// TODO: 展开泛型参数
            var underlyingComplexType = TypeTools.toComplexType(abstractType.type);
            elementParseFields.push({
              name : methodName,
              access: [APublic, AStatic],
              kind : FFun({
                params: [ { name: "Position" } ],
                args :
                [
                  {
                    name : "__source",
                    type : macro : com.dongxiguo.autoParser.ISource<$underlyingComplexType, Position>
                  }
                ],
                ret: macro : Null<$abstractComplexType>, // TODO: 展开泛型参数
                expr: macro return {
                var __current = __source.current;
                $switchExpr;
                }
              }),
              pos: PositionTools.here()
            });

          }
          methodName;
        case TAbstract(_.get() => abstractType, _) if (abstractType.meta.has(":rewrite")):
          var methodName = generatedMethodName(abstractType.pack, abstractType.name);
          if (dataTypesByGeneratedMethodName.get(methodName) == null) {
            dataTypesByGeneratedMethodName.set(methodName, abstractType);
            var abstractPath = abstractType.module.split(".");
            abstractPath.push(abstractType.name);
            var abstractFieldExpr = MacroStringTools.toFieldExpr(abstractPath);
            var abstractComplexType = TypeTools.toComplexType(type);// TODO: 展开泛型参数
            var impl = abstractType.impl;
            if (impl == null) {
              Context.error("@:rewrite abstract's constructor must contain a rewriteFrom method", abstractType.pos);
            }
            var statics = impl.get().statics;
            if (statics == null) {
              Context.error("@:rewrite abstract's constructor must contain a rewriteFrom method", abstractType.pos);
            }
            var rewriteFromMethod = statics.get().find(function (f) return f.name == "rewriteFrom");
            if (rewriteFromMethod == null) {
              Context.error("@:rewrite abstract's constructor must contain a rewriteFrom method", abstractType.pos);
            }
            switch Context.follow(rewriteFromMethod.type) {
              case TFun([ { t:fromType } ], _):
                var generatedFromMethodName = tryAddParseMethod(fromType);
                if (generatedFromMethodName == null) {
                  return Context.error('${TypeTools.toString(fromType)} is not supported.', rewriteFromMethod.pos);
                }

                var abstractPack = abstractType.module.split(".");
                var abstractName = abstractPack.pop();
                var abstractTypePath = {
                  pack: abstractPack,
                  name: abstractName,
                  sub: abstractType.name,
                  params: null
                };
                elementParseFields.push({
                  name : methodName,
                  access: [APublic, AStatic],
                  kind : FFun({
                    params: [ { name: "Position" } ],
                    args :
                    [
                      {
                        name : "__source",
                        type : null
                      }
                    ],
                    ret: macro : Null<$abstractComplexType>, // TODO: 展开泛型参数
                    expr: macro {
                    inline function __typeInfererForSource<Element>(__source:com.dongxiguo.autoParser.ISource<Element, Position>):Void return;
                    __typeInfererForSource(__source);
                    var __from = $thisClassExpr.$generatedFromMethodName(__source);
                    if (__from == null) {
                      return null;
                    } else {
                      return $abstractFieldExpr.rewriteFrom(__from);
                    }
                    }
                  }),
                  pos: PositionTools.here()
                });
              default:
                Context.error("@:rewrite abstract's rewriteFrom method must accept extractly one parameter", rewriteFromMethod.pos);
            }
          }
          methodName;
        case TAbstract(_.get() => abstractType, _) if (abstractType.meta.has(":repeat")):
          var methodName = generatedMethodName(abstractType.pack, abstractType.name);
          if (dataTypesByGeneratedMethodName.get(methodName) == null) {
            dataTypesByGeneratedMethodName.set(methodName, abstractType);
            var abstractComplexType = TypeTools.toComplexType(type);// TODO: 展开泛型参数
            var minRepeat:ExprOf<Int>;
            var maxRepeat:Null<ExprOf<Int>>;
            var repeatMeta = abstractType.meta.extract(":repeat")[0];
            switch repeatMeta.params {
              case null:
                Context.error("@:repeat requires one or two parameters", repeatMeta.pos);
              case [ min ]:
                minRepeat = min;
                maxRepeat = null;
              case [ min, max ]:
                minRepeat = min;
                maxRepeat = max;
              default:
                Context.error("@:repeat requires one or two parameters", repeatMeta.pos);
            }
            switch Context.follow(abstractType.type) {
              case TInst(_.get() => { module: "Array", name: "Array" }, [ elementType ]):
                var generatedElementMethodName = tryAddParseMethod(elementType);
                if (generatedElementMethodName == null) {
                  return Context.error('${TypeTools.toString(elementType)} is not supported.', abstractType.pos);
                }
                var elementComplexType = TypeTools.toComplexType(elementType);
                var whileCondition = maxRepeat == null ? macro true : macro __repeatedResult.length < $maxRepeat;
                elementParseFields.push({
                  name : methodName,
                  access: [APublic, AStatic],
                  kind : FFun({
                    params: [ { name: "Position" } ],
                    args :
                    [
                      {
                        name : "__source",
                        type : null
                      }
                    ],
                    ret: macro : Null<$abstractComplexType>, // TODO: 展开泛型参数
                    expr: macro {
                    inline function __typeInfererForSource<Element>(__source:com.dongxiguo.autoParser.ISource<Element, Position>):Void return;
                    __typeInfererForSource(__source);
                    var __repeatedResult:Array<$elementComplexType>= [];
                    while ($whileCondition) {
                    var __savedPosition = __source.position;
                    var __element = $thisClassExpr.$generatedElementMethodName(__source);
                    if (__element == null) {
                    if (__repeatedResult.length >= $minRepeat) {
                    __source.position = __savedPosition;
                    return cast __repeatedResult;
                    } else {
                    return null;
                    }
                    } else {
                    __repeatedResult.push(__element);
                    }
                    }
                    return cast __repeatedResult;
                    }
                  }),
                  pos: PositionTools.here()
                });

              default:
                Context.error("@:repeat abstract's underlying type must be Array", repeatMeta.pos);
            }
          }
          methodName;
        case TAbstract(_.get() => abstractType, _) if (hasStatic(abstractType, "accept")):
          var methodName = generatedMethodName(abstractType.pack, abstractType.name);
          if (dataTypesByGeneratedMethodName.get(methodName) == null) {
            dataTypesByGeneratedMethodName.set(methodName, abstractType);
            var abstractPath = abstractType.module.split(".");
            abstractPath.push(abstractType.name);
            var abstractFieldExpr = MacroStringTools.toFieldExpr(abstractPath);
            var abstractComplexType = TypeTools.toComplexType(type);// TODO: 展开泛型参数
            var underlyingComplexType = TypeTools.toComplexType(abstractType.type);
            elementParseFields.push({
              name : methodName,
              access: [APublic, AStatic],
              kind : FFun({
                params: [ { name: "Position" } ],
                args :
                [
                  {
                    name : "__source",
                    type : macro : com.dongxiguo.autoParser.ISource<$underlyingComplexType, Position>
                  }
                ],
                ret: macro : Null<$abstractComplexType>, // TODO: 展开泛型参数
                expr: macro return {
                var __current = __source.current;
                if (__current != null && $abstractFieldExpr.accept(__current)) {
                __source.next();
                cast __current;
                } else {
                null;
                }
                }
              }),
              pos: PositionTools.here()
            });
          }
          methodName;
        case TEnum(_.get() => enumType, _):
          var methodName = generatedMethodName(enumType.pack, enumType.name);
          if (dataTypesByGeneratedMethodName.get(methodName) == null) {
            dataTypesByGeneratedMethodName.set(methodName, enumType);
            var enumPath = enumType.module.split(".");
            enumPath.push(enumType.name);
            var enumFieldExpr = MacroStringTools.toFieldExpr(enumPath);
            var enumBodyExprs = [];
            for (name in enumType.names) {
              var constructor = enumType.constructs[name];
              switch constructor {
                case { type: TFun(args, _), name: constructorName, pos: constructorPos}:
                  var enumValueMethodName = '${methodName}_$constructorName';
                  var argsExprs = [];
                  var argsIdentExprs = [];
                  for (arg in args) {
                    var generatedArgMethodName = tryAddParseMethod(arg.t);
                    if (generatedArgMethodName == null) {
                      return Context.error('${TypeTools.toString(arg.t)} is not supported.', constructorPos);
                    }
                    var enumValueName = '__enumValue_${arg.name}';
                    argsExprs.push(if (arg.opt) {
                      macro var $enumValueName = {
                      var __savedPosition = __source.position;
                      var $enumValueName = $thisClassExpr.$generatedArgMethodName(__source);
                      if ($i {enumValueName} == null) {
                      __source.position = __savedPosition;
                      }
                      $i{enumValueName};
                    }
                    } else {
                    macro var $enumValueName = {
                    var $enumValueName = $thisClassExpr.$generatedArgMethodName(__source);
                    if ($i{enumValueName} == null) {
                    return null;
                    } else {
                    $i{enumValueName};
                    }
                    }
                    });
                    argsIdentExprs.push(macro $i{enumValueName});
                  }
                  argsExprs.push(macro $enumFieldExpr.$constructorName($a{argsIdentExprs}));
                  enumParseFields.push({
                    name: enumValueMethodName,
                    access: [APublic, AStatic],
                    kind : FFun({
                      params: [ { name: "Position" } ],
                      args :
                      [
                        {
                          name : "__source",
                          type : null
                        }
                      ],
                      ret: TypeTools.toComplexType(type), // TODO: 展开泛型参数
                      expr: macro return {
                      inline function __typeInfererForSource<Element>(__source:com.dongxiguo.autoParser.ISource<Element, Position>):Void return;
                      __typeInfererForSource(__source);
                      {$a{argsExprs}}
                      }
                    }),
                    pos: PositionTools.here()
                  });
                  enumBodyExprs.push(macro {
                  var __savedPosition = __source.position;
                  var __enumValue = $thisClassExpr.$enumValueMethodName(__source);
                  if (__enumValue == null) {
                  __source.position = __savedPosition;
                  } else {
                  return __enumValue;
                  }
                  });
                default: continue; // TODO: 不支持没有参数的枚举值
              }
            }
            enumBodyExprs.push(macro null);

            enumParseFields.push({
              name : methodName,
              access: [APublic, AStatic],
              kind : FFun({
                params: [ { name: "Position" } ],
                args :
                [
                  {
                    name : "__source",
                    type : null
                  }
                ],
                ret: TypeTools.toComplexType(type), // TODO: 展开泛型参数
                expr: macro return {
                inline function __typeInfererForSource<Element>(__source:com.dongxiguo.autoParser.ISource<Element, Position>):Void return;
                __typeInfererForSource(__source);
                {$a{enumBodyExprs}}
                }
              }),
              pos: PositionTools.here()
            });
          }
          methodName;
        default:
          null;
      }
    }

    for (moduleName in includeModules) {
      for (rootType in Context.getModule(moduleName)) {
        tryAddParseMethod(rootType);
      }
    }

    var fields = [];
    for (f in elementParseFields) { fields.push(f); }
    for (f in repeatParseFields) { fields.push(f); }
    for (f in enumParseFields) { fields.push(f); }
//    var t = macro class BuildingParser {}
//    t.fields = fields;
//    trace(new Printer().printTypeDefinition(t));
    fields;
  }
#end
  @:noUsing
  public macro static function defineParser(includeModules:Array<String>, parserModule:String, ?parserName:String):Void {
    var parserPackage = parserModule.split(".");
    var moduleName = parserPackage.pop();
    Context.defineModule(
      parserModule,
      [
        {
          pack: parserPackage,
          name: parserName == null ? moduleName : parserName,
          pos: PositionTools.here(),
          params: null,
          meta: null,
          kind: TDClass(null, [], false),
          isExtern: false,
          fields: fields(includeModules, parserModule, parserName == null ? moduleName : parserName)
        }
      ]);
  }



  @:noUsing
  public macro static function generate(includeModules:Array<String>):Array<Field> return {
    var localClass = Context.getLocalClass().get();
    Context.getBuildFields().concat(fields(includeModules, localClass.module, localClass.name));
  }
}
