--
-- require depend packages: 	xfce4-terminal,rofi,polybar,thunar,maim
-- require depend scripts:	 ~/bin/powermenu.sh

import XMonad
import XMonad.Layout.Fullscreen
    ( fullscreenEventHook, fullscreenManageHook, fullscreenSupport, fullscreenFull )
import Data.Monoid ()
import System.Exit ()
import XMonad.Util.SpawnOnce ( spawnOnce )
import Graphics.X11.ExtraTypes.XF86 (xF86XK_AudioLowerVolume, xF86XK_AudioRaiseVolume, xF86XK_AudioMute, xF86XK_MonBrightnessDown, xF86XK_MonBrightnessUp, xF86XK_AudioPlay, xF86XK_AudioPrev, xF86XK_AudioNext)
import XMonad.Hooks.EwmhDesktops ( ewmh )
import Control.Monad ( join, when )
import XMonad.Layout.NoBorders
import XMonad.Hooks.ManageDocks
    ( avoidStruts, docks, manageDocks, Direction2D(D, L, R, U) )
import XMonad.Hooks.ManageHelpers ( doFullFloat,doCenterFloat, isFullscreen )
import XMonad.Layout.Spacing ( spacingRaw, Border(Border) )
import XMonad.Layout.Gaps
    ( Direction2D(D, L, R, U),
      gaps,
      setGaps,
      GapMessage(DecGap, ToggleGaps, IncGap) )

import qualified XMonad.StackSet as W
import qualified Data.Map        as M
import Data.Maybe (maybeToList)



------------------------------------------------------------------------
--
-- global var
--

-- Whether focus follows the mouse pointer.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse 		= True

-- Whether clicking on a window to focus also passes the click to the window
myClickJustFocuses :: Bool
myClickJustFocuses 		= False

myBorderWidth   		= 2

myModMask       		= mod4Mask
myWorkspaces    		= ["1", "2", "3", "4", "5"]

myTerminal			=  "xfce4-terminal"
rofi_launcher  			=  "rofi -no-lazy-grab -show drun -modi run,drun,window "
polybar_toggle 			=  "polybar-msg cmd toggle"
filemanager			=  "thunar"

screenshot_path			= "~/图片"
maimcopy 			= "maim -s | xclip -selection clipboard -t image/png " 
					++ " && notify-send \"Screenshot\" \"Copied to Clipboard\" -i flameshot"
maimsave 			= ("maim -s " ++ screenshot_path ++ "/$(date +%Y-%m-%d_%H-%M-%S).png " 
					++ " && notify-send \"Screenshot\" \"" 
					++ screenshot_path 
					++ "\" -i flameshot")
power_menu			= "~/bin/powermenu.sh"
xmonad_restart			= "xmonad --restart"
--
-- Border colors for unfocused and focused windows, respectively.
--
myNormalBorderColor  		= "#3b4252"
myFocusedBorderColor 		= "#bc96da"
------------------------------------------------------------------------
--
-- What is this? addNETSupported? addEWMHFullscreen?
--
addNETSupported :: Atom -> X ()
addNETSupported x   		= withDisplay $ \dpy -> do
    r               		<- asks theRoot
    a_NET_SUPPORTED 		<- getAtom "_NET_SUPPORTED"
    a               		<- getAtom "ATOM"
    liftIO $ do
       sup 			<- (join . maybeToList) <$> getWindowProperty32 dpy a_NET_SUPPORTED r
       when (fromIntegral x `notElem` sup) $
         changeProperty32 dpy r a_NET_SUPPORTED a propModeAppend [fromIntegral x]

addEWMHFullscreen :: X ()
addEWMHFullscreen   		= do
    wms 			<- getAtom "_NET_WM_STATE"
    wfs 			<- getAtom "_NET_WM_STATE_FULLSCREEN"
    mapM_ addNETSupported [wms, wfs]
------------------------------------------------------------------------
--
-- Key bindings. Add, modify or remove key bindings here.
--

myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
    -- Quit xmonad
     [((modm .|. 		shiftMask, xK_q     	)	, spawn power_menu)
    -- Restart xmonad
    , ((modm .|. 		shiftMask, xK_r    	)	, spawn xmonad_restart)
    -- close focused window
    , ((modm , 			xK_q     		)	, kill)

--
--layout keys
--
    -- GAPS!!!
    , ((modm, 			xK_g			)	, sendMessage $ ToggleGaps)		-- toggle all gaps

     -- Rotate through the available layout algorithms
    , ((modm,               	xK_space 		)	, sendMessage NextLayout)

    --  Reset the layouts on the current workspace to default
    , ((modm .|. 		shiftMask, xK_space 	)	, setLayout $ XMonad.layoutHook conf)

    -- Resize viewed windows to the correct size
    , ((modm,               	xK_n     		)	, refresh)
--
-- move focus
--
    -- Move focus to the next window
    , ((modm,               	xK_Tab   		)	, windows W.focusDown)

    -- Move focus to the master window
    , ((modm,               	xK_m     		)	, windows W.focusMaster  )

    -- Swap the focused window and the master window
    , ((modm .|. 		shiftMask,   xK_Return	)	, windows W.swapMaster)

--
-- Set Focus windows layout
--
    -- TODO Set Focus window to Fullscreen
    -- , ((modm,               xK_f    ), sendMessage ...)
    -- Push window back into tiling
    , ((modm,               	xK_t     		)	, withFocused $ windows . W.sink)
    -- Set Focus window to Floating
    -- TODO

    -- launch a terminal
    , ((modm , 			xK_Return		)	, spawn myTerminal)
    -- launch rofi and dashboard
    , ((modm,               	xK_o    		)	, spawn rofi_launcher)
    , ((modm,               	xK_u    		)	, spawn filemanager)

--
-- wigdet
--
    , ((modm,               	xK_b     		)	, spawn polybar_toggle)
    
    -- Screenshot
    , ((0,                    xK_Print			)	, spawn maimcopy)
    , ((modm,                 xK_Print			)	, spawn maimsave)
    ] 
    ++

    --
    -- mod-[1..9], Switch to workspace N
    -- mod-shift-[1..9], Move client to workspace N
    --
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++
    []
    
------------------------------------------------------------------------
-- Mouse bindings: default actions bound to mouse events
--
myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList $

    -- mod-button1, Set the window to floating mode and move by dragging
    [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w
                                       >> windows W.shiftMaster))
    -- mod-button3, resize by dragging
    , ((modm, button3), (\w -> focus w >> mouseResizeWindow w
                                       >> windows W.shiftMaster))
    ]

------------------------------------------------------------------------
-- Layouts:
myLayout = avoidStruts(tiled ||| Full)
  where
     -- default tiling algorithm partitions the screen into two panes
     tiled   = Tall nmaster delta ratio

     -- The default number of windows in the master pane
     nmaster = 1

     -- Default proportion of screen occupied by master pane
     ratio   = 1/2

     -- Percent of screen to increment by when resizing panes
     delta   = 3/100

------------------------------------------------------------------------
-- Window rules:
-- 补充：如何找到正确的 className
-- xprop | grep CLASS
-- 使用其中的第二个值（Pavucontrol）作为 className 匹配条件。

myManageHook = fullscreenManageHook <+> manageDocks <+> composeAll
    [ className =? 	"vlc"        			--> doFloat
    , className =? 	"Gimp"           		--> doFloat
    , className =? 	"Pavucontrol" 	        	--> doCenterFloat
    , className =? 	"@docmirror/dev-sidecar-gui" 	--> doCenterFloat
    , className =? 	"Xfce4-power-manager-settings" 	--> doCenterFloat
    , resource  =? 	"desktop_window" 		--> doFloat
    , resource  =? 	"kdesktop"       		--> doFloat
    , isFullscreen 					--> doFullFloat
    ]

------------------------------------------------------------------------
-- Event handling
myEventHook = mempty
------------------------------------------------------------------------
-- Status bars and logging
myLogHook = return ()

------------------------------------------------------------------------
-- Startup hook
myStartupHook = do
  spawn "xsetroot -cursor_name left_ptr"
  spawnOnce "xfce4-power-manager --daemon"
  spawnOnce "fcitx5 &"
  spawnOnce "polybar -c $HOME/.config/polybar/config.ini &"

------------------------------------------------------------------------

main = xmonad $ fullscreenSupport $ docks $ ewmh defaults

--
-- No need to modify this.
--
defaults = def {
      -- simple stuff
        terminal           			= myTerminal,
        focusFollowsMouse  			= myFocusFollowsMouse,
        clickJustFocuses   			= myClickJustFocuses,
        borderWidth        			= myBorderWidth,
        modMask            			= myModMask,
        workspaces         			= myWorkspaces,
        normalBorderColor  			= myNormalBorderColor,
        focusedBorderColor 			= myFocusedBorderColor,

      -- key bindings
        keys               			= myKeys,
        mouseBindings      			= myMouseBindings,

      -- hooks, layouts
        manageHook 				= myManageHook, 
        layoutHook 				= gaps [(L,3), (R,3), (U,3), (D,3)] 
						$ spacingRaw True (Border 3 3 3 3) True (Border 3 3 3 3) True 
						$ smartBorders 
						$ myLayout,
        
	handleEventHook    			= myEventHook,
        logHook            			= myLogHook,
        startupHook        			= myStartupHook >> addEWMHFullscreen
    }

