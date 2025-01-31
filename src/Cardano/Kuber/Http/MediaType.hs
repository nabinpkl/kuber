{-#LANGUAGE OverloadedStrings#-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE FlexibleContexts #-}

module Cardano.Kuber.Http.MediaType
where

import Network.HTTP.Media ((//), (/:), MediaType)
import Servant.API.ContentTypes (Accept (contentType,contentTypes), MimeUnrender (mimeUnrender), MimeRender (mimeRender))
import GHC.Base (NonEmpty ((:|)))
import qualified Data.ByteString.Lazy as BSL
import qualified Data.ByteString as BSS
import qualified Data.ByteString.Char8 as BS8
import qualified Data.Text as T
import qualified Data.Text.Encoding as T

import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Encoding as TL
import Cardano.Binary (FromCBOR)
import qualified Cardano.Binary as CBOR
import Cardano.Api (Tx, BabbageEra, SerialiseAsCBOR (deserialiseFromCBOR, serialiseToCBOR), AsType (AsTx, AsBabbageEra))
import Data.Text.Conversions (Base16(Base16), convertText)
import Data.Data (Proxy (Proxy))
import Data.ByteString (ByteString)
import Data.Proxy (asProxyTypeOf)
import qualified Data.ByteString.Lazy
import Cardano.Kuber.Data.Models (SubmitTxModal(SubmitTxModal), TxModal (TxModal))
import Data.ByteString.Lazy (fromStrict)

data AnyTextType = AnyTextType

instance Accept AnyTextType where
   contentTypes _ =  "text" // "plain" :| [  "text" // "*", "text" // "plain" /: ("charset", "utf-8") ]

instance  MimeUnrender AnyTextType String where
   mimeUnrender _ bs = Right  $  BS8.unpack  $ BSL.toStrict bs

instance  MimeUnrender AnyTextType TL.Text where
    mimeUnrender _ bs = Right  $ TL.decodeUtf8 bs

instance  MimeUnrender AnyTextType T.Text where
    mimeUnrender :: Proxy AnyTextType -> Data.ByteString.Lazy.ByteString -> Either String T.Text
    mimeUnrender _ bs = Right  $ T.decodeUtf8  $ BSL.toStrict bs

data CBORBinary =CBORBinary

instance Accept CBORBinary where
   contentTypes _ =  "octet" // "stream" :| [  "application" // "cbor"]

instance  MimeUnrender  CBORBinary  ( Tx BabbageEra ) where
    mimeUnrender  _ bs = case deserialiseFromCBOR (AsTx AsBabbageEra) ( Data.ByteString.Lazy.toStrict bs) of
        Left e -> Left $ "Tx string: Invalid CBOR format : " ++ show e
        Right tx -> pure  tx

instance  MimeUnrender  CBORBinary  TxModal where
    mimeUnrender  proxy bs = do
      v <- mimeUnrender proxy bs
      pure (TxModal v)

instance MimeRender CBORBinary TxModal where
  mimeRender :: Proxy CBORBinary -> TxModal -> Data.ByteString.Lazy.ByteString
  mimeRender p (TxModal tx) = fromStrict $  serialiseToCBOR tx
   


instance MimeUnrender CBORBinary  SubmitTxModal where
   mimeUnrender  _ bs  = case deserialiseFromCBOR (AsTx AsBabbageEra) ( Data.ByteString.Lazy.toStrict bs) of
        Left e -> Left $ "Tx string: Invalid CBOR format : " ++ show e
        Right tx -> pure  $ SubmitTxModal tx Nothing


data CBORText =CBORText

instance Accept CBORText where
   contentTypes :: Proxy CBORText -> NonEmpty MediaType
   contentTypes _ =  "text" // "plain" :| [ "text" // "cbor" , "text" //"hex", "text" // "plain" /: ("charset", "utf-8") ]

instance (MimeUnrender CBORBinary a) => MimeUnrender CBORText a where
  mimeUnrender  _ bs =  case convertText (BS8.unpack $ BSL.toStrict bs) of
      Nothing -> Left "Expected hex encoded CBOR string"
      Just (Base16 bs) -> mimeUnrender (Proxy  :: (Proxy CBORBinary)) bs

instance (MimeRender CBORBinary a) => MimeRender CBORText a where
   mimeRender :: MimeRender CBORBinary a => Proxy CBORText -> a -> Data.ByteString.Lazy.ByteString
   mimeRender proxy  obj= mimeRender  (Proxy  :: (Proxy CBORBinary)) obj