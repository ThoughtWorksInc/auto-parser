package autoParser;

import haxe.macro.MacroType;
import haxe.macro.Type.AbstractType;
import haxe.macro.Printer;
import haxe.macro.TypeTools;
import haxe.macro.PositionTools;
import haxe.ds.StringMap;
import haxe.macro.MacroStringTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import hamu.Naming.*;
import hamu.Builder;

using Lambda;


class AutoParser {

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


  public static function fields(includeModules:Array<String>, buildingModule:String, className:String):Array<Field> return {
    var modulePath = MacroStringTools.toFieldExpr(buildingModule.split("."));
    var thisClassExpr = macro $modulePath.$className;
    var dataTypesByGeneratedMethodName = new StringMap<BaseType>();


// ADT的序列化必须放在最后，因为它们需要类型推断。
    var atomFields:Array<Field> = [];
//    var repeatedFields:Array<Field> = [];
    var complexFields:Array<Field> = [];
    var sequenceFields:Array<Field> = [];

    function tryAddMethod(type:Type):Null<String> return {
      switch Context.follow(type) {
        case TInst(_.get() => classType, _) if (classType.constructor != null && classType.constructor.get().isPublic):
          var methodName = generatedMethodName(classType.pack, classType.name);
          if (dataTypesByGeneratedMethodName.get(methodName) == null) {
            dataTypesByGeneratedMethodName.set(methodName, classType);

            var parseExprs = [];
            for (field in classType.fields.get()) {
              switch (field.kind) {
                case FVar(AccCall|AccNormal|AccInline, AccCall|AccNormal|AccInline):
                  var generatedArgMethodName = tryAddMethod(field.type);
                  var fieldName = field.name;
                  parseExprs.push(if (field.meta.has(":optional") || field.type.match(TType(_.get() => {name: "Null", module: "StdTypes"}, [_]))) {
                    macro
                    {
                      var __savedPosition = __source.position;
                      var __fieldValue = $thisClassExpr.$generatedArgMethodName(__source);
                      if (__fieldValue == null) {
                        __source.position = __savedPosition;
                      } else {
                        inline function nullable<A>(a:Null<A>):Null<A> return a;
                        if (nullable(__sequence.$fieldName = __fieldValue) == null) {
                          __source.position = __savedPosition;
                        }
                      }
                    }
                  } else {
                    macro
                    {
                      var __fieldValue = $thisClassExpr.$generatedArgMethodName(__source);
                      if (__fieldValue == null) {
                        return null;
                      } else {
                        inline function nullable<A>(a:Null<A>):Null<A> return a;
                        if (nullable(__sequence.$fieldName = __fieldValue) == null) {
                          return null;
                        }
                      }
                    }
                  });
                default:
                  continue;
              }
            }
            var classPack = classType.module.split(".");
            var className = classPack.pop();
            var classTypePath = {
              pack: classPack,
              name: className,
              sub: classType.name,
              params: null
            };

            complexFields.push({
              name: methodName,
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
                inline function __typeInfererForSource<Element>(__source:autoParser.ISource<Element, Position>):Void return;
                __typeInfererForSource(__source);
                var __sequence = new $classTypePath();
                {$a{parseExprs}}
                __sequence;
                }
              }),
              pos: PositionTools.here()
            });
          }
          methodName;
        case TAbstract(_.get() => abstractType, _) if (abstractType.meta.has(":enum") && abstractType.meta.has(":sequence")):
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

            var underlyingComplexType = TypeTools.toComplexType(abstractType.type);

            function tryNext(i:Int) return {
              if (i < staticFieldExprs.length) {
                var next = tryNext(i + 1);
                var staticFieldExpr = staticFieldExprs[i];
                macro {
                  var __sequence: $underlyingComplexType = cast $staticFieldExpr;
                  for (__char in __sequence) {
                    if (__source.current != cast __char) {
                      __source.position = __savedPosition;
                      $next;
                    }
                    __source.next();
                  }
                  return $staticFieldExpr;
                }
              } else {
                macro return null;
              }
            }

