# common.mk
MAKEFILE_PATH := $(lastword $(MAKEFILE_LIST))
MAKEFILE_DIR := $(dir $(MAKEFILE_PATH))
TF_DIR = $(MAKEFILE_DIR)/tf
BLOCKS_DIR := ../../blocks
include $(BLOCKS_DIR)/common.mk

# Build target
build: clean build_alloydb_trial
	@echo "Building demo: $(notdir $(CURDIR))"
	$(MAKE) fmt

