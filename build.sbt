enablePlugins(AllHaxePlugins)

organization := "com.thoughtworks.microbuilder"

name := "auto-parser"

resolvers += "Sonatype Public" at "https://oss.sonatype.org/content/groups/public"

libraryDependencies += "com.qifun.sbt-haxe" %% "test-interface" % "0.1.1" % Test

for (c <- AllHaxeConfigurations) yield {
  libraryDependencies += "com.thoughtworks.microbuilder" % "hamu" % "1.0.0" % c classifier c.name
}

haxelibDependencies += "hamu" -> DependencyVersion.SpecificVersion("1.0.0")

for (c <- Seq(Compile, Test)) yield {
  haxeOptions in c += (baseDirectory.value / "build.hxml").getAbsolutePath
}

for (c <- AllTestTargetConfigurations) yield {
  haxeMacros in c += raw"""
    autoParser.AutoParser.BUILDER.lazyDefineClass(
      [ "autoParser.UriTemplateLevel1" ],
      "autoParser.MacroParser")
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

haxelibReleaseNote := xml.Xhtml.toXhtml(
  <ul>
    <li>Add <code>StringIterator</code></li>
    <li>Support <code>@:sequence</code></li>
  </ul>
)

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

releaseUseGlobalVersion := false

scmInfo := Some(ScmInfo(
  url(s"https://github.com/ThoughtWorksInc/${name.value}"),
  s"scm:git:git://github.com/ThoughtWorksInc/${name.value}.git",
  Some(s"scm:git:git@github.com:ThoughtWorksInc/${name.value}.git")))

licenses += "Apache" -> url("http://www.apache.org/licenses/LICENSE-2.0")

releaseProcess := {
  releaseProcess.value.patch(releaseProcess.value.indexOf(publishArtifacts), Seq[ReleaseStep](releaseStepTask(publish in Haxe)), 0)
}

releaseProcess := {
  releaseProcess.value.patch(releaseProcess.value.indexOf(pushChanges), Seq[ReleaseStep](releaseStepCommand("sonatypeRelease")), 0)
}

releaseProcess -= runClean

releaseProcess -= runTest

doc in Compile <<= doc in Haxe
