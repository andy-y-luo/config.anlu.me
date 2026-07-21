DIRS := $(wildcard */)

.PHONY: all tangle
all: tangle

tangle:
	@set -e; for dir in $(DIRS); do \
		if [ -f "$$dir/Makefile" ]; then \
			echo "==> Tangling $$dir"; \
			$(MAKE) -C $$dir tangle; \
		fi; \
	done
