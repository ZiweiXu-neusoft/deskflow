# Fedora GNOME clipboard without focus-stealing windows

Deskflow 1.26.0's experimental `wl-clipboard` integration can repeatedly create
Wayland surfaces on GNOME to acquire clipboard focus. This can interrupt typing
and dismiss menus in applications such as Android Studio. The source on this
branch uses the native Clipboard Portal implementation already present in
upstream commit `ce2f948c296217ac722215eacd9682b5d3e94171` instead.

This branch adds a reproducible build entry point and a CMake requirement that
prevents a successful build with native clipboard support silently omitted.
It does not replace the existing upstream clipboard implementation.

## Requirements

- GNOME 50 or later, with a functioning Clipboard Portal backend.
- libportal 0.10 or later, including development headers.
- The normal Deskflow Linux build dependencies: CMake, Ninja, a C++20 compiler,
  Qt development packages, OpenSSL, libei, xkbcommon/xkbregistry and X11 headers.

On Fedora, ensure the development packages include `libportal-devel`,
`libei-devel`, `openssl-devel`, `libxkbfile-devel` and `libSM-devel`, in addition
to the normal Qt and X11 build dependencies. Installing runtime libraries alone
does not enable the CMake clipboard feature check.

## Build

From the repository root:

```sh
bash tools/build-portal.sh
```

The script requires native clipboard support and runs the project's tests.
The binaries are written to `build/portal/bin`. `BUILD_DIR` and `BUILD_JOBS`
override the output directory and build concurrency.

For an existing directory of locally extracted development RPMs, containing
`usr/include` and `usr/lib64/pkgconfig`, use:

```sh
PORTAL_DEPS_ROOT=/absolute/path/to/deps/root bash tools/build-portal.sh
```

That prefix must have relocatable pkg-config metadata and working library
symlinks pointing to matching installed runtime libraries. It is optional;
normal system development packages need no prefix.

## Run and verify

1. Exit the older Deskflow GUI and core process.
2. Launch `build/portal/bin/deskflow`. Keep `deskflow-core` beside it so the GUI
   starts the newly built core. Update the desktop launcher to this binary when
   using it persistently.
3. Keep clipboard sharing enabled and retain the existing server address.
   The old `wlClipboard` setting is obsolete; native clipboard sharing does not
   need `wl-copy` or `wl-paste`.
4. If GNOME requests remote desktop/clipboard permission, grant it for the new
   session. A restored session without clipboard permission may be retried once.
5. Copy text in Windows, move the pointer to Fedora and paste. Repeat in the
   opposite direction. Open Android Studio menus and type while synchronization
   is active; the menus should remain open and focus should remain stable.

Verified on Fedora 44, GNOME/Mutter 50.4, libportal 0.10.0 and libei 1.6.0,
using a wired Windows Deskflow server: all 27 test executables passed, and the
user confirmed clipboard synchronization and Android Studio menus worked.
This is a source build from the upstream development branch, not a new stable
Deskflow release. No clipboard contents, personal settings, certificates or
compiled binaries are included in this repository change.

## Server clipboard support

The Fedora server uses a separate RemoteDesktop session requesting clipboard
access with no input devices. It does not connect that session to EIS, so the
InputCapture session remains responsible for keyboard and mouse control. This
also works with InputCapture version 1 backends. Both clipboard directions use
the shared cache and the RemoteDesktop clipboard ownership and transfer events;
the InputCapture activation handler does not overwrite this cache.

Verified on 2026-10-05: the user confirmed text copy/paste in both directions
and no unexpected C input after switching to this implementation. All 30
existing test executables passed. These tests do not exercise live GNOME portal
permissions; the clipboard result was verified in the running desktop session.
