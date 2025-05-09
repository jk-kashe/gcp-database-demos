# common.mk
MAKEFILE_PATH := $(lastword $(MAKEFILE_LIST))
MAKEFILE_DIR := $(dir $(MAKEFILE_PATH))
TF_DIR = $(MAKEFILE_DIR)/tf
BLOCKS_DIR := ../../.blocks
include $(BLOCKS_DIR)/common.mk

DEMO_OUTPUT_FILE := demo_agentspace_alloydb.tf

#############
# DEMO CYMBAl AIR
demo_agentspace_alloydb: build_alloydb_trial demo_common
	@$(BLOCKS_DIR)/utils/block.sh $(BLOCKS_DIR)/demos/agentspace_alloydb $(TF_DIR) $(DEMO_OUTPUT_FILE)

# Build target
build: clean demo_agentspace_alloydb
	@echo "Building demo: $(notdir $(CURDIR))"
	$(MAKE) fmt