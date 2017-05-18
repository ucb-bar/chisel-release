// See LICENSE for license details.

import chiselBuild.ChiselDependencies

site.settings

lazy val chisel_release = (project in file (".")).
  settings(
    publishLocal := {},
    publish := {},
    packagedArtifacts := Map.empty
  ).
  aggregate(ChiselDependencies.packageProjectsMap.values.toSeq: _*)

publishArtifact in chisel_release := false

publish in chisel_release := {}
