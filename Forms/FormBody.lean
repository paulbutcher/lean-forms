import Std.Http.Server

/-!
Decoding an `application/x-www-form-urlencoded` request body (`title=Buy+milk`) into
`(name, value)` pairs.
-/

namespace Forms

open Std Async
open Std Http Server

/-- One hex digit's numeric value (case-insensitive), or `none` if `c` isn't `[0-9a-fA-F]`. -/
private def hexDigit (c : Char) : Option Nat :=
  let n := c.toNat
  if n ≥ '0'.toNat ∧ n ≤ '9'.toNat then some (n - '0'.toNat)
  else if n ≥ 'a'.toNat ∧ n ≤ 'f'.toNat then some (n - 'a'.toNat + 10)
  else if n ≥ 'A'.toNat ∧ n ≤ 'F'.toNat then some (n - 'A'.toNat + 10)
  else none

/-- Percent-decodes a `List Char`, accumulating the (reversed) decoded output in `acc`: `+`
becomes a space, `%XX` becomes the single character with that codepoint, and a `%` not followed by
two valid hex digits (including one at the very end of the input) fails the whole decode -- a
compliant sender always percent-encodes a literal `%` as `%25`, so a stray `%` here means the body
didn't come from a compliant form submission. -/
private def decodeCharsAux : List Char → List Char → Option (List Char)
  | acc, [] => some acc.reverse
  | acc, '+' :: rest => decodeCharsAux (' ' :: acc) rest
  | acc, '%' :: d1 :: d2 :: rest =>
    match hexDigit d1, hexDigit d2 with
    | some h1, some h2 => decodeCharsAux (Char.ofNat (h1 * 16 + h2) :: acc) rest
    | _, _ => none
  | _, '%' :: _ => none
  | acc, c :: rest => decodeCharsAux (c :: acc) rest

/-- Percent-decodes one form-urlencoded component (a key or a value), or `none` if it contains
malformed percent-encoding. -/
def decodeComponent (s : String) : Option String :=
  (decodeCharsAux [] s.toList).map String.ofList

/-- Splits a `List Char` on `'&'`. -/
private def splitAmp : List Char → List (List Char)
  | [] => [[]]
  | c :: rest =>
    if c = '&' then [] :: splitAmp rest
    else
      match splitAmp rest with
      | [] => [[c]]
      | seg :: segs => (c :: seg) :: segs

/-- Splits a `List Char` on the first `'='`. A pair with no `'='` at all (a bare flag, e.g.
`"checked"`) is treated as that key with an empty value: forms legitimately send valueless keys. -/
private def splitOnceEquals : List Char → List Char × List Char
  | [] => ([], [])
  | '=' :: rest => ([], rest)
  | c :: rest =>
    let (k, v) := splitOnceEquals rest
    (c :: k, v)

/-- Decodes an `application/x-www-form-urlencoded` body into `(name, value)` pairs, in the order
they appeared, or `none` if any component contains malformed percent-encoding. A completely empty
body (or a stray `&` producing an empty segment) contributes no pairs, rather than an empty-string
key. -/
def parseFormBody (body : String) : Option (List (String × String)) :=
  ((splitAmp body.toList).filter (·.isEmpty = false)).mapM fun cs =>
    let (k, v) := splitOnceEquals cs
    return (← decodeComponent (String.ofList k), ← decodeComponent (String.ofList v))

/-- Reads and decodes an `application/x-www-form-urlencoded` request body from `stream` into
`(name, value)` pairs, or `[]` if the body is ill-formed. -/
def parseForm (stream : Body.Stream) : Async (List (String × String)) := do
  let body ← stream.readAll (α := String)
  return (parseFormBody body).getD []

end Forms
