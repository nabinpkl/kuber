{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}
module Cardano.Kuber.Core.ChainAPI where
import Cardano.Kuber.Core.Kontract
import Cardano.Kuber.Error
import Cardano.Api.Shelley
import Cardano.Api
import Cardano.Slotting.Time (SystemStart)
import Data.Time.Clock.POSIX (POSIXTime)
import Data.Set (Set)
import PlutusTx.Prelude (traceError)


class HasChainQueryAPI a  where
  -- Core query functions
  kGetNetworkId         :: Kontract  a w FrameworkError NetworkId
  kQueryProtocolParams  :: Kontract  a w FrameworkError ProtocolParameters
  kQuerySystemStart     :: Kontract a w FrameworkError  SystemStart
  kQueryGenesisParams   :: Kontract a w FrameworkError GenesisParameters
  kQueryUtxoByAddress   :: Set AddressAny -> Kontract  a w FrameworkError (UTxO BabbageEra)
  kQueryUtxoByTxin      :: Set TxIn -> Kontract a w FrameworkError (UTxO BabbageEra)
  kQueryChainPoint      :: Kontract a w FrameworkError ChainPoint


class HasSubmitApi a where
  kSubmitTx :: Tx BabbageEra ->  Kontract  a w FrameworkError ()

data  CachedApi  a = CachedApi a  SystemStart ProtocolParameters (EraHistory CardanoMode) GenesisParameters


-- instance HasChainQueryAPI a => HasChainQueryAPI (CachedApi a ) where
--   kQueryProtocolParams = KLift $ \(CachedApi a _ pp _  _ )  -> pure (pure pp)
--   kQuerySystemStart = KLift $ \(CachedApi a ss pp eh  gp )  -> pure (pure ss)
--   kQueryEraHistory = KLift $ \(CachedApi a ss pp eh  gp )  -> pure (pure eh)
--   kQueryGenesisParams = KLift $ \(CachedApi a ss pp eh  gp )  -> pure (pure gp)
--   kQueryUtxoByAddress addrs=  KLift $ \(CachedApi a _ _ _  _ )  -> evaluateKontract a (kQueryUtxoByAddress addrs)
--   kQueryUtxoByTxin txins = KLift $ \(CachedApi a _ _ _  _ )  -> evaluateKontract a (kQueryUtxoByTxin txins)
--   kQueryChainPoint = KLift $ \(CachedApi a _ _ _  _ )  -> evaluateKontract a kQueryChainPoint
--   kGetNetworkId = KLift $ \(CachedApi a _ _ _  _ )  ->evaluateKontract a kGetNetworkId


-- instance HasSubmitApi a => HasSubmitApi( CachedApi a) where
--     kSubmitTx  tx =  KLift $ \(CachedApi a _ pp _  _ )  ->evaluateKontract a (kSubmitTx tx)



-- withCache :: HasChainQueryAPI a => a -> IO (Either FrameworkError (CachedApi a))
-- withCache api = do
--     eParams  <- evaluateKontract api $  do
--                     pParam <-  kQueryProtocolParams
--                     sStart <- kQuerySystemStart
--                     eraHistory  <- kQueryEraHistory
--                     genesisParams <- kQueryGenesisParams
--                     pure ( pParam, sStart,eraHistory , genesisParams)
--     case eParams of
--       Left fe -> pure $ Left fe
--       Right (pp, ss, eh, gp) -> pure $ pure $ CachedApi api ss pp eh gp
