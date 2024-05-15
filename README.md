# BalenaDockerWaylandGTK
Sample project for a docker container based on Bookworm and with Wayland and GTK support

## Features
* Based on Bookworm
* Targeting ARM64v8 (Raspberry Pi 4+)
* .NET8 support
* Wayland
* GTK
* X11 (currently required for my application based on Uno Platform, would like to remove in the future)
* Developer image with a no-password SSH server
* Extra tools that can be removed (OpenOCD, Joe, etc)

Base image: mcr.microsoft.com/dotnet/sdk:8.0-bookworm-slim-arm64v8

Note that this is coming from a commercial closed-source project (that I own), so it has some bits and pieces that can be cleaned up to make this container cleaner (like I had to create dev nodes for sdaX or my USB stick wouldn't show up).
I'm happy to accept PRs to clean this up further, but I wanted to share this with the community as a starting point, I know it would've helped me a lot in the beginning.
