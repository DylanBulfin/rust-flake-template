{
  description = ''
    Template for rust projects, provides an overlay to access the project and
    a home-manager module to configure it
  '';
  outputs = { self }: {
    templates = rec {
      fenix = {
        path = ./fenix;
        description = ''
          Uses the fenix overlay to provide a packaging/devShell for
                  basic-medium rust projects'';
      };
      rustup = {
        path = ./rustup;
        description = ''
          Uses a devShell from the Rust page on the NixOS wiki, to provide more
            native rust support with rustup'';
      };
      default = fenix;
    };
  };
}
