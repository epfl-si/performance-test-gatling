/**
 * (c) All rights reserved. ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2018
 */
package computerdatabase

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import scala.concurrent.duration._

class TestBackendPar extends Simulation {

  // Here is the root for all relative URLs
  val httpConf = http
    .baseURL("https://test-www-backend.epfl.ch")
    .inferHtmlResources()
    .acceptEncodingHeader("gzip, deflate")
    .userAgentHeader("DevRunBot v1.0")

  // A scenario is a chain of requests and pauses
  val scn = scenario("Scenario Name")
    .exec(http("index.fr.html")
    .get("/index.fr.html"))

  setUp(
    // Injects users at a constant rate
    // Users will be injected at randomized intervals.
    scn.inject(constantUsersPerSec(51) during(20) randomized
  ).protocols(httpConf))
}
