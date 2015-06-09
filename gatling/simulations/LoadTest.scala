import io.gatling.core.Predef._
import io.gatling.http.Predef._
import scala.concurrent.duration._

class LoadTest extends Simulation {
  object Thumbnailer {
    val health_check = exec(
      http("Health check")
        .get("/health_check")
        .check(
          status.is(200),
          bodyString.is("HTTP Thumbnailer OK\r\n")
        )
    )

    val image_files = csv("index.csv").circular
    val thumbnail_req = csv("thumbnail.csv").records
    val thumbnails_req = csv("thumbnails.csv").records

    val rnd = new scala.util.Random(42)

    val feed_image =
      feed(image_files)

    val identify =
      exec(
        http("Identify")
        .put("/identify")
        .body(RawFileBody("${file_name}"))
        .check(
          status.is(200),
          headerRegex("Content-Type", "^application/json$"),
          substring(""""mimeType":"image/""")
        )
      )

    val request =
      http("${name}")
      .put("${uri}")
      .body(RawFileBody("${file_name}"))
      .check(
        status.is(200),
        headerRegex("Content-Type", "^${mime_type}"),
        substring("${body}")
      )

    val thumbnail =
      group("Thumbnail") {
        exec((session) => {
          session.set("thumbnail", thumbnail_req(rnd.nextInt(thumbnail_req length)))
        })
        .exec(flattenMapIntoAttributes("${thumbnail}"))
        .exec(request)
      }

    val thumbnails =
      group("Thumbnails") {
        exec((session) => {
          session.set("thumbnails", thumbnails_req(rnd.nextInt(thumbnails_req length)))
        })
        .exec(flattenMapIntoAttributes("${thumbnails}"))
        .exec(request)
      }
  }

  val httpThumbnailer = http.baseURL(sys.env("HTTP_THUMBNAILER_ADDR"))
    .disableWarmUp
    .disableCaching

  val upload_and_process = scenario("Upload and process images")
    .exec(Thumbnailer.health_check)
    .exitHereIfFailed
    .forever {
      exec(
        Thumbnailer.feed_image.pause(50 millisecond, 200 millisecond),
        Thumbnailer.identify.pause(50 millisecond, 200 millisecond),
        repeat(10) {
          exec(
            Thumbnailer.thumbnail.pause(50 millisecond, 200 millisecond)
          )
        },
        Thumbnailer.thumbnails.pause(50 millisecond, 200 millisecond)
      )
    }

  setUp(
    upload_and_process.inject(rampUsers(sys.env("MAX_USERS").toInt) over (300 seconds)).protocols(httpThumbnailer)
  ).maxDuration(300 seconds)
  .assertions(
    global.failedRequests.percent.is(0),
    details("Identify").responseTime.percentile3.lessThan(150),
    details("Thumbnail").responseTime.percentile3.lessThan(500),
    details("Thumbnails").responseTime.percentile3.lessThan(1100)
  )
}

