# Playbooks et rôles

## Points d'entrée

| Fichier           | Rôle                                                      |
| ----------------- | --------------------------------------------------------- |
| `site.yml`        | Bootstrap : socle, Docker, stockage, NFS et cluster Swarm |
| `maintenance.yml` | Mises à jour du système et contrôle de la synchro horaire |

## Playbooks

Les playbooks de `playbooks/` se lancent aussi un par un :

| Playbook                     | Rôle                                                             |
| ---------------------------- | ---------------------------------------------------------------- |
| `bootstrap.yml`              | Socle commun, Docker, disques de données, GlusterFS, NFS, Swarm  |
| `upgrade.yml`                | Mise à jour des paquets, redémarrage si nécessaire, notification |
| `dns-setup.yml`              | Serveurs DNS Technitium                                          |
| `openbao-setup.yml`          | Installation d'OpenBao et de son certificat                      |
| `swarm-networks.yml`         | Réseaux overlay du cluster Swarm                                 |
| `sync-docker-secrets.yml`    | Copie des secrets d'OpenBao vers les secrets Docker Swarm        |
| `komodo-periphery-setup.yml` | Agent Komodo Periphery sur les hôtes Docker                      |
| `ci-forgejo-runner.yml`      | Runner Forgejo Actions sur Podman, Nix et cache Harmonia         |
| `db-backup.yml`              | Sauvegarde quotidienne des bases de données vers PBS             |
| `forgejo-backup.yml`         | Sauvegarde quotidienne de la forge vers PBS                      |
| `pve-nodes.yml`              | Grafana Alloy sur les nœuds Proxmox (métriques et journal)       |

## Rôles

| Rôle                              | Ce qu'il configure                                                       |
| --------------------------------- | ------------------------------------------------------------------------ |
| `common`                          | Paquets de base, chrony, comptes, durcissement SSH, swap                 |
| `docker`                          | Installation de Docker et configuration du démon                         |
| `podman`                          | Installation de Podman                                                   |
| `disk_data`                       | Disque de données des workers                                            |
| `glusterfs`, `nfs`                | Stockage partagé et montages réseau                                      |
| `swarm`                           | Initialisation du cluster et étiquettes des nœuds                        |
| `technitium_dns`, `openbao`       | Services d'infrastructure                                                |
| `certbot`                         | Certificats Let's Encrypt par challenge DNS-01 Cloudflare (pour OpenBao) |
| `forgejo_runner`                  | Runner Forgejo Actions sans root, jobs dans Podman ou sur l'hôte         |
| `nix`                             | Nix (paquets Debian) sur disque dédié `/nix`, builds hors tmpfs, GC auto |
| `harmonia`                        | Cache binaire Nix servant `/nix/store` en HTTP                           |
| `pbs_client`                      | Dépôt et client Proxmox Backup Server                                    |
| `alloy`                           | Grafana Alloy en observateur (métriques unix, journal)                   |
| `forgejo_backup`                  | Sauvegarde de la forge vers PBS                                          |
| `db_backup`                       | Dumps des bases conteneurisées (PostgreSQL, MariaDB, MongoDB) vers PBS   |
| `upgrade`, `upgrade_notification` | Mises à jour et compte rendu par notification                            |
| `ntp_check`                       | Contrôle de la synchronisation horaire                                   |

Les bases à sauvegarder sont déclarées dans `db_backup_targets`
(`inventory/group_vars/tier_database.yml`) ; les champs d'une cible sont
décrits dans `roles/db_backup/defaults/main.yml`.

## Collection `homelab.base`

Les rôles génériques sont aussi distribués sous forme de collection,
`homelab.base`, pour être réutilisés depuis d'autres dépôts sans y être
recopiés. Elle ne contient que `common`, `docker`, `podman` et `pbs_client` ; les
autres rôles sont propres à ce homelab et restent dans le dépôt.

Le dépôt Packer s'en sert pendant le build des templates : il installe la
collection à une version donnée et applique les rôles `common` et `docker`, pour
que les paquets de base, chrony et Docker soient déjà dans l'image. Le socle
d'une machine n'est ainsi écrit qu'à un seul endroit, qu'il soit posé au build
du template ou par le bootstrap.
