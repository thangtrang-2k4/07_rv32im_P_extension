# ======================================================================
# Master Makefile - Coordinates builds across tests and apps
#
# Usage:
#   make all   -> build tests and all apps
#   make clean -> clean tests and all apps
#   make tests -> build only tests
#   make apps  -> build only apps
# ======================================================================

APP_DIRS := apps/filter-fir apps/filter-sobel apps/matrix-multiplication
TEST_DIR := tests

.PHONY: all clean tests apps $(APP_DIRS) $(TEST_DIR)

all: tests apps

tests: $(TEST_DIR)

apps: $(APP_DIRS)

$(TEST_DIR):
	$(MAKE) -C $@ all

$(APP_DIRS):
	$(MAKE) -C $@ all

clean:
	$(MAKE) -C $(TEST_DIR) clean
	for dir in $(APP_DIRS); do \
		$(MAKE) -C $$dir clean; \
	done
