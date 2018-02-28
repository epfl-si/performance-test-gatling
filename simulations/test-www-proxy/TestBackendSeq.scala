/**
 * (c) All rights reserved. ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2018
 */
package computerdatabase

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import scala.concurrent.duration._

class TestBackendSeq extends Simulation {

  // Here is the root for all relative URLs
  val httpConf = http
    .baseURL("https://test-www-backend.epfl.ch")
    .acceptEncodingHeader("gzip, deflate")
    .userAgentHeader("DevRunBot v1.0")

  // A scenario is a chain of requests
  val scn = scenario("Scenario Name")
    .exec(http("index.fr.html")
      .get("/index.fr.html")
    ).exec(http("favicon.8fc2f2d4bc4f.ico")
      .get("/public/hp2013/epfl-bootstrap/favicon.8fc2f2d4bc4f.ico")
    ).exec(http("favicon.24556dbc785e.png")
      .get("/public/hp2013/epfl-bootstrap/favicon.24556dbc785e.png")
    ).exec(http("app.2620b3a6149b.css")
      .get("/public/hp2013/css/app.2620b3a6149b.css")
    ).exec(http("logo.0db041f79158.png")
      .get("/public/hp2013/epfl-bootstrap/images/logo.0db041f79158.png")
    ).exec(http("1-a293b3.jpg")
      .get("/visual/news/en/1-a293b3.jpg")
    ).exec(http("logo.0523381324e7.svg")
      .get("/public/hp2013/epfl-bootstrap/images/logo.0523381324e7.svg")
    ).exec(http("2-cfd782.jpg")
      .get("/visual/news/en/2-cfd782.jpg")
    ).exec(http("3-12d5f1.jpg")
      .get("/visual/news/en/3-12d5f1.jpg")
    ).exec(http("ab1f2c-Ouds_184_BZUA45R.jpg")
      .get("/visual/fr/ab1f2c-Ouds_184_BZUA45R.jpg")
    ).exec(http("3cde01-aliH_S2IOmoA.jpg")
      .get("/visual/en/3cde01-aliH_S2IOmoA.jpg")
    ).exec(http("6ee80c-case_moocs.jpg")
      .get("/visual/en/6ee80c-case_moocs.jpg")
    ).exec(http("3799ca-eurotech_YNOuQZE.jpg")
      .get("/visual/fr/3799ca-eurotech_YNOuQZE.jpg")
    ).exec(http("67728e-bande%20d'annonce%20website%20epfl_RzMuz0T.jpg")
      .get("/visual/en/67728e-bande%20d'annonce%20website%20epfl_RzMuz0T.jpg")
    ).exec(http("62c94e-d979c5-banniere-1-22.01.2018_1uxKrU7.jpg")
      .get("/visual/en/62c94e-d979c5-banniere-1-22.01.2018_1uxKrU7.jpg")
    ).exec(http("330-4f774d.jpg")
      .get("/visual/survey/en/330-4f774d.jpg")
    ).exec(http("525efd-1V0A4092-2%20copie_gHqSzNj.jpg")
      .get("/visual/en/525efd-1V0A4092-2%20copie_gHqSzNj.jpg")
    ).exec(http("app.651b1e6d125c.js")
      .get("/public/hp2013/js/app.651b1e6d125c.js")
    )

  setUp(
    // Injects users at a constant rate
    // Users will be injected at randomized intervals.
    scn.inject(constantUsersPerSec(100) during(20) randomized
  ).protocols(httpConf))
}
