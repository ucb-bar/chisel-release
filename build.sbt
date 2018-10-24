// See LICENSE for license details.

//enablePlugins(SiteScaladocPlugin)

//enablePlugins(GhpagesPlugin)

def scalacOptionsVersion(scalaVersion: String): Seq[String] = {
  Seq() ++ {
    // If we're building with Scala > 2.11, enable the compile option
    //  switch to support our anonymous Bundle definitions:
    //  https://github.com/scala/bug/issues/10047
    CrossVersion.partialVersion(scalaVersion) match {
      case Some((2, scalaMajor: Long)) if scalaMajor < 12 => Seq()
      case _ => Seq("-Xsource:2.11")
    }
  }
}

def javacOptionsVersion(scalaVersion: String): Seq[String] = {
  Seq() ++ {
    // Scala 2.12 requires Java 8. We continue to generate
    //  Java 7 compatible code for Scala 2.11
    //  for compatibility with old clients.
    CrossVersion.partialVersion(scalaVersion) match {
      case Some((2, scalaMajor: Long)) if scalaMajor < 12 =>
        Seq("-source", "1.7", "-target", "1.7")
      case _ =>
        Seq("-source", "1.8", "-target", "1.8")
    }
  }
}

scalaVersion := "2.12.6"

crossScalaVersions := Seq("2.11.12", "2.12.6")

scalacOptions := Seq("-deprecation", "-feature") ++ scalacOptionsVersion(scalaVersion.value)

javacOptions ++= javacOptionsVersion(scalaVersion.value)

lazy val commonSettings = Seq (
  organization := "edu.berkeley.cs",

  resolvers ++= Seq(
    Resolver.sonatypeRepo("snapshots"),
    Resolver.sonatypeRepo("releases")
  ),

  // Shouldn't sbt-coverage do this?
  // If we don't, we get:
  coverageEnabled := (coverageEnabled in ThisBuild).value
)

lazy val publishSettings = Seq (
  publishMavenStyle := true,
  publishArtifact in Test := false,
  pomIncludeRepository := { x => false },

  publishTo := {
    val v = version.value
    val nexus = "https://oss.sonatype.org/"
    if (v.trim.endsWith("SNAPSHOT")) {
      Some("snapshots" at nexus + "content/repositories/snapshots")
    }
    else {
      Some("releases" at nexus + "service/local/staging/deploy/maven2")
    }
  }
)

lazy val chisel = (project in file("chisel3")).
  settings(commonSettings: _*).
  settings(publishSettings: _*).
  dependsOn(firrtl)

lazy val chisel_testers = (project in file("chisel-testers")).
  settings(commonSettings: _*).
  settings(publishSettings: _*).
  dependsOn(chisel, firrtl, firrtl_interpreter, treadle)

lazy val firrtl = (project in file("firrtl")).
  settings(commonSettings: _*).
  settings(publishSettings: _*)

lazy val firrtl_interpreter = (project in file("firrtl-interpreter")).
  settings(commonSettings: _*).
  settings(publishSettings: _*).
  dependsOn(firrtl)

lazy val treadle = (project in file("treadle")).
  settings(commonSettings: _*).
  settings(publishSettings: _*).
  dependsOn(firrtl)

lazy val rocket = (project in file("rocket-chip")).
  settings(commonSettings: _*).
  settings(publishSettings: _*).
  dependsOn(chisel)

lazy val chisel_release = (project in file (".")).
  settings(commonSettings: _*).
  settings(
    publishLocal := {},
    publish := {},
    publishArtifact := false,
    packagedArtifacts := Map.empty
  ).
  dependsOn(firrtl).
  aggregate(firrtl, chisel, firrtl_interpreter, treadle, chisel_testers, rocket)

buildInfoUsePackageAsPath := true
