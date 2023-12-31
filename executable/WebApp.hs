{-# LANGUAGE NoImplicitPrelude, OverloadedStrings, UnicodeSyntax, TemplateHaskell #-}

module WebApp (app) where

import           Prelude.Compat
import           Data.Microformats2.Parser
import           Data.Microformats2.Jf2
import           Data.Aeson.Encode.Pretty
import           Data.Aeson.Types (object)
import           Data.Default
import qualified Data.Text.Lazy as TL
import           Network.Wai (Application)
import           Network.Wai.Middleware.Autohead
import           Network.URI (parseURI)
import           Web.Scotty hiding (html)
import           Text.Blaze.Html5 as H hiding (main, param, object, base)
import           Text.Blaze.Html5.Attributes as A hiding (id)
import           Text.Blaze.Html.Renderer.Utf8 (renderHtml)
import           GitHash


exampleValue ∷ TL.Text
exampleValue = "<body> <p class='h-adr'>   <span class='p-street-address'>17 Austerstræti</span>   <span class='p-locality'>Reykjavík</span>   <span class='p-country-name'>Iceland</span>   <span class='p-postal-code'>107</span> </p> <div class='h-card'>   <a class='p-name u-url'      href='http://blog.lizardwrangler.com/'      >Mitchell Baker</a>    (<a class='p-org h-card'        href='http://mozilla.org/'      >Mozilla Foundation</a>) </div> <article class='h-entry'>   <h1 class='p-name'>Microformats are amazing</h1>   <p>Published by <a class='p-author h-card' href='http://example.com'>W. Developer</a>      on <time class='dt-published' datetime='2013-06-13 12:00:00'>13<sup>th</sup> June 2013</time>     <p class='p-summary'>In which I extoll the virtues of using microformats.</p>     <div class='e-content'>     <p>Blah blah blah</p>   </div> </article> <span class='h-cite'>   <time class='dt-published'>YYYY-MM-DD</time>    <span class='p-author h-card'>AUTHOR</span>:    <cite><a class='u-url p-name' href='URL'>TITLE</a></cite> </span> </body>"

homePage ∷ TL.Text → Html
homePage v = docTypeHtml $ do
  H.head $ do
    H.meta ! charset "utf-8"
    H.title "microformats2-parser"
    H.style "body { font-family: 'Helvetica Neue', sans-serif; max-width: 900px; margin: 0 auto; } a { color: #ba2323; } a:hover { color: #da4343; } pre, input:not([type=checkbox]), textarea, button { width: 100%; border-radius: 3px; } input:not([type=checkbox]), textarea, label { margin-bottom: 1em; display: block; } textarea { resize: vertical; min-height: 15em; } pre { white-space: pre-wrap; } footer { margin: 2em 0; } @media screen and (prefers-color-scheme: dark) { html { background: #222; color: #f1f1f1; } input, textarea { background: #444; color: #fefefe; } a { color: #da4343; } a:hover { color: #ea6363; } }"
  H.body $ do
    H.header $ do
      h1 $ do
        a ! href "https://codeberg.org/valpackett/microformats2-parser" $ "microformats2-parser"
      a ! href "https://codeberg.org/valpackett/microformats2-parser" $ img ! alt "Codeberg" ! src "https://img.shields.io/badge/code-berg-blue.svg?style=flat"
      " "
      a ! href "https://hackage.haskell.org/package/microformats2-parser" $ img ! alt "Hackage" ! src "https://img.shields.io/hackage/v/microformats2-parser.svg?style=flat"
      " "
      a ! href "https://unlicense.org" $ img ! alt "unlicense" ! src "https://img.shields.io/badge/un-license-green.svg?style=flat"
    p "This is a test page for the Microformats 2 Haskell parser."
    p "Notes:"
    ul $ do
      li "this demo page uses the Sanitize mode for e-*"
      li $ do
        a ! href "https://enable-cors.org" $ "CORS is enabled"
        " on the endpoint (POST parse.json, form-urlencoded, 'html' and 'base' parameter)"
    H.form ! method "post" ! action "parse.json" $ do
      textarea ! name "html" $ toHtml v
      input ! name "base" ! type_ "url" ! placeholder "https://example.com/base/url/for/resolving/relative/urls"
      H.label $ do
        input ! name "jf2" ! type_ "checkbox"
        "Return "
        a ! href "https://indieweb.org/jf2" $ "jf2"
        " instead of full MF2 JSON"
      button "Parse!"
    footer $ do
      let gi = $$tGitInfoCwd
      p $ do
        "Version: "
        a ! href (toValue $ "https://codeberg.org/valpackett/microformats2-parser/commit/" <> giHash gi) $ toMarkup $ take 12 $ giHash gi
        " ("
        toMarkup $ giCommitDate gi
        ")"
      "made by "
      a ! href "https://val.packett.cool" ! rel "author" $ "Val Packett"

app ∷ IO Application
app = scottyApp $ do
  middleware autohead

  get "/" $ do
    setHeader "Content-Type" "text/html; charset=utf-8"
    raw $ renderHtml $ homePage exampleValue

  get "/parse.json" $ do
    setHeader "Access-Control-Allow-Origin" "*"
    json $ object []

  post "/parse.json" $ do
    hsrc ← param "html"
    base ← param "base" `rescue` (\_ → return "")
    jf2 ← param "jf2" `rescue` (\_ → return ("" ∷ TL.Text))
    setHeader "Content-Type" "application/json; charset=utf-8"
    setHeader "Access-Control-Allow-Origin" "*"
    let root = documentRoot $ parseLBS hsrc
    raw $ encodePretty $ (if jf2 /= "" then mf2ToJf2 else id) $ parseMf2 (def { baseUri = parseURI base }) root
