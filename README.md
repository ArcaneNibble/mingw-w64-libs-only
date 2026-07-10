# mingw-w64 libraries and headers

This repo builds just the libraries and headers from mingw-w64. It is intended for things such as targeting `*-windows-gnullvm` with Rust. `rustup` makes these libraries available, but _only on Windows_, so this tarball simplifies the process for other platforms.

## Build configuration

- Uses UCRT
- CFG is enabled
- Also builds `compiler-rt` and `libunwind`
- Sanitizers are _not_ supported

## Example usage

In `.cargo/config.toml`, write something like:

```toml
[build]
target = "x86_64-pc-windows-gnullvm"

[target.x86_64-pc-windows-gnullvm]
rustflags = [
    "-Clinker=rust-lld",
    "-L../path/to/mingw-w64-minimal/x86_64-w64-mingw32/lib",
    "-Clink-arg=crt2.o",
]
```
