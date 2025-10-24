.PHONY: demo demo-docker demo-local
demo-local:
	@POSTGRES_HOST=$${POSTGRES_HOST:-localhost}; \
	POSTGRES_PORT=$${POSTGRES_PORT:-6543}; \
	SKIP_TWEETS=$${SKIP_TWEETS:-1}; \
	PYTHONPATH=.; \
	export POSTGRES_HOST POSTGRES_PORT SKIP_TWEETS PYTHONPATH; \
	python -m scripts.ingest && \
	python -m scripts.run_sentiment && \
	python -m scripts.compute_indices

demo-docker:
	@POSTGRES_HOST=$${POSTGRES_HOST:-db}; \
	POSTGRES_PORT=$${POSTGRES_PORT:-5432}; \
	SKIP_TWEETS=$${SKIP_TWEETS:-1}; \
	PYTHONPATH=.; \
	export POSTGRES_HOST POSTGRES_PORT SKIP_TWEETS PYTHONPATH; \
	python -m scripts.ingest && \
	python -m scripts.run_sentiment && \
	python -m scripts.compute_indices

.PHONY: bootstrap
bootstrap:
	@echo "▶ Starting db + adminer…"
	docker compose up -d db adminer
	@echo "▶ Waiting for Postgres to be ready…"
	@until docker exec africa-momentum-index-db pg_isready -U ami -d ami >/dev/null 2>&1; do sleep 1; done
	@echo "▶ Applying schema…"
	docker exec -i africa-momentum-index-db psql -U ami -d ami < sql/schema.sql
	@echo "▶ Ingest → sentiment → indices…"
	docker compose run --rm streamlit bash -lc "make demo-docker"
	@echo "▶ Starting Streamlit…"
	docker compose up -d streamlit
	@echo "✅ Done: http://localhost:8501  |  Adminer: http://localhost:8081"
