enablePlugins(AllHaxePlugins)

organization := "com.dongxiguo"

name := "auto-parser"

libraryDependencies ++= Seq("com.qifun.sbt-haxe" %% "test-interface" % "0.1.1" % Test)

libraryDependencies += "com.thoughtworks.microbuilder" % "hamu" % "0.2.0" % HaxeJava classifier "haxe-java"

haxelibDependencies += "hamu" -> DependencyVersion.SpecificVersion("0.2.0")

for (c <- Seq(Compile, Test)) yield {
  haxeOptions in c += (baseDirectory.value / "build.hxml").getAbsolutePath
}

for (c <- AllTestTargetConfigurations) yield {
  haxeMacros in c += raw"""
    com.dongxiguo.autoParser.AutoParser.BUILDER.defineClass(
      [ "com.dongxiguo.autoParser.UriTemplateLevel1" ],
      "com.dongxiguo.autoParser.MacroParser")
  """
}

developers := List(
  Developer(
    "Atry",
    "杨博 (Yang Bo)",
    "pop.atry@gmail.com",
    url("https://github.com/Atry")
  ),
  Developer(
    "wzhao0928",
    "赵文博 (Zhao Wenbo)",
    "wbzhao@thoughtworks.com",
    url("https://github.com/wzhao0928")
  )
)

haxelibContributors := Seq("Atry")

haxelibReleaseNote := "Initial release"

haxelibTags ++= Seq(
  "cross", "cpp", "cs", "flash", "java", "javascript", "js", "neko", "php", "python", "nme",
  "macro", "parser", "lexer", "parser-combinator", "sde"
)

startYear := Some(2015)

autoScalaLibrary := false

crossPaths := false

homepage := Some(url(s"https://github.com/ThoughtWorksInc/${name.value}"))

releasePublishArtifactsAction := PgpKeys.publishSigned.value

import ReleaseTransformations._

releaseProcess := Seq[ReleaseStep](
  checkSnapshotDependencies,
  inquireVersions,
  runClean,
  runTest,
  setReleaseVersion,
  commitReleaseVersion,
  tagRelease,
  publishArtifacts,
  releaseStepTask(publish in Haxe),
  setNextVersion,
  commitNextVersion,
  releaseStepCommand("sonatypeRelease"),
  pushChanges
)

releaseUseGlobalVersion := false

scmInfo := Some(ScmInfo(
  url(s"https://github.com/ThoughtWorksInc/${name.value}"),
  s"scm:git:git://github.com/ThoughtWorksInc/${name.value}.git",
  Some(s"scm:git:git@github.com:ThoughtWorksInc/${name.value}.git")))

licenses += "MIT" -> url("https://opensource.org/licenses/MIT")
