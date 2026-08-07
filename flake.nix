{
  # Trial-only packaging for the Doppler-provider fork. This flake lives on the
  # `doppler-trial` branch so the upstream PR branch stays flake-free; it lets
  # downstream projects consume the CLI as `packages.<system>.default` instead
  # of writing their own buildRustPackage.
  #
  # nixpkgs is pinned to unstable because the workspace's MSRV is 1.92
  # (rust-toolchain.toml); nixos-25.11 still ships rustc 1.91.
  description = "SecretSpec CLI with the Doppler provider (fork trial build)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        default = secretspec;
        secretspec = pkgs.rustPlatform.buildRustPackage {
          pname = "secretspec";
          # Read from the workspace rather than hard-coded, so rebasing this
          # branch onto a newer upstream cannot leave the store path claiming a
          # version the binary does not report.
          version =
            "${(builtins.fromTOML (builtins.readFile ./Cargo.toml)).workspace.package.version}-doppler";
          src = self;
          cargoLock.lockFile = ./Cargo.lock;
          buildAndTestSubdir = "secretspec";
          # The interesting tests need live provider backends; the fork's CI
          # runs the offline suite already.
          doCheck = false;
          meta = {
            description = "Declarative secrets, every environment, any provider";
            homepage = "https://secretspec.dev";
            license = pkgs.lib.licenses.asl20;
            mainProgram = "secretspec";
          };
        };
      });
    };
}
