# microformats2-parser [![Hackage](https://img.shields.io/hackage/v/microformats2-parser.svg?style=flat)](https://hackage.haskell.org/package/microformats2-parser) [![Build Status](https://img.shields.io/travis/myfreeweb/microformats2-parser.svg?style=flat)](https://travis-ci.org/myfreeweb/microformats2-parser) [![unlicense](https://img.shields.io/badge/un-license-green.svg?style=flat)](http://unlicense.org)

[Microformats 2] parser for Haskell!

Originally created for [sweetroll] :-)

[Microformats 2]: http://microformats.org/wiki/microformats2
[sweetroll]: https://codeberg.org/valpackett/sweetroll

## [DEMO PAGE](https://unrelenting.technology/mf2/)

## Usage

Look at the API docs [on Hackage](https://hackage.haskell.org/package/microformats2-parser) for more info, here's a quick overview:

```haskell
{-# LANGUAGE OverloadedStrings #-}

import Data.Microformats2.Parser
import Data.Default

parseMf2 def $ documentRoot $ parseLBS "<body><p class=h-entry><h1 class=p-name>Yay!</h1></p></body>"
```

The `def` is the [default](https://hackage.haskell.org/package/data-default-class-0.0.1/docs/Data-Default-Class.html) configuration.

The configuration includes:
- `htmlMode`, an HTML parsing mode (`Unsafe` | `Escape` | **`Sanitize`**)

`parseMf2` will return an Aeson [Value](https://hackage.haskell.org/package/aeson-0.8.0.2/docs/Data-Aeson-Types.html#t:Value) structured like [canonical microformats2 JSON](http://microformats.org/wiki/microformats2).
[lens-aeson](https://hackage.haskell.org/package/lens-aeson) is a good way to navigate it.

## Development

Use [stack] to build.  
Use ghci to run tests quickly with `:test` (see the `.ghci` file).

```bash
$ stack build

$ stack test && rm tests.tix

$ stack ghci --ghc-options="-fno-hpc"
```

[stack]: https://github.com/commercialhaskell/stack

## Contributing

Please feel free to submit pull requests!
Bugfixes and simple non-breaking improvements will be accepted without any questions :-)

By participating in this project you agree to follow the [Contributor Code of Conduct](http://contributor-covenant.org/version/1/2/0/).

[The list of contributors is available on GitHub](https://codeberg.org/valpackett/microformats2-parser/graphs/contributors).

## License

This is free and unencumbered software released into the public domain.  
For more information, please refer to the `UNLICENSE` file or [unlicense.org](http://unlicense.org).
