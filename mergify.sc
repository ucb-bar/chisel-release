#!/usr/bin/env amm

/* Generates a Mergify config YAML (to STDOUT) based on input config
 *
 * There are built-in conditions, but different CI requires different conditions
 * Listed branches should be stable branches that we want to backport to, in ascending order
 * {{{
 * conditions:
     - status-success=Travis CI - Pull Request
   branches:
     - 1.2.x
     - 1.3.x
     - 1.4.x
 * }}}
 */

import $ivy.`io.circe::circe-yaml:0.13.1`

import io.circe._
import io.circe.syntax._ // for .asJson
import io.circe.yaml.parser
import io.circe.yaml.syntax._ // for .asYaml

val mergeAction = Json.obj(
  "merge" -> Json.obj(
    "method" -> "squash".asJson,
    "strict" -> "smart".asJson,
    "strict_method" -> "merge".asJson
  )
)

def mergeToMaster(conditions: List[String]) = Json.obj(
  "name" -> "automatic squash-and-merge on CI success and review".asJson,
  "conditions" -> (conditions ++ List(
    "#approved-reviews-by>=1",
    "#changes-requested-reviews-by=0",
    "base=master",
    "label=\"Please Merge\"",
    "label!=\"DO NOT MERGE\"",
    "label!=\"bp-conflict\""
  )).asJson,
  "actions" -> mergeAction
)

val labelMergifyBackport = Json.obj(
  "name" -> "label Mergify backport PR".asJson,
  "conditions" -> List(
    """body~=This is an automated backport of pull request \#\d+ done by Mergify"""
  ).asJson,
  "actions" -> Json.obj(
    "label" -> Json.obj(
      "add" -> List("Backport").asJson
    )
  )
)

def makeBackportRule(branches: List[String]): Json = {
  Json.obj(
    "name" -> s"""backport to ${branches.mkString(", ")}""".asJson,
    "conditions" -> List("merged", "base=master", s"milestone=${branches.head}").asJson,
    "actions" -> Json.obj(
      "backport" -> Json.obj(
        "branches" -> branches.asJson,
        "ignore_conflicts" -> true.asJson,
        "label_conflicts" -> "bp-conflict".asJson
      ),
      "label" -> Json.obj(
        "add" -> List("Backported").asJson
      )
    )
  )
}

def backportMergeRule(conditions: List[String])(branch: String): Json = Json.obj(
  "name" -> s"automatic squash-and-mege of $branch backport PRs".asJson,
  "conditions" -> (conditions ++ List(
    "#changes-requested-reviews-by=0",
    s"base=$branch",
    "label=\"Backport\"",
    "label!=\"DO NOT MERGE\"",
    "label!=\"bp-conflict\""
  )).asJson,
  "actions" -> mergeAction
)


def error(msg: String) = throw new Exception(msg) with scala.util.control.NoStackTrace

def processTemplate(path: os.Path): (List[String], List[String]) = {
  val contents = os.read(path)
  val parsed = parser.parse(contents)
                     .getOrElse(error(s"Invalid YAML $path"))

  val cursor: HCursor = parsed.hcursor

  val conditions = cursor.downField("conditions")
                         .as[List[String]]
                         .getOrElse(error(s"Invalid template, expected field 'conditions': List[String]"))

  val branches = cursor.downField("branches")
                       .as[List[String]]
                       .getOrElse(error(s"Invalid template, expected field 'branches': List[String]"))
  (conditions, branches)
}

@main
def main(template: os.Path) = {
  val (conditions, branches) = processTemplate(template)

  val branchSets = branches.scanRight(List.empty[String])(_ :: _).init.reverse

  val config = Json.obj(
    "pull_request_rules" -> Json.fromValues(
      mergeToMaster(conditions) ::
      branchSets.map(makeBackportRule) :::
      labelMergifyBackport ::
      branches.map(backportMergeRule(conditions))
    )
  )
  println(config.asYaml.spaces2)
}
