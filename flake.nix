{
  description = "Ensemble des playbooks Ansible pour le Homelab";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f:
      nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs {
          inherit system;
        }));

    # Outils des contrôles, communs au devShell et à l'image de CI
    checkTools = pkgs:
      with pkgs; [
        (ansible.override {extraPackages = ps: [ps.hvac];})
        ansible-lint
        ansible-builder
        pre-commit
        gitleaks
        forgejo-runner
      ];
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages =
          checkTools pkgs
          ++ (with pkgs; [
            openbao # connexion Openbao dans .envrc
            ansible-navigator
            podman
          ]);
      };
    });
  };
}
