// See LICENSE for license details.

ChiselProjectDependenciesPlugin.chiselProjectSettings

buildInfoUsePackageAsPath := true
//enablePlugins(GhpagesPlugin)

scalaVersion := "2.11.12"

crossScalaVersions := Seq("2.11.12", "2.12.4")

// Provide a managed dependency on X if -DXVersion="" is supplied on the command line.
val defaultVersions = Map(
  "firrtl" -> "1.1-SNAPSHOT",
  "firrtl-interpreter" -> "1.1-SNAPSHOT",
  "chisel3" -> "3.1-SNAPSHOT",
  "chisel-iotesters" -> "1.2-SNAPSHOT",
  "dsptools" -> "1.1-SNAPSHOT"
)

def chiselVersion(proj: String): String = {
  sys.props.getOrElse(proj + "Version", defaultVersions(proj))
}

// The Chisel projects we know we'll require.
// This could be any (or all) of the BIG4 projects
val chiselDeps = chisel.dependencies(Seq(
    ("edu.berkeley.cs" %% "firrtl" % chiselVersion("firrtl"), "firrtl"),
    ("edu.berkeley.cs" %% "firrtl-interpreter" % chiselVersion("firrtl-interpreter"), "firrtl-interpreter"),
    ("edu.berkeley.cs" %% "chisel3" % chiselVersion("chisel3"), "chisel3"),
    ("edu.berkeley.cs" %% "chisel-iotesters" % chiselVersion("chisel-iotesters"), "chisel-testers"),
    ("edu.berkeley.cs" %% "dsptools" % chiselVersion("dsptools"), "dsptools")
))

lazy val chisel_release = (project in file (".")).
  settings(
    publishLocal := {},
    publish := {},
    publishArtifact := false,
    packagedArtifacts := Map.empty
  ).
  aggregate(chiselDeps.projects: _*)

// Shouldn't sbt-coverage do this?
// If we don't, we get:
//  [warn] No coverage data, skipping reports
chiselDeps.projects map { proj =>
  coverageEnabled in proj := (coverageEnabled in ThisBuild).value
}
