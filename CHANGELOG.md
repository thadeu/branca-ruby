# Changelog

## [1.0.5] - 2025-02-10

### Changed

- Replaced the `base_x` gem with a built-in `Branca::Base62` encoder/decoder.

The `base_x` gem uses mathematical range-based padding, which prepends a leading `'0'` character
to the encoded token when `62^len < 256^byte_count`. This is incompatible with the JavaScript
[base-x](https://github.com/cryptocoinjs/base-x) library used by
[branca-js](https://github.com/tuupola/branca-js) and all other Branca implementations.

The JavaScript `base-x` library follows the Bitcoin-style convention where leading `'0'` characters
in the encoded string map 1:1 to leading `\x00` bytes in the decoded binary. When it decodes a
Ruby-generated token that starts with `'0'` (added as mathematical padding), it interprets that
character as a `\x00` byte, corrupting the version byte from `0xBA` to `0x00` and causing an
"Invalid token version" error.

The new `Branca::Base62` module implements the same Bitcoin-style algorithm, ensuring full
cross-language compatibility with every Branca implementation listed in the
[branca-spec](https://github.com/thadeu/branca-spec).

### Removed

- Removed the `base_x` gem dependency.

## [1.0.4] - 2026-02-10

### Changed

- First attempt to fix the leading `'0'` issue in Base62-encoded tokens by using a rearranged
  alphabet (`BaseX.new('123456789ABCDEF...0')`) to avoid `'0'` as the first character. This
  workaround shifted `'0'` to the end of the numeral set but did not address the root cause:
  the `base_x` gem's mathematical padding algorithm is fundamentally incompatible with the
  JavaScript `base-x` library used by all other Branca implementations.

- Added a fallback in `base62_decode` that retries with the original `BaseX::Base62` alphabet
  when the version byte does not match `0xBA`, providing partial backward compatibility.

- Added comprehensive tests for Base62 encoding compliance and round-trip validation with
  production-like payloads.

> **Note:** This version was superseded by 1.0.5, which fully replaces the `base_x` gem with
> a Bitcoin-style `Branca::Base62` implementation that is natively compatible with `branca-js`.
