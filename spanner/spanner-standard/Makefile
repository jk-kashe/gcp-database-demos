# common.mk
MAKEFILE_PATH := $(lastword $(MAKEFILE_LIST))
MAKEFILE_DIR := $(dir $(MAKEFILE_PATH))
TF_DIR = $(MAKEFILE_DIR)/tf
BLOCKS_DIR := ../../blocks
include $(BLOCKS_DIR)/common.mk

# Build target
build: build_landing_zone build_spanner_standard
	@echo "Building demo: $(notdir $(CURDIR))"
	$(MAKE) fmt

