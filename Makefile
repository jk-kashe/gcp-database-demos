# Makefile

DEMO_DIRS := alloydb/alloydb-ai-free-trial alloydb/cymbal-air spanner/spanner-standard spanner/finance-advisor

.PHONY: all clean $(DEMO_DIRS)

all: $(DEMO_DIRS)

$(DEMO_DIRS):
	cd $@ && ./.build

# --- Clean Target (remove symlinks) ---

clean:
	find . -type l -delete