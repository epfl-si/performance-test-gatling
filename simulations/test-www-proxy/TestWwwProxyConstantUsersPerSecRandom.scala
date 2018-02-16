/**
 * (c) All rights reserved. ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2018
 */
package computerdatabase

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import scala.concurrent.duration._

class TestWwwProxyConstantUsersPerSecRandom extends Simulation {

  val httpConf = http
    .baseURL("https://test-www-proxy.epfl.ch") // Here is the root for all relative URLs
    .inferHtmlResources()
    .acceptHeader("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8") // Here are the common headers
    .doNotTrackHeader("1")
    .acceptLanguageHeader("en-US,en;q=0.5")
    .acceptEncodingHeader("gzip, deflate")
    .userAgentHeader("Gatling Test - Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:16.0) Gecko/20100101 Firefox/16.0")

  val scn = scenario("Scenario Name") // A scenario is a chain of requests and pauses
    .exec(http("test-www-proxy.epfl.ch/index.fr.html")
      .get("/index.fr.html"))

  setUp(
    // Injects users at a constant rate, defined in users per second, during a given duration.
    // Users will be injected at randomized intervals.
    scn.inject(constantUsersPerSec(51) during(20) randomized
  ).protocols(httpConf))
}
