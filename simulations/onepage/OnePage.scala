/**
 * (c) All rights reserved. ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE,
 * Switzerland, VPSI, 2018
 *
 * This is a generic test fetching a single web page.
 * In order for it to work the following variables must be defined (using -Dvarname=value in JAVA_OPTS)
 * baseurl:  the base domain to be tested (.epfl.ch will be added) [default = www] 
 * reqpath:  the path to be added to the base url [default = no path]
 * users:    number of users/second to be added [default = 1]
 * duration: total simulation duration in seconds [default = 10]
 * pseed:    a string to be added as variable to the URL in order to make this request unique
 * npages:   the number of "different" pages to request by simply adding a different parameter to the request [default = 1]  
 */

package epfl

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import scala.concurrent.duration._
import scala.util.Random

// Utility class for generating "pnum" -> random number within range single element Map
class RandomIntLowerThanMax(var max: Int) {
  private var rrr = new Random
  def next(): Map[String, Int] = {Map("pnum" -> rrr.nextInt(max))}
}

class OnePage extends Simulation {

  // reqPath is one of "", "actu", "memento", "people"
  // nPages is how many 'different' pages we simulate by adding a random parameter to the url
  val nbUsers = Integer.getInteger("users", 1).doubleValue()
  val injectDuration = Integer.getInteger("duration", 10) // scala.concurrent.duration.FiniteDuration
  val reqPath = "/" + System.getProperty("reqpath", "") + "/"
  val bSeed = System.getProperty("bseed", Random.alphanumeric.take(8).mkString)
  val nPages = Integer.getInteger("npages", 1)

  val baseUrl = "https://" + System.getProperty("baseurl", "www") + ".epfl.ch/"

  println("----------------------------------- Simulation Parameters")
  println("baseUrl:  " + baseUrl)
  println("nbUsers:  " + nbUsers)
  println("duration: " + injectDuration)
  println("reqPath:  " + reqPath)
  println("bSeed:    " + bSeed)
  println("nPages:   " + nPages)
  println("---------------------------------------------------------")


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
  val rrr = new RandomIntLowerThanMax(nPages)
  val feeder = Iterator.continually(rrr.next())
  val scn = scenario("wp-cloudflare").group("page") {
    feed(feeder)
    .exec(
      http("home").get(reqPath).queryParam("gtlbseed", bSeed).queryParam("gtlpnum", "${pnum}")
    )
  }    

  setUp(
    // Injects users at a constant rate
    // Users will be injected at randomized intervals.
    scn.inject(
      constantUsersPerSec(nbUsers) during(injectDuration) randomized
    ).protocols(httpConf)
  ).assertions(
    // Test if 95% is served under 500 ms
    details("page").responseTime.percentile3.lt(500)
  ).assertions(
    details("page").failedRequests.percent.is(0)
  )
}