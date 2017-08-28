// See LICENSE for license details.

// The Chisel projects we know we'll require.
// This could be any (or all) of the BIG4 projects
val chiselDeps = chisel.dependencies(Seq(
    ("edu.berkeley.cs" %% "firrtl" % "1.1-SNAPSHOT", "firrtl"),
    ("edu.berkeley.cs" %% "firrtl-interpreter" % "1.1-SNAPSHOT", "firrtl-interpreter"),
    ("edu.berkeley.cs" %% "chisel3" % "3.1-SNAPSHOT", "chisel3"),
    ("edu.berkeley.cs" %% "chisel-iotesters" % "1.2-SNAPSHOT", "chisel-testers")
))
lazy val chisel_release = (project in file (".")).
  settings(
    publishLocal := {},
    publish := {},
    packagedArtifacts := Map.empty
  ).
  aggregate(chiselDeps.projects: _*)

publishArtifact in chisel_release := false

publish in chisel_release := {}
