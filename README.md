# WordPress Docker Stack

> **PHP 8.3 · WordPress 6.9.4 · Apache · MySQL 8.0**  
> WPGraphQL · All-In-One WP Migration · WP REST API v2 + JWT Auth

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  docker-compose                                         │
│                                                         │
│  ┌─────────────────────┐   ┌──────────────────────────┐ │
│  │  wordpress (wp_app) │   │  db (wp_mysql)           │ │
│  │  PHP 8.3 + Apache   │──▶│  MySQL 8.0               │ │
│  │  Port: 8080         │   │  Volume: db_data         │ │
│  └─────────────────────┘   └──────────────────────────┘ │
│           │                                             │
│  ┌────────────────────┐                                 │
│  │  phpmyadmin        │                                 │
│  │  Port: 8081        │                                 │
│  └────────────────────┘                                 │
└─────────────────────────────────────────────────────────┘
```

## Plugins installés

| Plugin | Rôle | Endpoint |
|---|---|---|
| **WPGraphQL** | API GraphQL pour WP | `/graphql` |
| **All-In-One WP Migration** | Import/export de sites | Admin UI |
| **JWT Auth for WP REST API** | Sécurisation de la REST API | `/wp-json/jwt-auth/v1/token` |

> **Note sur la REST API :** La WordPress REST API v2 est **intégrée au core** depuis  
> WordPress 4.7. Il n'est pas nécessaire d'installer un plugin séparé pour l'activer.  
> Le plugin **JWT Authentication for WP REST API** (`jwt-authentication-for-wp-rest-api`)  
> est installé ici pour ajouter une authentification sans état (stateless), indispensable  
> pour les clients JavaScript/mobile/headless qui consomment l'API REST.

---

## Obtenir le projet depuis GitHub

### Option 1 — `git clone` (recommandé)

```bash
# Cloner le dépôt dans un dossier local
git clone https://github.com/<votre-organisation>/wordpress-docker.git

# Entrer dans le dossier
cd wordpress-docker
```

> Remplacer `<votre-organisation>` par votre nom d'utilisateur ou organisation GitHub.

---

### Option 2 — Télécharger l'archive ZIP (sans Git)

1. Ouvrir la page du dépôt sur GitHub :  
   `https://github.com/<votre-organisation>/wordpress-docker`
2. Cliquer sur le bouton vert **`<> Code`**
3. Choisir **Download ZIP**
4. Décompresser l'archive, puis ouvrir un terminal dans le dossier extrait

```bash
# macOS / Linux
unzip wordpress-docker-main.zip
cd wordpress-docker-main

# Windows (PowerShell)
Expand-Archive wordpress-docker-main.zip -DestinationPath .
cd wordpress-docker-main
```

---

### Option 3 — GitHub CLI

```bash
# Installer gh si nécessaire : https://cli.github.com
gh repo clone <votre-organisation>/wordpress-docker
cd wordpress-docker
```

---

### Publier votre propre fork sur GitHub

Si vous souhaitez versionner ce projet depuis zéro :

```bash
# 1. Initialiser Git dans le dossier du projet
git init
git add .
git commit -m "chore: initial WordPress Docker stack"

# 2. Créer un dépôt vide sur GitHub (sans README ni .gitignore)
#    puis lier le remote :
git remote add origin https://github.com/<votre-organisation>/wordpress-docker.git

# 3. Pousser la branche principale
git branch -M main
git push -u origin main
```

> ⚠️ Le fichier `.env` est dans `.gitignore` — vos mots de passe ne seront **jamais**
> poussés sur GitHub. Seul `.env.example` (sans valeurs sensibles) est versionné.

---

## Prérequis

- Docker Desktop ≥ 4.x (ou Docker Engine + Compose plugin)
- Git ≥ 2.x (pour le clonage)
- Make (optionnel mais recommandé)
- VSCode avec les extensions listées dans `.vscode/extensions.json`

---

## Démarrage rapide

