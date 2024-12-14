# common.mk
MAKEFILE_PATH := $(lastword $(MAKEFILE_LIST))
MAKEFILE_DIR := $(dir $(MAKEFILE_PATH))
TF_DIR = $(MAKEFILE_DIR)/tf
BLOCKS_DIR := ../../.blocks
include $(BLOCKS_DIR)/common.mk

DEMO_OUTPUT_FILE := demo_financial_advisor.tf

.PHONY: demo_cymbal_air_alloydb step2

demo_spanner_financial_advisor: clean build_landing_zone build_spanner_enterprise demo_common build_dataflow_service 
	@$(BLOCKS_DIR)/utils/block.sh $(BLOCKS_DIR)/demos/spanner_finance_advisor $(TF_DIR) $(DEMO_OUTPUT_FILE)

# Build target
build: clean demo_spanner_financial_advisor
	@echo "Building demo: $(notdir $(CURDIR))"
	$(MAKE) fmt