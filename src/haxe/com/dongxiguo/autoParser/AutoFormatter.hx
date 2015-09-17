package com.dongxiguo.autoParser;

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


class AutoFormatter {

  static function generatedMethodName(pack:Array<String>, name:String):String {
    var sb = new StringBuf();
    sb.add("format_");
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
    var repeatedFields:Array<Field> = [];
    var complexFields:Array<Field> = [];
    
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
                    macro {
                      var __fieldValue = __ast.$fieldName;
                      inline function nullable<A>(a:Null<A>):Null<A> return a;
                      if (nullable(__ast.$fieldName = __fieldValue) != null) {
                        $thisClassExpr.$generatedArgMethodName(__buffer, __fieldValue);
                      }
                    }
                  } else {
                    macro {
                      var __fieldValue = __ast.$fieldName;
                      inline function nullable<A>(a:Null<A>):Null<A> return a;
                      $thisClassExpr.$generatedArgMethodName(__buffer, __fieldValue);
                    }
                  });
                default:
                  continue;
              }
            }

            complexFields.push({
              name: methodName,
              access: [APublic, AStatic],
              kind : FFun({
                params: [],
                args :
                [
                  {
                    name : "__buffer",
                    type : null
                  },
                  {
                    name: "__ast",
                    type: TypeTools.toComplexType(type) // TODO: 展开泛型参数
                  }
                ],
                ret: macro : Void,
                expr: macro return {
                  inline function __typeInfererForBuffer<Element>(__buffer:com.dongxiguo.autoParser.IBuffer<Element>):Void return;
                  __typeInfererForBuffer(__buffer);
                  {$a{parseExprs}}
                }
              }),
              pos: PositionTools.here()
            });
          }
          methodName;
        case TAbstract(_.get() => abstractType, _) if (abstractType.meta.has(":enum") || abstractType.meta.has(":atom")):
          var methodName = generatedMethodName(abstractType.pack, abstractType.name);
          if (dataTypesByGeneratedMethodName.get(methodName) == null) {
            dataTypesByGeneratedMethodName.set(methodName, abstractType);
            var abstractComplexType = TypeTools.toComplexType(type);// TODO: 展开泛型参数
            var underlyingComplexType = TypeTools.toComplexType(abstractType.type);
            atomFields.push({
              name : methodName,
              access: [APublic, AStatic],
              kind : FFun({
                params: [],
                args :
                [
                  {
                    name : "__buffer",
                    type : null
                  },
                  {
                    name: "__ast",
                    type: TypeTools.toComplexType(type) // TODO: 展开泛型参数
                  }
                ],
                ret: macro : Void,
                expr: macro return {
                  inline function __typeInfererForBuffer<Element>(__buffer:com.dongxiguo.autoParser.IBuffer<Element>):Void return;
                  __typeInfererForBuffer(__buffer);
                  var __enumValue: $underlyingComplexType = cast __ast;
                  __buffer.append(__enumValue);
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
              Context.error("@:rewrite abstract's constructor must contain a rewriteTo method", abstractType.pos);
            }
            var statics = impl.get().statics;
            if (statics == null) {
              Context.error("@:rewrite abstract's constructor must contain a rewriteTo method", abstractType.pos);
            }
            var rewriteToMethod = statics.get().find(function (f) return f.name == "rewriteTo");
            if (rewriteToMethod == null) {
              Context.error("@:rewrite abstract's constructor must contain a rewriteTo method", abstractType.pos);
            }
            switch Context.follow(rewriteToMethod.type) {
              case TFun(_, toType):
                var generatedToMethodName = tryAddMethod(toType);
                if (generatedToMethodName == null) {
                  return Context.error('${TypeTools.toString(toType)} is not supported.', rewriteToMethod.pos);
                }
                atomFields.push({
                  name : methodName,
                  access: [APublic, AStatic],
                  kind : FFun({
                    params: [],
                    args :
                    [
                      {
                        name : "__buffer",
                        type : null
                      },
                      {
                        name: "__ast",
                        type: TypeTools.toComplexType(type) // TODO: 展开泛型参数
                      }
                    ],
                    ret: macro : Void,
                    expr: macro {
                      inline function __typeInfererForBuffer<Element>(__buffer:com.dongxiguo.autoParser.IBuffer<Element>):Void return;
                      __typeInfererForBuffer(__buffer);
                      var __to = $abstractFieldExpr.rewriteTo(cast __ast);
                      if (__to != null) {
                         $thisClassExpr.$generatedToMethodName(__buffer, cast __to);
                      }
                    }
                  }),
                  pos: PositionTools.here()
                });
              default:
                Context.error("@:rewrite abstract's rewriteTo method must accept extractly one parameter", rewriteToMethod.pos);
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
                    params: [],
                    args :
                    [
                      {
                        name : "__buffer",
                        type : null
                      },
                      {
                        name: "__ast",
                        type: TypeTools.toComplexType(type) // TODO: 展开泛型参数
                      }
                    ],
                    ret: macro : Void,
                    expr: macro {
                      inline function __typeInfererForBuffer<Element>(__buffer:com.dongxiguo.autoParser.IBuffer<Element>):Void return;
                      __typeInfererForBuffer(__buffer);
                      var __repeatedResult:Array<$elementComplexType>= cast __ast;
                      for (__element in __repeatedResult) {
                        $thisClassExpr.$generatedElementMethodName(__buffer, __element);
                      }
                    }
                  }),
                  pos: PositionTools.here()
                });

              default:
                Context.error("@:repeat abstract's underlying type must be Array", repeatMeta.pos);
            }
          }
          methodName;
        case TEnum(_.get() => enumType, _):
          var methodName = generatedMethodName(enumType.pack, enumType.name);
          if (dataTypesByGeneratedMethodName.get(methodName) == null) {
            dataTypesByGeneratedMethodName.set(methodName, enumType);
            var enumPath = enumType.module.split(".");
            enumPath.push(enumType.name);
            var enumFieldExpr = MacroStringTools.toFieldExpr(enumPath);
            var cases = [];
            for (name in enumType.names) {
              var constructor = enumType.constructs[name];
              switch constructor {
                case { type: TFun(args, _), name: constructorName, pos: constructorPos}:
                  var enumValueMethodName = '${methodName}_$constructorName';
                  var argsIdentExprs = [];
                  var bodyExprs = [];
                  for (arg in args) {
                    var generatedArgMethodName = tryAddMethod(arg.t);
                    if (generatedArgMethodName == null) {
                      return Context.error('${TypeTools.toString(arg.t)} is not supported.', constructorPos);
                    }
                    var enumValueName = '__enumValue_${arg.name}';
                    argsIdentExprs.push(macro $i{enumValueName});
                    bodyExprs.push(macro if ({
                      inline function nullable<A>(a:Null<A>):Null<A> return a;
                      nullable($i{enumValueName}) != null;
                    }) {
                      $thisClassExpr.$generatedArgMethodName(__buffer, $i{enumValueName});
                    });
                  }
                  cases.push({
                    values: [ macro $enumFieldExpr.$constructorName($a{argsIdentExprs}) ],
                    expr: macro {$a{bodyExprs}}
                  });
                default: continue; // TODO: 不支持没有参数的枚举值
              }
            }
            var switchExpr = {
              pos: PositionTools.here(),
              expr: ESwitch(macro __ast, cases, macro null)
            }

            complexFields.push({
              name : methodName,
              access: [APublic, AStatic],
              kind : FFun({
                params: [],
                args :
                [
                  {
                    name : "__buffer",
                    type : null
                  },
                  {
                    name: "__ast",
                    type: TypeTools.toComplexType(type) // TODO: 展开泛型参数
                  }
                ],
                ret: macro : Void,
                expr: macro return {
                  inline function __typeInfererForBuffer<Element>(__buffer:com.dongxiguo.autoParser.IBuffer<Element>):Void return;
                  __typeInfererForBuffer(__buffer);
                  $switchExpr;
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
    for (f in atomFields) { fields.push(f); }
    for (f in repeatedFields) { fields.push(f); }
    for (f in complexFields) { fields.push(f); }
//    var t = macro class BuildingParser {}
//    t.fields = fields;
//    trace(new Printer().printTypeDefinition(t));
    fields;
  }

  public static var BUILDER(default, never) = new Builder<Array<String>>(AutoFormatter);

#end

}

