/**
 * (c) All rights reserved. ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE,
 * Switzerland, VPSI, 2019
 */
package epfl

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import scala.concurrent.duration._

class MementoSubscription extends Simulation {

  // Here is the root for all relative URLs
  val baseUrl = "https://memento.epfl.ch"

  // Here are the common headers
  val header  = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"

  val httpConf = http
    .baseURL(baseUrl)
    .inferHtmlResources()
    .acceptHeader(header)
    .doNotTrackHeader("1")
    .acceptLanguageHeader("en-US,en;q=0.5")
    .acceptEncodingHeader("gzip, deflate")
    .userAgentHeader("EPFL-SI PerfTestBot - v1.0.0")
    .disableCaching
    .disableClientSharing
    .maxConnectionsPerHostLikeChrome

  // A scenario is a chain of requests and pauses
  val scn = scenario("memento-subscription").group("page") {
    exec(http("memento-subscription").get("/private/subscription/epfl/")
  )}

  setUp(
    // Injects users at a constant rate
    // Users will be injected at randomized intervals.
    scn.inject(
      constantUsersPerSec(6) during(300) randomized
    ).protocols(httpConf)
  ).assertions(
    // Test if 95% is served under 500 ms
    details("page").responseTime.percentile3.lt(500)
  ).assertions(
    details("page").failedRequests.percent.is(0)
  )
}
