# WordPress Docker Stack

> PHP 8.3 · WordPress 6.x · Apache · MySQL 8.0  
> WPGraphQL · All-In-One WP Migration · JWT Auth for WP REST API

---

## Prérequis

- Docker Desktop >= 4.x
- Make (optionnel)

---

## Démarrage rapide

```bash
# 1. Cloner le dépôt
git clone https://github.com/reyraph/HESSO-Vs-64-31-WebDev-WordPress.git
cd HESSO-Vs-64-31-WebDev-WordPress

# 2. Configurer les variables d'environnement
cp .env.example .env
# Éditer .env avec vos valeurs

# 3. Construire et démarrer
docker compose up -d --build
```

### URLs

| Service | URL |
|---|---|
| WordPress | http://localhost:8080 |
| Admin WP | http://localhost:8080/wp-admin/ |
| GraphQL | <http://localhost:8080/graphql> |
| REST API | http://localhost:8080/wp-json/wp/v2/ |
| phpMyAdmin | http://localhost:8081 |

---

## Plugins

| Plugin | Rôle |
|---|---|
| WPGraphQL | API GraphQL |
| All-In-One WP Migration | Import/export de sites |
| JWT Auth for WP REST API | Authentification stateless sur la REST API |

---

## Commandes utiles

```bash
# Démarrer / arrêter
make up
make down

# Logs
make logs

# WP-CLI
make wp CMD="plugin list"
make wp CMD="core version"

# Nettoyage complet (supprime les volumes !)
make clean
```

---

## REST API

### Lecture publique

```bash
curl http://localhost:8080/wp-json/wp/v2/posts
```

### Avec JWT

```bash
# Obtenir un token
TOKEN=$(curl -s -X POST http://localhost:8080/wp-json/jwt-auth/v1/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"<mot-de-passe>"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

# Créer un article
curl -X POST http://localhost:8080/wp-json/wp/v2/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Hello API","content":"Test","status":"publish"}'
```

---

## Structure du projet

```
.
├── Dockerfile          # Image PHP 8.3 + Apache + WP
├── docker-compose.yml
├── entrypoint.sh       # Installation WP, plugins, thème via WP-CLI
├── wordpress.conf      # VirtualHost Apache
├── php.ini             # Config PHP 8.3
├── my.cnf              # Tuning MySQL 8
├── .env                # Variables locales (non versionné)
├── .env.example        # Template (versionné)
├── Makefile
└── api-tests.http      # Tests REST + GraphQL (VSCode REST Client)
```

---

## Production

- Remplacer `.env` par des **Docker Secrets** ou un **Vault**
- Ajouter un reverse proxy (Nginx/Traefik) avec TLS
- Retirer le service `phpmyadmin` du `docker-compose.yml`
