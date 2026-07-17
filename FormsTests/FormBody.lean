import Forms.FormBody

namespace Forms

-- #guard tests: empty body, single/multiple pairs, `+`-as-space, `%XX` decoding (including
-- decoding a literal `%` via `%25`), a valueless flag, an empty value, and tolerant handling of a
-- malformed/trailing `%` escape.
#guard parseFormBody "" = []
#guard parseFormBody "title=Buy+milk" = [("title", "Buy milk")]
#guard parseFormBody "a=1&b=2" = [("a", "1"), ("b", "2")]
#guard parseFormBody "title=Buy%20milk" = [("title", "Buy milk")]
#guard parseFormBody "a=100%25" = [("a", "100%")]
#guard parseFormBody "flag" = [("flag", "")]
#guard parseFormBody "empty=&x=1" = [("empty", ""), ("x", "1")]
#guard parseFormBody "a=b%" = [("a", "b%")]
#guard parseFormBody "a=b%zz" = [("a", "b%zz")]

end Forms
