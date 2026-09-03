MODULE_big = topnbench
OBJS = topnbench.o

EXTENSION = topnbench
DATA = topnbench--1.0.sql

PG_CONFIG ?= pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
