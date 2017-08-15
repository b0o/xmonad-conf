{-# LANGUAGE AllowAmbiguousTypes, DeriveDataTypeable,
  TypeSynonymInstances, MultiParamTypeClasses #-}

----------------------------------------------------------------------------
-- |
-- Module       : Conf.Bindings.Keys.Workspaces
-- Copyright    : (c) maddy@na.ai
-- License      : MIT
--
-- Maintainer   : maddy@na.ai
-- Stability    : unstable
-- Portability  : unportable
--
----------------------------------------------------------------------------
module Conf.Bindings.Keys.Workspaces
  ( workspaces
  ) where

import Data.List
        ( nub
        , sortBy
        , find
        )

import Conf.Bindings.Keys.Internal
        ( subKeys
        )

import Conf.Theme
        ( warmPrompt
        )

import qualified XMonad
import qualified XMonad.Core as Core
import qualified XMonad.StackSet as StackSet
import qualified XMonad.Prompt as Prompt

import qualified XMonad.Actions.CycleWS as CycleWS

import qualified XMonad.Layout.IndependentScreens as IndependentScreens

import qualified XMonad.Hooks.WorkspaceHistory as WH

import qualified XMonad.Util.NamedScratchpad as NamedScratchpad
import qualified XMonad.Util.WorkspaceCompare as WorkspaceCompare

import XMonad.Actions.DynamicWorkspaces
        -- ( withNthWorkspace
        ( renameWorkspace
        )

import XMonad.Layout.IndependentScreens
        ( VirtualWorkspace
        )

import XMonad.Util.NamedActions
        ( addName
        )

workspaces c = subKeys "Workspaces & Projects" c
  ( [ ( "M-`",   addName "Next non-empty workspace" nextNonEmptyWS)
    , ( "M-S-`", addName "Prev non-empty workspace" prevNonEmptyWS)
    , ( "M-a",   addName "Toggle last workspace"    toggleLast)
    , ( "M-r",   addName "Rename workspace"         renameWs)
    ]
  ++ [ ("M-" ++ show i, addName "View ws" $ XMonad.windows $ IndependentScreens.onCurrentScreen StackSet.view w)
     | (i, w) <- zip [0..9] (workspaces' c) ]
  ++ [ ("C-" ++ show i, addName "Move ws" $ XMonad.windows $ IndependentScreens.onCurrentScreen StackSet.shift w)
     | (i, w) <- zip [0..9] (workspaces' c) ]
  )

renameWs = renameWorkspace warmPrompt

workspaces' :: XMonad.XConfig l -> [VirtualWorkspace]
workspaces' = nub . sortWS . map IndependentScreens.unmarshallW . filterWS . XMonad.workspaces
  where
    filterWS = filter (/="0_NSP")
    sortWS = sortBy (\a b -> compare a b)

nextNonEmptyWS =
  CycleWS.findWorkspace getSortByIndexNoSP Prompt.Next CycleWS.HiddenNonEmptyWS 1 >>= \t ->
    (XMonad.windows . StackSet.view $ t)

prevNonEmptyWS =
  CycleWS.findWorkspace getSortByIndexNoSP Prompt.Prev CycleWS.HiddenNonEmptyWS 1 >>= \t ->
    (XMonad.windows . StackSet.view $ t)

getSortByIndexNoSP =
  fmap (. NamedScratchpad.namedScratchpadFilterOutWorkspace) WorkspaceCompare.getSortByIndex

-- toggleLast = CycleWS.toggleWS' ["0_NSP"] -- Ignore NSP (Named Scratchpad)
toggleLast
  = do
    lastViewedHidden --workspaces'
    return ()

lastViewedHidden :: XMonad.X (Maybe XMonad.WorkspaceId)
lastViewedHidden = do
    hs <- XMonad.gets $ map StackSet.tag . StackSet.hidden . Core.windowset
    vs <- WH.workspaceHistory
    return $ choose hs (find (`elem` hs) vs)
    where choose []    _           = Nothing
          choose (h:_) Nothing     = Just h
          choose _     vh@(Just _) = vh
