/**
 * (c) All rights reserved. ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE,
 * Switzerland, VPSI, 2018
 */
package epfl

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import scala.concurrent.duration._

class InfoscienceExports extends Simulation {
  val exportIdFeeder = Array(Map("exportId" -> s"15")).circular
  // stackoverflow.com 35730086 for to learn about custom feeder


  // Here is the root for all relative URLs
  val baseUrl = "https://idevelopsrv25.epfl.ch/publication-exports"

  // Here are the common headers
  val header  = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"

  val httpConf = http
    .baseURL(baseUrl)
    .inferHtmlResources()
    .acceptHeader(header)
    .doNotTrackHeader("1")
    .acceptLanguageHeader("en-US,en;q=0.5")
    .acceptEncodingHeader("gzip, deflate")
    .userAgentHeader("IDevelopBot - v1.0.0")
    .disableCaching
    .disableClientSharing
    .maxConnectionsPerHostLikeChrome

  // A scenario is a chain of requests and pauses
  val scn = scenario("InfoscienceExports")
    .feed(exportIdFeeder)
    .exec(http("list exports")
    .get("/${exportId}/")
  )

  setUp(
    scn.inject(rampUsers(30) over (10 seconds))
  ).protocols(httpConf)
}
