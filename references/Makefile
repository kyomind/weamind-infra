APP_SERVICE=app

.PHONY: dev-up clean setup-prod up down deploy migrate revision rollback

# === Container & Image Management ===
dev-up:
	docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d

clean:
	docker compose -f docker-compose.yml -f docker-compose.dev.yml down -v

setup-prod:
	docker volume create wea-db-data-prod
	docker network create wea-net || true

up:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build

down:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml down

deploy:
	@echo "🚀 開始部署..."
	@echo "📦 建立並啟動容器..."
	docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d
	@echo "⏳ 等待資料庫服務啟動..."
	@until docker compose exec db pg_isready -U wea_bot -d weamind -q; do \
		echo "等待資料庫準備中..."; \
		sleep 2; \
	done
	@echo "🔄 執行資料庫遷移..."
	@if docker compose exec $(APP_SERVICE) uv run alembic upgrade head; then \
		echo "✅ 資料庫遷移完成"; \
	else \
		echo "⚠️  資料庫遷移失敗，請檢查是否有新的遷移檔案或資料庫連線"; \
	fi
	@echo "✅ 部署完成！"

# === Database Migration ===
migrate:
	docker compose exec $(APP_SERVICE) uv run alembic upgrade head

revision:
	docker compose exec $(APP_SERVICE) uv run alembic revision --autogenerate -m "$(shell git rev-parse --abbrev-ref HEAD)_$(shell date +%Y%m%d_%H%M%S)"

rollback:
	docker compose exec $(APP_SERVICE) uv run alembic downgrade -1
