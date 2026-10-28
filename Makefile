# Полный цикл с нуля: make install up all
VENV      ?= .venv
BIN       := $(VENV)/bin
DBT_DIR   := dbt
DBT       := cd $(DBT_DIR) && ../$(BIN)/dbt
DBT_FLAGS := --profiles-dir .
DOCS_PORT ?= 8080

.PHONY: help install up down data-check deps seed run test unit-test build docs docs-serve \
        lint fix pre-commit-install pre-commit all clean

help:  ## Список команд
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "} {printf "  %-20s %s\n", $$1, $$2}'

install:  ## Создать venv и поставить dbt, sqlfluff, pre-commit
	python3 -m venv $(VENV)
	$(BIN)/pip install --upgrade pip
	$(BIN)/pip install -r requirements.txt

up:  ## Поднять ClickHouse и загрузить data/train.csv (ждёт healthcheck)
	docker-compose up -d
	@echo "Waiting for ClickHouse to load data..."
	@until [ "$$(docker inspect -f '{{.State.Health.Status}}' fraudlens-clickhouse)" = "healthy" ]; do sleep 3; done
	@$(MAKE) --no-print-directory data-check

down:  ## Остановить ClickHouse (данные удаляются вместе с контейнером)
	docker-compose down

data-check:  ## Число строк в исходной таблице
	@docker exec fraudlens-clickhouse clickhouse-client -q "SELECT count() AS rows FROM transactions_db.transactions"

deps:  ## dbt deps
	$(DBT) deps $(DBT_FLAGS)

seed:  ## dbt seed
	$(DBT) seed $(DBT_FLAGS)

run:  ## dbt run
	$(DBT) run $(DBT_FLAGS)

test:  ## dbt test (data tests + unit tests)
	$(DBT) test $(DBT_FLAGS)

unit-test:  ## Только unit tests
	$(DBT) test $(DBT_FLAGS) --select "test_type:unit"

build:  ## dbt build (seed + run + test в порядке DAG)
	$(DBT) build $(DBT_FLAGS)

docs:  ## Сгенерировать dbt Docs
	$(DBT) docs generate $(DBT_FLAGS)

docs-serve: docs  ## Сгенерировать и открыть dbt Docs на http://localhost:$(DOCS_PORT)
	$(DBT) docs serve $(DBT_FLAGS) --port $(DOCS_PORT)

lint:  ## sqlfluff lint
	$(BIN)/sqlfluff lint $(DBT_DIR)/models $(DBT_DIR)/tests

fix:  ## sqlfluff fix
	$(BIN)/sqlfluff fix $(DBT_DIR)/models $(DBT_DIR)/tests

pre-commit-install:  ## Установить git-хуки pre-commit
	$(BIN)/pre-commit install

pre-commit:  ## Прогнать pre-commit по всем файлам
	$(BIN)/pre-commit run --all-files

all: deps seed run test  ## Полный цикл: deps -> seed -> run -> test

clean:  ## Удалить артефакты dbt
	$(DBT) clean $(DBT_FLAGS)
