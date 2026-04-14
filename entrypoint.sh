#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  entrypoint.sh
#  Lance Apache après avoir configuré WordPress via WP-CLI
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

WP_DIR="/var/www/html"
WP_CLI="wp --allow-root --path=${WP_DIR}"

# ── Couleurs pour les logs ──────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[WP-SETUP]${NC} $*"; }
warn() { echo -e "${YELLOW}[WP-SETUP]${NC} $*"; }
err()  { echo -e "${RED}[WP-SETUP]${NC} $*" >&2; }

# ── Attendre MySQL ──────────────────────────────────────────────
wait_for_mysql() {
    log "Attente de MySQL (${WORDPRESS_DB_HOST})…"
    local retries=40
    until mysqladmin ping \
        -h "${WORDPRESS_DB_HOST%%:*}" \
        -P "${WORDPRESS_DB_HOST##*:}" \
        -u "${WORDPRESS_DB_USER}" \
        -p"${WORDPRESS_DB_PASSWORD}" \
        --silent 2>/dev/null; do
        retries=$((retries - 1))
        if [[ $retries -le 0 ]]; then
            err "MySQL inaccessible après 40 tentatives – abandon."
            exit 1
        fi
        sleep 3
    done
    log "MySQL prêt."
}

# ── Générer wp-config.php ───────────────────────────────────────
create_wp_config() {
    if [[ -f "${WP_DIR}/wp-config.php" ]]; then
        warn "wp-config.php déjà présent – ignoré."
        return
    fi
    log "Génération de wp-config.php…"
    $WP_CLI config create \
        --dbname="${WORDPRESS_DB_NAME}" \
        --dbuser="${WORDPRESS_DB_USER}" \
        --dbpass="${WORDPRESS_DB_PASSWORD}" \
        --dbhost="${WORDPRESS_DB_HOST}" \
        --dbprefix="${WORDPRESS_TABLE_PREFIX:-wp_}" \
        --dbcharset="utf8mb4" \
        --dbcollate="utf8mb4_unicode_ci" \
        --locale="fr_FR" \
        --extra-php <<'PHP'
/** Activation de HTTPS derrière un reverse proxy */
if ( isset( $_SERVER['HTTP_X_FORWARDED_PROTO'] ) && 'https' === $_SERVER['HTTP_X_FORWARDED_PROTO'] ) {
    $_SERVER['HTTPS'] = 'on';
}

/** WP GraphQL – désactiver introspection en prod si besoin */
define( 'GRAPHQL_DEBUG', false );

/** REST API – activer les namespaces personnalisés */
define( 'WP_REST_CACHE', false );

/** Augmenter la mémoire WP */
define( 'WP_MEMORY_LIMIT', '256M' );

/** Désactiver l'éditeur de thèmes/plugins dans l'admin */
define( 'DISALLOW_FILE_EDIT', true );

/** Révisions limitées */
define( 'WP_POST_REVISIONS', 5 );

/** Corbeille automatique (jours) */
define( 'EMPTY_TRASH_DAYS', 14 );
PHP
    log "wp-config.php créé."
}

# ── Installer WordPress core ────────────────────────────────────
install_wp_core() {
    if $WP_CLI core is-installed 2>/dev/null; then
        warn "WordPress déjà installé – ignoré."
        return
    fi
    log "Installation de WordPress core…"
    $WP_CLI core install \
        --url="${WP_SITEURL:-http://localhost:8080}" \
        --title="${WP_SITE_TITLE:-WordPress Dev}" \
        --admin_user="${WP_ADMIN_USER:-admin}" \
        --admin_password="${WP_ADMIN_PASSWORD:-admin}" \
        --admin_email="${WP_ADMIN_EMAIL:-admin@example.com}" \
        --skip-email
    log "WordPress core installé."
}

# ── Installer le thème Twenty Fourteen ─────────────────────────
install_theme() {
    if $WP_CLI theme is-installed twentyfourteen 2>/dev/null; then
        warn "Thème twentyfourteen déjà installé."
    else
        log "Installation du thème Twenty Fourteen…"
        $WP_CLI theme install twentyfourteen --activate
    fi
    $WP_CLI theme activate twentyfourteen
    log "Thème Twenty Fourteen activé."
}

# ── Installer et activer les plugins ───────────────────────────
install_plugins() {
    # ── 1. WPGraphQL ──────────────────────────────────────────
    if $WP_CLI plugin is-installed wp-graphql 2>/dev/null; then
        warn "WPGraphQL déjà installé."
    else
        log "Installation de WPGraphQL…"
        $WP_CLI plugin install wp-graphql --activate
    fi

    # ── 2. All-In-One WP Migration ────────────────────────────
    if $WP_CLI plugin is-installed all-in-one-wp-migration 2>/dev/null; then
        warn "All-In-One WP Migration déjà installé."
    else
        log "Installation de All-In-One WP Migration…"
        $WP_CLI plugin install all-in-one-wp-migration --activate
    fi

    # ── 3. JWT Authentication for WP REST API ────────────────
    #  La WP REST API (v2) est intégrée au core depuis WP 4.7.
    #  Ce plugin ajoute une couche d'authentification JWT pour
    #  sécuriser les endpoints REST sans session/cookie.
    #  Slug officiel : jwt-authentication-for-wp-rest-api
    if $WP_CLI plugin is-installed jwt-authentication-for-wp-rest-api 2>/dev/null; then
        warn "JWT Auth pour REST API déjà installé."
    else
        log "Installation de JWT Authentication for WP REST API…"
        $WP_CLI plugin install jwt-authentication-for-wp-rest-api --activate
    fi

    log "Tous les plugins sont actifs."
}

# ── Réglages WordPress post-install ────────────────────────────
configure_wp() {
    log "Configuration des permaliens (post name)…"
    $WP_CLI rewrite structure '/%postname%/' --hard

    log "Mise à jour des règles de réécriture…"
    $WP_CLI rewrite flush --hard

    log "Passage du site en français…"
    $WP_CLI language core install fr_FR --activate || true

    log "Configuration terminée."
}

# ── Ajuster les permissions ─────────────────────────────────────
fix_permissions() {
    chown -R www-data:www-data "${WP_DIR}"
    find "${WP_DIR}" -type d -exec chmod 755 {} \;
    find "${WP_DIR}" -type f -exec chmod 644 {} \;
    chmod 600 "${WP_DIR}/wp-config.php" 2>/dev/null || true
}

# ══════════════════════════════════════════════
#  Pipeline principal
# ══════════════════════════════════════════════
main() {
    wait_for_mysql
    create_wp_config
    install_wp_core
    install_theme
    install_plugins
    configure_wp
    fix_permissions
    log "🚀  WordPress prêt sur ${WP_SITEURL:-http://localhost:8080}"
    log "    GraphQL   → ${WP_SITEURL:-http://localhost:8080}/graphql"
    log "    REST API  → ${WP_SITEURL:-http://localhost:8080}/wp-json/wp/v2/"
    log "    Admin     → ${WP_SITEURL:-http://localhost:8080}/wp-admin/"
    exec apache2-foreground
}

main "$@"