            var tryAll = tryNext(0);

            var abstractComplexType = TypeTools.toComplexType(type);// TODO: 展开泛型参数
            complexFields.push({
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
                  inline function __typeInfererForSource<Element>(__source:autoParser.ISource<Element, Position>):Void return;
                  __typeInfererForSource(__source);
                  var __savedPosition = __source.position;
                  $tryAll;
                }
              }),
              pos: PositionTools.here()
            });

          }
          methodName;
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
            var cases = [];
            if (staticFieldExprs.length > 0) {
              cases.push(
                {
                  values: staticFieldExprs,
                  expr: macro { __source.next(); cast __current; }
                }
              );
            }

            var switchExpr = {
              pos: PositionTools.here(),
              expr: ESwitch(
                macro __current,
                cases,
                macro null)
            }
            var abstractComplexType = TypeTools.toComplexType(type);// TODO: 展开泛型参数
            var underlyingComplexType = TypeTools.toComplexType(abstractType.type);
            atomFields.push({
              name : methodName,
              access: [APublic, AStatic],
              kind : FFun({
                params: [ { name: "Position" } ],
                args :
                [
                  {
                    name : "__source",
                    type : macro : autoParser.ISource<$underlyingComplexType, Position>
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
                var generatedFromMethodName = tryAddMethod(fromType);
                if (generatedFromMethodName == null) {
                  return Context.error('${TypeTools.toString(fromType)} is not supported.', rewriteFromMethod.pos);
                }
                atomFields.push({
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
                    inline function __typeInfererForSource<Element>(__source:autoParser.ISource<Element, Position>):Void return;
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
                var generatedElementMethodName = tryAddMethod(elementType);
                if (generatedElementMethodName == null) {
                  return Context.error('${TypeTools.toString(elementType)} is not supported.', abstractType.pos);
                }
                var elementComplexType = TypeTools.toComplexType(elementType);
                var whileCondition = maxRepeat == null ? macro true : macro __repeatedResult.length < $maxRepeat;
                complexFields.push({
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
                    inline function __typeInfererForSource<Element>(__source:autoParser.ISource<Element, Position>):Void return;
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
        case TAbstract(_.get() => abstractType, _) if (abstractType.meta.has(":atom")):
          var methodName = generatedMethodName(abstractType.pack, abstractType.name);
          if (dataTypesByGeneratedMethodName.get(methodName) == null) {
            dataTypesByGeneratedMethodName.set(methodName, abstractType);
            var abstractPath = abstractType.module.split(".");
            abstractPath.push(abstractType.name);
            var abstractFieldExpr = MacroStringTools.toFieldExpr(abstractPath);
            var abstractComplexType = TypeTools.toComplexType(type);// TODO: 展开泛型参数
            var underlyingComplexType = TypeTools.toComplexType(abstractType.type);
            atomFields.push({
              name : methodName,
              access: [APublic, AStatic],
              kind : FFun({
                params: [ { name: "Position" } ],
                args :
                [
                  {
                    name : "__source",
                    type : macro : autoParser.ISource<$underlyingComplexType, Position>
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
                    var generatedArgMethodName = tryAddMethod(arg.t);
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
                  complexFields.push({
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
                      inline function __typeInfererForSource<Element>(__source:autoParser.ISource<Element, Position>):Void return;
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

            complexFields.push({
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
                inline function __typeInfererForSource<Element>(__source:autoParser.ISource<Element, Position>):Void return;
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
        tryAddMethod(rootType);
      }
    }

    var fields = [];
    for (f in sequenceFields) { fields.push(f); }
    for (f in atomFields) { fields.push(f); }
//    for (f in repeatedFields) { fields.push(f); }
    for (f in complexFields) { fields.push(f); }
//    var t = macro class BuildingParser {}
//    t.fields = fields;
//    trace(new Printer().printTypeDefinition(t));
    fields;
  }

  public static var BUILDER(default, never) = new Builder<Array<String>>(AutoParser);

#end

}

