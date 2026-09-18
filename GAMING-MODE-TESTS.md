# Steam Deck Gaming Mode tests

Use these tests when SWG Infinity works in Desktop Mode, but Gaming Mode shows
the following Gamescope error, a white screen, or a black screen:

```text
CreateSwapchainKHR: Creating swapchain for non-Gamescope swapchain.
Hooking has failed somewhere!
```

Open **Steam > Library > SWG Infinity > Properties > Shortcut** and edit
**Launch Options**. Run one test at a time and completely stop the shortcut
before trying the next one.

These commands assume the normal Steam Deck user name, `deck`, and the default
location created by this repository's installer. If the Deck uses another user
name, replace `home\deck` with that user's home path.

## Test 1: disable WebView2 GPU rendering

Copy this entire line into **Launch Options**:

```text
WAYLAND_DISPLAY= WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS="--disable-gpu --disable-gpu-compositing --disable-features=Vulkan" WEBVIEW2_BROWSER_EXECUTABLE_FOLDER="Z:\home\deck\.local\share\swg-infinity\webview2-fixed" WINEDLLOVERRIDES="mscoree,mshtml=" %command%
```

This keeps the game's normal DXVK/Vulkan rendering enabled, but asks the
WebView2 process used by Infinity Launcher to render without its GPU path. It
is the preferred test because the Gamescope error may be produced by the
launcher's Chromium/WebView2 child process rather than by the game itself.

## Test 2: also disable the Gamescope WSI layer

Only try this if Test 1 still produces the same popup or black screen. Copy
this entire line into **Launch Options**:

```text
ENABLE_GAMESCOPE_WSI=0 WAYLAND_DISPLAY= WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS="--disable-gpu --disable-gpu-compositing --disable-features=Vulkan" WEBVIEW2_BROWSER_EXECUTABLE_FOLDER="Z:\home\deck\.local\share\swg-infinity\webview2-fixed" WINEDLLOVERRIDES="mscoree,mshtml=" %command%
```

This prevents the Gamescope Vulkan WSI layer from being injected into the
shortcut. It is a diagnostic workaround and may affect how Gamescope captures
or presents the game, so Test 1 should be preferred when it works.

## If the screen is black but the game is still running

Press the **Steam** button and look for **Switch Windows** under SWG Infinity.
The launcher and the game can exist as separate windows, and Gaming Mode may
remain focused on the launcher's blank window. Select the game window if it is
listed.

## Restore the installed default

To undo both tests, restore this line:

```text
WAYLAND_DISPLAY= WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS= WEBVIEW2_BROWSER_EXECUTABLE_FOLDER="Z:\home\deck\.local\share\swg-infinity\webview2-fixed" WINEDLLOVERRIDES="mscoree,mshtml=" %command%
```

## Why Desktop Mode can work

Desktop Mode presents Wine windows through KDE Plasma/XWayland. Gaming Mode
adds Gamescope as the session compositor and injects its Vulkan WSI layer so it
can capture, scale, and present application windows. A WebView2 GPU child
process can therefore work normally on the desktop while conflicting with the
extra Gamescope presentation layer in Gaming Mode.

The missing automatic keyboard in Desktop Mode is a separate input issue.
Wine/WebView2 text fields do not reliably advertise themselves to Plasma as
touch-input fields, so the desktop keyboard is not opened automatically. Keep
the Steam client running and press **Steam + X** to open Steam's on-screen
keyboard manually. This does not indicate a problem with the Proton fix or the
WebView2 installation.
