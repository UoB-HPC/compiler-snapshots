package uob_hpc.snapshots

import com.raquo.airstream.state.Var
import com.raquo.laminar.api.L.*
import org.scalajs.dom.fetch

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.scalajs.js

extension [A: Numeric](inline d: A) {
  inline def px  = s"${d}px"
  inline def em  = s"${d}em"
  inline def vh  = s"${d}vh"
  inline def vw  = s"${d}vw"
  inline def pct = s"$d%"
  inline def inset = Seq(
    top    := 0.px,
    left   := 0.px,
    bottom := 0.px,
    right  := 0.px
  )
}
extension (inline t: Throwable) {
  inline def stackTraceAsString = {
    val sw = java.io.StringWriter()
    t.printStackTrace(java.io.PrintWriter(sw))
    sw.toString
  }
}

enum Deferred[+A] {
  case Pending
  case Success(a: A)
  case Error(e: Throwable)
}

given [A: upickle.default.ReadWriter]: upickle.default.ReadWriter[Var[A]] =
  upickle.default.readwriter[A].bimap[Var[A]](_.now(), Var(_))

//def fetchJson[A](url: String): Future[A] = fetch(url).toFuture.flatMap(_.json().toFuture).map(_.asInstanceOf[A])

inline def fetchRaw(inline url: String): Future[String]                = fetch(url).toFuture.flatMap(_.text().toFuture)
inline def fetchJson[A: Pickler.Reader](inline url: String): Future[A] = fetchRaw(url).map(Pickler.web.read[A](_))
