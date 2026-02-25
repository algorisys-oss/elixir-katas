# Kata 41: String Deep Dive

## The Concept

Elixir strings are **UTF-8 encoded binaries**. This means every string is just a sequence of bytes that follows the UTF-8 encoding rules. Understanding this internal representation is key to writing correct, performant string code.

```elixir
"hello" == <<104, 101, 108, 108, 111>>   # true
is_binary("hello")                         # true
```

## byte_size vs String.length

These two functions measure different things:

```elixir
# ASCII: 1 byte per character, so they match
byte_size("hello")      # 5
String.length("hello")  # 5

# Multibyte: they diverge
byte_size("cafe")      # 6 (the accent takes 2 bytes)
String.length("cafe")  # 4 (4 visible characters)

# Emoji: even more bytes
byte_size("hi!")       # 6 (2 + 4 bytes for emoji)
String.length("hi!")   # 3
```

**Performance note**: `byte_size/1` is O(1) — it just reads the binary's size metadata. `String.length/1` is O(n) — it must walk every byte to count grapheme clusters.

## Grapheme Clusters vs Codepoints

A **codepoint** is a single Unicode number (like U+0065 for "e"). A **grapheme cluster** is what a human perceives as a single character — it may consist of multiple codepoints.

```elixir
# Simple case: one codepoint = one grapheme
String.graphemes("abc")    # ["a", "b", "c"]
String.codepoints("abc")   # ["a", "b", "c"]

# Combining characters: multiple codepoints = one grapheme
# "e" followed by combining acute accent (U+0301) = "e"
s = "e\u0301"
String.graphemes(s)    # ["e"]      — 1 grapheme
String.codepoints(s)   # ["e", "́"]  — 2 codepoints

# Emoji with skin tone: multiple codepoints = one grapheme
String.length("👋🏽")       # 1 grapheme
String.codepoints("👋🏽")   # multiple codepoints
```

## UTF-8 Encoding Scheme

UTF-8 uses 1–4 bytes per character:

| Byte Count | Codepoint Range | First Byte Pattern | Example |
|------------|----------------|-------------------|---------|
| 1 byte | U+0000–U+007F | `0xxxxxxx` | A (0x41) |
| 2 bytes | U+0080–U+07FF | `110xxxxx 10xxxxxx` | e (0xC3 0xA9) |
| 3 bytes | U+0800–U+FFFF | `1110xxxx 10xxxxxx 10xxxxxx` | 中 (0xE4 0xB8 0xAD) |
| 4 bytes | U+10000+ | `11110xxx 10xxxxxx 10xxxxxx 10xxxxxx` | 😀 (0xF0 0x9F 0x98 0x80) |

## Useful String Module Functions

```elixir
String.slice("Elixir", 0, 3)           # "Eli"
String.split("a,b,c", ",")             # ["a", "b", "c"]
String.replace("hello", "l", "r")      # "herro"
String.starts_with?("hello", "he")     # true
String.ends_with?("hello", "lo")       # true
String.contains?("hello", "ell")       # true
String.trim("  hi  ")                  # "hi"
String.pad_leading("42", 5, "0")       # "00042"
String.upcase("hello")                 # "HELLO"
String.downcase("HELLO")               # "hello"
String.capitalize("hello world")       # "Hello world"
String.duplicate("ha", 3)              # "hahaha"
String.reverse("hello")                # "olleh"
String.at("hello", 2)                  # "l"
```

## Binary Inspection

You can inspect the raw bytes of any string:

```elixir
# View as list of byte integers
:binary.bin_to_list("hello")    # [104, 101, 108, 108, 111]

# View as hex
"hello" |> :binary.bin_to_list() |> Enum.map(&Integer.to_string(&1, 16))
# ["68", "65", "6C", "6C", "6F"]

# Construct from bytes
<<72, 101, 108, 108, 111>>   # "Hello"
```

## Common Pitfalls

1. **Using `byte_size` when you mean `String.length`**: For user-facing character counts, always use `String.length/1`.
2. **Assuming 1 byte = 1 character**: Only true for ASCII. Multibyte characters break this assumption.
3. **Binary slicing vs String slicing**: `binary_part/3` works on bytes; `String.slice/3` works on graphemes.
4. **String.length is O(n)**: Don't call it in a tight loop if you can avoid it. Cache the result.
5. **Grapheme vs codepoint confusion**: Use `String.graphemes/1` for user-visible characters, `String.codepoints/1` for Unicode analysis.
