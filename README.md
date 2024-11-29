# My Rust flake template
I wrote this for personal use so it's not very complicated, but provides basic support for
custom toolchains (via the [fenix overlay](https://github.com/nix-community/fenix)), as
well as configuration via a home-manager module. 

## Usage notes
- If you're using a toolchain file you will need to provide the SHA of the file along with
  its path. It is automatically populated with a fake SHA so to get the correct one you
  should try building it, the error logs will give the correct value. I haven't found a
  better way around this 
- If using on a project that hasn't been built yet, you'll need to get a Cargo.lock file
  generated. For this you can use `cargo update` or `cargo generate-lockfile`
