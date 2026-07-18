# Forms

A Lean 4 library for decoding `application/x-www-form-urlencoded` HTML form
submissions (e.g. `title=Buy+milk&done=false`) into `(name, value)` pairs.

See: [Formally verified CRUD](https://paulbutcher.com/lean2.html).

## Installation

Add this to your `lakefile.toml`:

```toml
[[require]]
name = "Forms"
git = "https://github.com/paulbutcher/lean-forms"
```

## Usage

To parse a request body already read into a `String`, use `parseFormBody`:

```lean
open Forms

#eval parseFormBody "title=Buy+milk&done=false"
-- some [("title", "Buy milk"), ("done", "false")]
```

It returns `none` if the body contains malformed percent-encoding.

To read and parse a form body directly from a `Std.Http.Server` request's
body stream, use `parseForm`:

```lean
open Forms

def handleRequest (request : Std.Http.Server.Request Std.Http.Server.Body.Stream) : Async Unit := do
  let pairs ← parseForm request.body
  ...
```

`parseForm` returns `[]` if the body is ill-formed, rather than failing.

## License

This library is released under the Apache 2.0 license. See the LICENSE
file for the complete license text.