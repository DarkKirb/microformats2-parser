[![Hackage](https://img.shields.io/hackage/v/microformats2-parser.svg?style=flat)](https://hackage.haskell.org/package/microformats2-parser)
[![unlicense](https://img.shields.io/badge/un-license-green.svg?style=flat)](https://unlicense.org)

# microformats2-parser

[Microformats 2] parser for Haskell! [#IndieWeb]

- parses `items`, `rels`, `rel-urls`
- resolves relative URLs (with support for the `<base>` tag), including inside of `html` for `e-*` properties
- parses the [value-class-pattern](http://microformats.org/wiki/value-class-pattern), including date and time normalization
- handles malformed HTML (the actual HTML parser is [tagstream-conduit])
- also can convert to [JF2]
- high performance
- extensively tested

Also check out [http-link-header] because you often need to read links from the Link header!

[Microformats 2]: http://microformats.org/wiki/microformats2
[#IndieWeb]: https://indieweb.org
[tagstream-conduit]: https://hackage.haskell.org/package/tagstream-conduit
[JF2]: https://www.w3.org/TR/jf2/
[http-link-header]: https://codeberg.org/valpackett/http-link-header

## [DEMO PAGE](https://unrelenting.technology/mf2/)

## Usage

Look at the API docs [on Hackage](https://hackage.haskell.org/package/microformats2-parser) for more info, here's a quick overview:

```haskell
{-# LANGUAGE OverloadedStrings #-}

import Data.Microformats2.Parser
import Data.Default
import Network.URI

parseMf2 def $ documentRoot $ parseLBS "<body><p class=h-entry><h1 class=p-name>Yay!</h1></p></body>"

parseMf2 (def { baseUri = parseURI "https://where.i.got/that/page/from/" }) $ documentRoot $ parseLBS "<body><base href=\"base/\"><link rel=micropub href='micropub'><p class=h-entry><h1 class=p-name>Yay!</h1></p></body>"
```

The `def` is the [default](https://hackage.haskell.org/package/data-default-class-0.0.1/docs/Data-Default-Class.html) configuration.

The configuration includes:
- `htmlMode`, an HTML parsing mode (`Unsafe` | `Escape` | **`Sanitize`**)
- `baseUri`, the `Maybe URI` that represents the address you retrieved the HTML from, used for resolving relative addresses -- you should set it

`parseMf2` will return an Aeson [Value](https://hackage.haskell.org/package/aeson-0.8.0.2/docs/Data-Aeson-Types.html#t:Value) structured like [canonical microformats2 JSON](http://microformats.org/wiki/microformats2).
[lens-aeson](https://hackage.haskell.org/package/lens-aeson) is a good way to navigate it.

## Development

Use [stack] to build.  
Use ghci to run tests quickly with `:test` (see the `.ghci` file).

```bash
$ stack build

$ stack test

$ stack ghci
```

[stack]: https://github.com/commercialhaskell/stack

## License

This is free and unencumbered software released into the public domain.  
For more information, please refer to the `UNLICENSE` file or [unlicense.org](https://unlicense.org).
