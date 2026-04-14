# ═══════════════════════════════════════════════════════════
#  Makefile  –  Raccourcis Docker Compose
# ═══════════════════════════════════════════════════════════
.PHONY: up down build rebuild logs shell wp clean reset help

## Démarrer les services (mode détaché)
up:
	docker compose up -d

## Stopper les services
down:
	docker compose down

## Construire l'image WordPress
build:
	docker compose build wordpress

## Reconstruire sans cache
rebuild:
	docker compose build --no-cache wordpress

## Afficher les logs en live
logs:
	docker compose logs -f wordpress

## Logs MySQL
logs-db:
	docker compose logs -f db

## Ouvrir un shell dans le container WordPress
shell:
	docker compose exec wordpress bash

## Exécuter une commande WP-CLI
##  Usage : make wp CMD="post list"
wp:
	docker compose exec wordpress wp --allow-root $(CMD)

## Supprimer containers + volumes (⚠ supprime les données DB)
clean:
	docker compose down -v --remove-orphans

## Reset complet (clean + rebuild)
reset: clean rebuild up

## Afficher ce message d'aide
help:
	@echo ""
	@echo "  Commandes disponibles :"
	@echo "  ─────────────────────────────────────────"
	@echo "  make up          Démarrer"
	@echo "  make down        Stopper"
	@echo "  make build       Builder l'image WP"
	@echo "  make rebuild     Rebuild sans cache"
	@echo "  make logs        Logs WordPress"
	@echo "  make logs-db     Logs MySQL"
	@echo "  make shell       Shell dans WP container"
	@echo "  make wp CMD=...  WP-CLI direct"
	@echo "  make clean       Supprimer containers+volumes"
	@echo "  make reset       clean + rebuild + up"
	@echo ""
