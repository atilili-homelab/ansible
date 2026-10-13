# ANSIBLE

<!--toc:start-->

- [Ce que fait le dépôt](#ce-que-fait-le-dépôt)
- [Inventaire](#inventaire)
- [Prérequis](#prérequis)
- [Secrets](#secrets)
- [Utilisation](#utilisation)
- [Structure](#structure)
- [Collection](#collection)

<!--toc:end-->

Playbooks et rôles qui configurent les machines de mon homelab : les VM et les
conteneurs LXC de mon cluster Proxmox VE, ainsi qu'un VPS OVH.

C'est la troisième partie de la chaîne : Packer construit les templates,
OpenTofu les clone pour créer les machines, puis Ansible les configure.

## Ce que fait le dépôt

Deux points d'entrée regroupent les playbooks courants :

| Fichier           | Rôle                                                      |
| ----------------- | --------------------------------------------------------- |
| `site.yml`        | Configuration complète d'une machine, du socle au cluster |
| `maintenance.yml` | Mises à jour du système et contrôle de la synchro horaire |

Les playbooks de `playbooks/` se lancent aussi un par un :

| Playbook                     | Rôle                                                             |
| ---------------------------- | ---------------------------------------------------------------- |
| `bootstrap.yml`              | Socle commun, Docker, disques de données, GlusterFS, NFS, Swarm  |
| `upgrade.yml`                | Mise à jour des paquets, redémarrage si nécessaire, notification |
| `dns-setup.yml`              | Serveurs DNS Technitium                                          |
| `openbao-setup.yml`          | Installation d'OpenBao                                           |
| `backup-postgres.yml`        | Sauvegarde quotidienne des bases PostgreSQL                      |
| `swarm-networks.yml`         | Réseaux overlay du cluster Swarm                                 |
| `sync-docker-secrets.yml`    | Copie des secrets d'OpenBao vers les secrets Docker Swarm        |
| `komodo-periphery-setup.yml` | Agent Komodo Periphery sur les hôtes Docker                      |

## Inventaire

L'inventaire est dynamique : `inventory/inventory.proxmox.yml` interroge l'API
de Proxmox et ne retient que les machines démarrées. Les tags posées sur les
machines par OpenTofu deviennent des groupes Ansible, que `inventory/groups.yml`
assemble en groupes fonctionnels (`swarm_managers`, `swarm_workers`, `gluster`,
`nfs_media`…).

Aucun fichier n'est échangé entre OpenTofu et Ansible : ajouter une machine à un
groupe revient à lui poser un tag.

Le VPS, hors du cluster, est décrit dans `inventory/inventory.ovh.ini`.

## Prérequis

- **Nix** avec les flakes activés, et **direnv**.
- **rbw** (client Bitwarden CLI) déverrouillé : il fournit les identifiants
  AppRole d'OpenBao.
- Un accès réseau à **OpenBao**, à l'**API Proxmox** et aux machines en SSH.

Les outils (ansible, ansible-lint, ansible-builder, pre-commit, gitleaks, client
OpenBao) ne sont pas à installer : ils sont fournis par le `flake.nix`, en
versions figées par `flake.lock`.

Les collections et le rôle tiers ne sont pas versionnés dans le dépôt. Leurs
versions sont fixées dans `requirements.yml`, et ils s'installent dans
`~/.ansible` :

```bash
ansible-galaxy install -r requirements.yml
```

## Secrets

Aucun secret n'est stocké dans ce dépôt.

- Les mots de passe et les tokens sont lus dans OpenBao au moment de
  l'exécution, par le plugin `community.hashi_vault`. Le token de l'API Proxmox
  utilisé par l'inventaire suit le même chemin.
- À l'entrée dans le dossier, `.envrc` lit les identifiants de l'AppRole
  `ansible` dans Bitwarden via rbw et les exporte pour Ansible. L'adresse
  d'OpenBao et la méthode d'authentification sont dans `ansible.cfg`.

## Utilisation

```bash
direnv allow                                    # une seule fois : charge l'environnement
ansible-galaxy install -r requirements.yml      # après chaque changement de requirements.yml
ansible-inventory --graph                       # vérifie l'inventaire et les groupes
ansible-playbook site.yml --check --diff        # simulation, sans rien modifier
ansible-playbook site.yml --limit <machine>     # applique sur une seule machine
ansible-playbook maintenance.yml --tags upgrade # mises à jour seules
```

## Structure

| Élément                       | Rôle                                                                       |
| ----------------------------- | -------------------------------------------------------------------------- |
| `site.yml`, `maintenance.yml` | Points d'entrée                                                            |
| `playbooks/`                  | Un playbook par usage                                                      |
| `roles/`                      | Rôles maison                                                               |
| `inventory/`                  | Inventaire dynamique, groupes et variables de groupe                       |
| `ansible.cfg`                 | Configuration d'Ansible pour ce dépôt                                      |
| `requirements.yml`            | Collections et rôle tiers, versions figées                                 |
| `execution-environment.yml`   | Définition de l'image d'exécution, avec `requirements.txt` et `bindep.txt` |
| `galaxy.yml`                  | Déclare le dépôt comme collection `homelab.base`                           |
| `flake.nix`, `.envrc`         | Environnement de développement et connexion à OpenBao                      |

Les rôles :

| Rôle                              | Ce qu'il configure                                       |
| --------------------------------- | -------------------------------------------------------- |
| `common`                          | Paquets de base, chrony, comptes, durcissement SSH, swap |
| `docker`                          | Installation de Docker et configuration du démon         |
| `disk_data`                       | Disque de données des workers                            |
| `glusterfs`, `nfs`                | Stockage partagé et montages réseau                      |
| `swarm`                           | Initialisation du cluster et étiquettes des nœuds        |
| `technitium_dns`, `openbao`       | Services d'infrastructure                                |
| `upgrade`, `upgrade_notification` | Mises à jour et compte rendu par notification            |
| `ntp_check`, `pipx`               | Contrôle de l'heure, installation de pipx                |

## Collection

Les rôles sont aussi distribués sous forme de collection, `homelab.base`, pour
être réutilisés depuis d'autres dépôts sans y être recopiés.

Le dépôt Packer s'en sert pendant le build des templates : il installe la
collection à une version donnée et applique les rôles `common` et `docker`, pour
que les paquets de base, chrony et Docker soient déjà dans l'image. Le socle
d'une machine n'est ainsi écrit qu'à un seul endroit, qu'il soit posé au build
du template ou par le bootstrap.