```bash
# 1. Cloner le dépôt (voir section "Obtenir le projet depuis GitHub")
git clone https://github.com/<votre-organisation>/wordpress-docker.git
cd wordpress-docker

# 2. Copier et adapter les variables d'environnement
cp .env.example .env
# Éditer .env avec vos valeurs

# 3. Construire et démarrer
make up
# ou : docker compose up -d --build

# 4. Attendre ~60s le premier démarrage (installation WP + plugins)
make logs
```

### URLs après démarrage

| Service | URL |
|---|---|
| WordPress | http://localhost:8080 |
| Admin WP | http://localhost:8080/wp-admin/ |
| GraphQL Playground | http://localhost:8080/graphql |
| REST API | http://localhost:8080/wp-json/wp/v2/ |
| phpMyAdmin | http://localhost:8081 |

---

## Vérification de la version WordPress

> Vérifier que la version **6.9.4** est disponible sur https://wordpress.org/news/category/releases/  
> avant de builder. Si elle n'est pas encore publiée, modifier `ARG WP_VERSION` dans  
> `docker/wordpress/Dockerfile`.

---

## Utiliser la REST API

### Sans authentification (lecture publique)

```bash
# Articles
curl http://localhost:8080/wp-json/wp/v2/posts

# Pages
curl http://localhost:8080/wp-json/wp/v2/pages

# Catégories
curl http://localhost:8080/wp-json/wp/v2/categories
```

### Avec JWT (écriture / données privées)

```bash
# 1. Obtenir un token
TOKEN=$(curl -s -X POST http://localhost:8080/wp-json/jwt-auth/v1/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Admin@Secure2024!"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

# 2. Créer un article
curl -X POST http://localhost:8080/wp-json/wp/v2/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Hello API","content":"Test","status":"publish"}'
```

---

## Utiliser WPGraphQL

```graphql
# Récupérer les 5 derniers articles
{
  posts(first: 5) {
    nodes {
      id
      title
      date
      excerpt
      author {
        node { name }
      }
    }
  }
}
```

Playground interactif : http://localhost:8080/graphql

---

## Commandes WP-CLI utiles

```bash
# Via Makefile
make wp CMD="post list"
make wp CMD="plugin list"
make wp CMD="theme list"
make wp CMD="user list"

# Via docker compose exec
docker compose exec wordpress wp --allow-root plugin list
docker compose exec wordpress wp --allow-root core version
docker compose exec wordpress wp --allow-root cache flush
```

---

## Structure du projet

```
wordpress-docker/
├── .vscode/
│   ├── extensions.json     ← extensions recommandées
│   └── settings.json       ← config éditeur + REST Client
├── config/
│   ├── apache/
│   │   └── wordpress.conf  ← VirtualHost Apache
│   ├── mysql/
│   │   └── my.cnf          ← tuning MySQL 8
│   └── php/
│       └── php.ini         ← PHP 8.3 optimisé WP
├── docker/
│   └── wordpress/
│       └── Dockerfile      ← image PHP 8.3 + Apache + WP 6.9.4
├── scripts/
│   └── entrypoint.sh       ← installation WP, plugins, thème
├── .env                    ← variables locales (non commitable)
├── .env.example            ← template (commitable)
├── .gitignore
├── api-tests.http          ← tests REST + GraphQL (REST Client)
├── docker-compose.yml
├── Makefile
└── README.md
```

---

## Arrêt et nettoyage

```bash
# Stopper sans perdre les données
make down

# Supprimer tout (containers + volumes DB !)
make clean
```

---

## Passage en production

- Remplacer le `.env` par des **Docker Secrets** ou un **Vault**
- Ajouter un **reverse proxy** (Nginx/Traefik) avec **Let's Encrypt**
- Passer `display_errors = Off` (déjà fait) et surveiller `/var/log/php_errors.log`
- Supprimer le service `phpmyadmin` du `docker-compose.yml`
- Activer `session.cookie_secure = 1` dans `php.ini`
- Limiter les headers CORS Apache à votre domaine réel
