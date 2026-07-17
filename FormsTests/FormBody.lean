import Forms.FormBody

open Std Async
open Std Http

namespace Forms

private def checkParseForm (body : String) (expected : List (String × String)) : IO Unit := do
  let got ← Async.block do
    let stream ← Body.fromBytes body.toUTF8
    parseForm stream
  unless got = expected do
    throw <| IO.userError s!"parseForm {body.quote}: expected {expected}, got {got}"

#eval checkParseForm "" []
#eval checkParseForm "title=Buy+milk" [("title", "Buy milk")]
#eval checkParseForm "a=1&b=2" [("a", "1"), ("b", "2")]
#eval checkParseForm "title=Buy%20milk" [("title", "Buy milk")]
#eval checkParseForm "a=100%25" [("a", "100%")]
#eval checkParseForm "flag" [("flag", "")]
#eval checkParseForm "empty=&x=1" [("empty", ""), ("x", "1")]
#eval checkParseForm "a=b%" []
#eval checkParseForm "a=b%zz" []

end Forms
