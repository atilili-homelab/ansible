# Changelog

## [2.0.0] - 2026-10-16

### Ajouté

- Rôle `podman` : installation de Podman.
- Rôle `pbs_client` : dépôt et client Proxmox Backup Server.

### Modifié

- Les réglages des rôles passent de `vars/` à `defaults/` : ils se surchargent
  depuis l'inventaire (`group_vars`, `host_vars`).
- Dépendances déclarées : `ansible.posix` et `community.general`, celles
  qu'utilisent réellement les rôles publiés.

### Retiré

- La collection ne contient plus que `common`, `docker`, `podman` et
  `pbs_client`. Les autres rôles restent dans le dépôt, propres au homelab.

## [1.0.0] - 2026-10-13

### Ajouté

- Rôle `common` : paquets de base, chrony, comptes, durcissement SSH, swap.
- Rôle `docker` : installation de Docker et configuration du daemon.
