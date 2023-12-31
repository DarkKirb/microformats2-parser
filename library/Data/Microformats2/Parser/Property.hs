{-# LANGUAGE Safe, NoImplicitPrelude, OverloadedStrings, QuasiQuotes, UnicodeSyntax, CPP, RankNTypes, TupleSections #-}
-- LOL: CPP is required for the \ linebreak thing

module Data.Microformats2.Parser.Property where

import           Prelude.Compat
import qualified Data.Text as T
import           Data.Text (Text)
import           Data.CaseInsensitive (CI)
import           Data.Char (isSpace)
import           Data.Foldable (asum)
import qualified Data.Map as M
import           Data.Maybe
import           Data.Microformats2.Parser.Date (normalizeDTParts, parseDTParts)
import           Data.Microformats2.Parser.HtmlUtil
import           Data.Microformats2.Parser.Util

unwrapName ∷ (Name, α) → (Text, α)
unwrapName (Name n _ _, val) = (n, val)

classes ∷ Element → [Text]
classes (Element _ as _) = T.split isSpace . fromMaybe "" . lookup "class" . map unwrapName . M.toList $ as

isPClass, isUClass, isEClass, isDtClass, isPropertyClass, isMf2Class ∷ Text → Bool
isPClass          = T.isPrefixOf "p-"
isUClass          = T.isPrefixOf "u-"
isEClass          = T.isPrefixOf "e-"
isDtClass         = T.isPrefixOf "dt-"
isPropertyClass x = isPClass x || isUClass x || isEClass x || isDtClass x
isMf2Class        = T.isPrefixOf "h-"

isProperty ∷ Element → Bool
isProperty = any isPropertyClass . classes

propertyElements ∷ Traversal' Element Element
propertyElements = attributeSatisfies "class" $ any isPropertyClass . T.split isSpace

hasOneClass ∷ [String] → Traversal' Element Element
hasOneClass ns = attributeSatisfies "class" $ \a → any (\x → (T.pack x) `elem` (T.split isSpace a)) ns

hasClass ∷ String → Traversal' Element Element
hasClass n = attributeSatisfies "class" $ \a → (T.pack n) `elem` (T.split isSpace a)

getOnlyChildren ∷ Element → [Element]
getOnlyChildren e = if lengthOf plate e == 1 then e ^.. plate else []

getOnlyChild, getOnlyOfType ∷ CI Text → Element → Maybe Element
getOnlyChild n e = if' (fromMaybe False $ not <$> isProperty <$> r) $ r
  where r = if' (lengthOf plate e == 1) $ e ^? plate . named n
getOnlyOfType n e = if' (fromMaybe False $ not <$> isProperty <$> r) $ r
  where r = if' (lengthOf (plate . named n) e == 1) $ e ^? plate . named n

els ∷ [Name] → Traversal' Element Element
els ns f s = if elementName s `elem` ns then f s else pure s

getAbbrTitle, getDataInputValue, getImgSrc, getObjectData, getImgAreaAlt, getAAreaHref, getImgAudioVideoSourceSrc, getTimeInsDelDatetime, getOnlyChildImgAreaAlt, \
getOnlyChildAbbrTitle, getOnlyOfTypeImgSrc, getOnlyOfTypeObjectData, getOnlyOfTypeAAreaHref, extractValue, extractValueTitle ∷ Element → Maybe Text
getAbbrTitle              e = e ^. named "abbr" . attribute "title"
getDataInputValue         e = e ^. els ["data", "input"] . attribute "value"
getImgSrc                 e = e ^. named "img" . attribute "src"
getObjectData             e = e ^. named "object" . attribute "data"
getImgAreaAlt             e = e ^. els ["img", "area"] . attribute "alt"
getAAreaHref              e = e ^. els ["a", "area"] . attribute "href"
getImgAudioVideoSourceSrc e = e ^. els ["img", "audio", "video", "source"] . attribute "src"
getTimeInsDelDatetime     e = e ^. els ["time", "ins", "del"] . attribute "datetime"
getOnlyChildImgAreaAlt    e = (^. attribute "alt") =<< asum (getOnlyChild <$> [ "img", "area" ] <*> pure e)
getOnlyChildAbbrTitle     e = (^. attribute "title") =<< getOnlyChild "abbr" e
getOnlyOfTypeImgSrc       e = (^. attribute "src") =<< getOnlyOfType "img" e
getOnlyOfTypeObjectData   e = (^. attribute "data") =<< getOnlyOfType "object" e
getOnlyOfTypeAAreaHref    e = (^. attribute "href") =<< asum (getOnlyOfType <$> [ "a", "area" ] <*> pure e)
extractValue              e = asum $ [ getAbbrTitle, getDataInputValue, getImgAreaAlt, getInnerTextRaw ] <*> pure e
extractValueTitle         e = if' (isJust $ e ^? hasClass "value-title") $ e ^. attribute "title"

extractValueClassPattern ∷ [Element → Maybe Text] → Element → Maybe [Text]
extractValueClassPattern fs e = if' (isJust $ e ^? valueParts) extractValueParts
  where extractValueParts   = Just . catMaybes $ e ^.. valueParts . to extractValuePart
        extractValuePart e' = asum $ fs <*> pure e'
        valueParts          ∷ (Applicative φ, Contravariant φ) => (Element → φ Element) → Element → φ Element
        valueParts          = cosmos . hasOneClass ["value", "value-title"]

extractValueClassPatternConcat ∷ [Element → Maybe Text] → Element → Maybe Text
extractValueClassPatternConcat fs e = T.concat <$> extractValueClassPattern fs e

extractValueClassPatternDate ∷ [Element → Maybe Text] → Element → Maybe Text
extractValueClassPatternDate fs e = asum [ T.pack . show <$> (normalizeDTParts $ parseDTParts $ fromMaybe [] valueParts), T.concat <$> valueParts ]
  where valueParts = extractValueClassPattern fs e

extractP ∷ Element → Maybe Text
extractP e =
  asum $ [ extractValueClassPatternConcat [extractValueTitle, extractValue]
         , getAbbrTitle, getDataInputValue, getImgAreaAlt, getInnerTextWithImgs ] <*> pure e

extractU ∷ Element
         → Maybe (Text, Bool) -- ^ The Microformats 2 spec requires URL resolution only in some cases. The Bool here is whether you should resolve the result.
extractU e =
#if !MIN_VERSION_html_conduit(1,3,1)
  fmap (& _1 %~ unescapeHtml) $
#endif
  asum $ [ (, True) <$> getAAreaHref e
         , (, True) <$> getImgAudioVideoSourceSrc e
         , (, True) <$> getObjectData e
         , (, False) <$> extractValueClassPatternConcat [extractValueTitle, extractValue] e
         , (, False) <$> getAbbrTitle e
         , (, False) <$> getDataInputValue e
         , (, False) <$> getInnerTextRaw e ]

extractDt ∷ Element → Maybe Text
extractDt e =
  asum $ (extractValueClassPatternDate ms : ms ++ [getInnerTextRaw]) <*> pure e
  where ms = [ getTimeInsDelDatetime, extractValueTitle, extractValue ]

implyProperty ∷ String → Element → Maybe Text
implyProperty "name"  e = asum $ [ getImgAreaAlt, getAbbrTitle
                                 , getOnlyChildImgAreaAlt, getOnlyChildAbbrTitle
                                 , \e' -> asum $ [ getOnlyChildImgAreaAlt, getOnlyChildAbbrTitle ] <*> getOnlyChildren e'
                                 , getInnerTextRaw ] <*> pure e
implyProperty "photo" e = asum $ [ getImgSrc, getObjectData
                                 , getOnlyOfTypeImgSrc, getOnlyOfTypeObjectData
                                 , \e' -> asum $ [ getOnlyOfTypeImgSrc, getOnlyOfTypeObjectData ] <*> getOnlyChildren e'
                                 ] <*> pure e
implyProperty "url"   e = asum $ [ getAAreaHref, getOnlyOfTypeAAreaHref ] <*> pure e
implyProperty _ _ = Nothing
