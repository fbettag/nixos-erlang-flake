{
  description = "A Nix-flake-based Elixir development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        erlang = pkgs.beam.interpreters.erlangR26;
        elixir = pkgs.beam.packages.erlangR26.elixir_1_15;
        nodejs = pkgs.nodejs-18_x;

        default = pkgs.mkShell {
          buildInputs = [
            pkgs.beam.interpreters.erlangR26
            pkgs.beam.packages.erlangR26.elixir_1_15
            pkgs.nodejs-18_x
            
            # rust support
            pkgs.cargo

            # elixir-typst support
            pkgs.iconv
          ];

          packages = 
            # Linux only
            pkgs.lib.optionals (pkgs.stdenv.isLinux) (with pkgs; [ gigalixir inotify-tools libnotify ]) ++

            # macOS only
            pkgs.lib.optionals (pkgs.stdenv.isDarwin) (with pkgs; [ terminal-notifier postgresql_15 ]) ++
            (with pkgs.darwin.apple_sdk.frameworks; [ CoreFoundation CoreServices ]);


          shellHook = ''
            # this allows mix to work on the local directory
            mkdir -p .nix-mix
            mkdir -p .nix-hex
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-hex
            export PATH=$MIX_HOME/bin:$PATH
            export PATH=$HEX_HOME/bin:$PATH
            export LANG=en_US.UTF-8
            export ERL_AFLAGS="-kernel shell_history enabled"
          '';
        };
      });
    };
}
