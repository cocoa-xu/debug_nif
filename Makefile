ROOT_PRIV_DIR = $(shell pwd)/priv
ERL_CACHE_PRIV_DIR = $(ERLANG_CACHE_DIR)/debug_nif/priv
PRIV_DIR = $(MIX_APP_PATH)/priv
NIF_SO = $(PRIV_DIR)/debug.so

C_SRC = $(shell pwd)/c_src
LIB_SRC = $(shell pwd)/lib
CPPFLAGS += -shared -std=c++14 -O3 -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -fPIC
CPPFLAGS += -I"$(ERTS_INCLUDE_DIR)"

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	CPPFLAGS += -undefined dynamic_lookup -flat_namespace -undefined suppress
endif

.DEFAULT_GLOBAL := build

build: $(NIF_SO)

$(NIF_SO):
	@ mkdir -p $(PRIV_DIR)
	@ mkdir -p $(ROOT_PRIV_DIR)
	@ mkdir -p $(ERL_CACHE_PRIV_DIR)
	$(CC) $(CPPFLAGS) $(C_SRC)/debug_nif.cpp -o $(NIF_SO)
	@ cp -a $(NIF_SO) $(ROOT_PRIV_DIR)/debug.so
	@ cp -a $(NIF_SO) $(ERL_CACHE_PRIV_DIR)/debug.so

