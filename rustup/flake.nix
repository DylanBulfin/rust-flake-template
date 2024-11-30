{
  description = "Rust flake with rustup devShell";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      systemPkgs = nixpkgs.legacyPackages.${system};
      llvmPackages = systemPkgs.llvmPackages_19;

      ######################################################################################
      # User Inputs:
      toolchainFile = ./rust-toolchain.toml;
      # End User Input
      ######################################################################################
    in {
      devShell.${system} = let
        overrides = (builtins.fromTOML (builtins.readFile toolchainFile));
        libPath = (with systemPkgs;
          lib.makeLibraryPath [
            # External libraries
          ]);
      in systemPkgs.mkShell {
        buildInputs = with systemPkgs; [
          clang

          rustup
          llvmPackages.bintools
        ];

        RUSTC_VERSION = overrides.toolchain.channel;
        # https://github.com/rust-lang/rust-bindgen#environment-variables
        LIBCLANG_PATH =
          systemPkgs.lib.makeLibraryPath [ llvmPackages.libclang.lib ];
        shellHook = ''
          export PATH=$PATH:''${CARGO_HOME:-~/.cargo}/bin
          export PATH=$PATH:''${RUSTUP_HOME:-~/.rustup}/toolchains/$RUSTC_VERSION-x86_64-unknown-linux-gnu/bin/
        '';
        # Add precompiled library to rustc search path
        RUSTFLAGS = (builtins.map (a: "-L ${a}/lib") [
          # add libraries here (e.g. systemPkgs.libvmi)
        ]);
        LD_LIBRARY_PATH = libPath;
        # Add glibc, clang, glib, and other headers to bindgen search path
        BINDGEN_EXTRA_CLANG_ARGS =
          # Includes normal include path
          (builtins.map (a: ''-I"${a}/include"'') [
            # add dev libraries here (e.g. systemPkgs.libvmi.dev)
            systemPkgs.glibc.dev
          ])
          # Includes with special directory paths
          ++ [
            ''
              -I"${llvmPackages.libclang.lib}/lib/clang/${llvmPackages.libclang.version}/include"''
            ''-I"${systemPkgs.glib.dev}/include/glib-2.0"''
            "-I${systemPkgs.glib.out}/lib/glib-2.0/include/"
          ];
      };
      #
    };
}
