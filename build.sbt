import scala.util.parsing.json.JSONFormat

organization := "com.dongxiguo"

name := "auto-parser"

libraryDependencies ++= Seq("com.qifun.sbt-haxe" %% "test-interface" % "0.1.1" % Test)

for (c <- Seq(Compile, Test)) yield {
  haxeOptions in c += (baseDirectory.value / "build.hxml").getAbsolutePath
}

haxeMacros in Test += raw"""
  com.dongxiguo.autoParser.AutoParser.BUILDER.defineClass(
    [ "com.dongxiguo.autoParser.UriTemplateLevel1" ],
    "com.dongxiguo.autoParser.MacroParser")
"""