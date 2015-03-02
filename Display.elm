module Display where

import Pacman (..)
import Controls as Ctr
import BoardControls as BCtr
import Models   as Mod
import Utils    as Utl
import Time (..)

import List ((::))
import List
import Array as A

import Color (..)
import Signal (Signal, (<~), (~))
import Signal
import Window
import Mouse
import Text as Txt
import Graphics.Element as El
import Graphics.Collage as Clg
import String
import Keyboard as Key

-- View

title w h =
    El.container w (h + 20) El.middle
          <| El.flow El.down
                 [El.image w h "/pacman-logo.jpg", El.spacer w 20]

renderPacman : Pacman -> Int -> El.Element
renderPacman p bSide =
    let
        pman_form =
            case p.dir of
              Left -> Mod.pacman Mod.Left ((toFloat bSide) / 2)
              Right -> Mod.pacman Mod.Right ((toFloat bSide) / 2)
              Up -> Mod.pacman Mod.Up ((toFloat bSide) / 2)
              Down -> Mod.pacman Mod.Down ((toFloat bSide) / 2)
    in
      Clg.collage bSide bSide [pman_form]

displayBox : Box -> Int -> El.Element
displayBox b bSide =
    case b of
      Empty -> Clg.collage bSide bSide [Mod.emptySpace (toFloat bSide)]
      Pellet -> Clg.collage bSide bSide [Mod.pellet ((toFloat bSide) / 6)]
      Pill -> Clg.collage bSide bSide [Mod.pill ((toFloat bSide) / 3)]
      Wall -> Clg.collage bSide bSide [Mod.wall (toFloat bSide)]

view : (Int, Int) -> State -> El.Element
view (w, h) st =
    let
        bSide = (h - 45) // 36
        titleHeight = 30
        titleWidth = bSide * 23
        ttl = title titleWidth titleHeight
        rowBuilder bxs = El.flow El.left (List.map (\b -> displayBox b bSide) bxs)
        colBuilder rws = El.flow El.down ([ttl] ++ rws)
        pac_pos = Utl.itow (bSide * numCols) (titleHeight + 20 + (bSide * numRows)) st.pacman.pos
        pac_dir = case st.pacman.dir of
                    Left -> Mod.Left
                    Right -> Mod.Right
                    Up -> Mod.Up
                    Down -> Mod.Down

    in
      El.color black
            <| Clg.collage w h
                 [ Clg.toForm <| colBuilder (List.map rowBuilder st.board)
                 , Clg.move pac_pos <| Mod.pacman pac_dir <| toFloat <| bSide // 2
                 ]

--Controller

type Action = KeyAction Key.KeyCode | TimeAction

actions : Signal Action
actions =
  Signal.merge
    (Signal.map (\k -> KeyAction k) Key.lastPressed)
    (Signal.sampleOn (every <| second / 40)  <| Signal.constant TimeAction)

currState : Signal State
currState =
  Signal.dropRepeats
    <| Signal.foldp upstate initState actions

upstate : Action -> State -> State
upstate a s =
  case a of
    KeyAction k -> {s | pacman <- Ctr.updateDir  k s.pacman}
    TimeAction  -> {s | pacman <- Ctr.updatePacPos s.pacman
                   , board <- BCtr.updateBoard s.board s.pacman}

main : Signal El.Element
main = view <~ Window.dimensions ~ currState
