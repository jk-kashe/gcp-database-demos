# Makefile

DEMO_DIRS := alloydb/alloydb-ai-free-trial alloydb/agentspace alloydb/cymbal-air spanner/spanner-standard spanner/finance-advisor

.PHONY: all clean $(DEMO_DIRS)

all: $(DEMO_DIRS)

$(DEMO_DIRS):
	$(MAKE) -C $@ build

# --- Clean Target (remove symlinks) ---

clean:
	for dir in $(DEMO_DIRS); do \
		$(MAKE) -C $$dir clean; \
	done