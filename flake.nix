{
  description = ''
  Template for rust projects, provides an overlay to access the project and
  a home-manager module to configure it
  '';
  outputs = {self}: {
    templates = rec {
      rust = {
        path = ./rust;
        description = "Very simple rust flake template";
      };
      default = rust;
    };
  };
}