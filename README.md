#  Branca Tokens for Ruby

Authenticated and encrypted API tokens using modern crypto.

[![Gem Version](https://badge.fury.io/rb/branca-ruby.svg)](https://badge.fury.io/rb/branca-ruby)
[![Build Status](https://travis-ci.org/thadeu/branca-ruby.svg?branch=main)](https://travis-ci.org/thadeu/branca-ruby)
[![Software License](https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square)](LICENSE)

## What?

[Branca](https://github.com/thadeu/branca-ruby) is a secure easy to use token format which makes it hard to shoot yourself in the foot. It uses IETF XChaCha20-Poly1305 AEAD symmetric encryption to create encrypted and tamperproof tokens. Payload itself is an arbitrary sequence of bytes. You can use for example a JSON object, plain text string or even binary data serialized by [MessagePack](http://msgpack.org/) or [Protocol Buffers](https://developers.google.com/protocol-buffers/).

It is possible to use [Branca as an alternative to JWT](https://appelsiini.net/2017/branca-alternative-to-jwt/).

## Install

Add this line to your application's Gemfile, Note that you also must have [libsodium](https://download.libsodium.org/doc/) installed.

```ruby
gem 'branca-ruby', '~> 1.0.0'
```

## Configure

You must be configure `secret_key` and `ttl` using this.

```ruby
Branca.configure do |config|
  config.secret_key = 'supersecretkeyyoushouldnotcommit'.b
  config.ttl = 86_400 # in seconds
end
```

## Usage

The payload of the token can be anything, like a simple string.

### Encode

```ruby
Branca.encode('with string')

# 1y48BiLKOcB4N8xjazwFpas3DwOovXzu6vtbiUr4bDAGLaVyFjIN5Xwz5p3qvNYsi5kWjk7ilgnS
```

or JSON stringified

```ruby
Branca.encode(JSON.generate({ permissions: [] }))

# ATkzLjriA1ijbBcuZOJ1zMR0z5oVXDGDVjUWwrqJWszynAM4GLGiTwZnC6nUvtVIuavAVCMbwcsYqlYKejOI4
```

You can also pass `timestamp` to encode

```ruby
Branca.encode('with string', Time.now.utc)

# 1y48BiV0jaalTYiARPdbm52IKgGEhfwq8DlP9ulKBx8LMLFrjNKe88vIGIUxsWzybIwBhmVvIam5
```

### Decode

If you branca token isnt expired. You will receive something like this

```ruby
decode = Branca.decode('1y48BiV0jaalTYiARPdbm52IKgGEhfwq8DlP9ulKBx8LMLFrjNKe88vIGIUxsWzybIwBhmVvIam5')

# <Branca::Decoder:0x00007fde4e3e6398 @message="with string", @timestamp=2020-10-27 03:44:03 UTC>

decode.message
# "with string"
```

## Exceptions

Token is expired, will receive exception `Branca::ExpiredTokenError`

Invalid Version, will receive exception `Branca::VersionError`