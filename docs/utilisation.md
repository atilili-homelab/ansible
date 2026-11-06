# Utilisation

## Prérequis

- **Nix** avec les flakes activés, et **direnv**.
- **rbw** (client Bitwarden CLI) déverrouillé : il fournit le mot de passe
  OpenBao de l'utilisateur `yoann`, si aucune session n'est ouverte.
- Un accès réseau à **OpenBao**, à l'**API Proxmox** et aux machines en SSH.

Les outils (ansible, ansible-lint, ansible-builder, pre-commit, gitleaks, client
OpenBao) ne sont pas à installer : ils sont fournis par le `flake.nix`, en
versions figées par `flake.lock`.

Les collections et le rôle tiers ne sont pas versionnés dans le dépôt. Leurs
versions sont fixées dans `requirements.yml`, et ils s'installent dans
`~/.ansible`.

## Commandes

```bash
direnv allow                                    # une seule fois : charge l'environnement
ansible-galaxy install -r requirements.yml      # après chaque changement de requirements.yml
ansible-inventory --graph                       # vérifie l'inventaire et les groupes
ansible-playbook site.yml --check --diff        # simulation, sans rien modifier
ansible-playbook site.yml --limit <machine>     # applique sur une seule machine
ansible-playbook maintenance.yml --tags upgrade # mises à jour seules
```

## Adapter à votre environnement

Le dépôt décrit mon homelab réel. Pour le réutiliser, les valeurs propres au
site sont regroupées ici :

- `inventory/inventory.proxmox.yml` : URL de l'API Proxmox ;
- `inventory/group_vars/` : comptes et clés SSH, notifications, serveur PBS,
  montages NFS, bases à sauvegarder ;
- `ansible.cfg` : adresse d'OpenBao ;
- les secrets lus dans OpenBao, au chemin donné par chaque `lookup` dans les
  rôles et playbooks.

Les réglages des rôles sont dans leurs `defaults/` et se surchargent depuis
l'inventaire.
