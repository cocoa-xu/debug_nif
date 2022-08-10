# DebugNIF

An escript for debugging a NIF library in a debugger. It automates the process described here, [Debug Erlang NIF library on macOS and Linux](https://cocoa-research.works/2022/02/debug-erlang-nif-library/).

Works on macOS and Linux.

![macOS](assets/screenshot-macos.png)

![Linux](assets/screenshot-linux.png)

## Build and Installation

```shell
# clone this repo
$ git clone https://github.com/cocoa-xu/debug_nif.git
$ cd debug_nif
$ mix do escript.build + escript.install

# or directly build from HEAD
$ mix escript.install github cocoa-xu/debug_nif

# or install a specific version
$ mix escript.install github cocoa-xu/debug_nif tag v0.1.0
```

By default the `debug_nif` escript will try to download precompiled NIF binaries from GitHub. If there is no corresponding precompiled binary for your machine, you can build it from source by

```shell
export DEBUG_NIF_USE_PRECOMPILED=NO
# then call `mix escript.install ...`
```

## Usage
```shell
$ debug_nif --help
synopsis:
    A convenient script for debugging NIF libraries.
usage:
    $ debug_nif {options} arg1 arg2 ...
    is equvilent to call `mix arg1 arg2 ...`
options:
    --print-only          Only print commands and necessary environment variables
                          for running the debugger.
    --print-cmd-only      Only print commands for running the debugger.
    --debugger=DEBUGGER   Set which debugger to use. `lldb` is the default for
                          macOS and `gdb` is the default for linux.
    --generate=TYPE       It's possible to generate a Xcode project on macOS for
                          debugging or profiling with Xcode. [TODO]
```
