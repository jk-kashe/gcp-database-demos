# common.mk
MAKEFILE_PATH := $(lastword $(MAKEFILE_LIST))
MAKEFILE_DIR := $(dir $(MAKEFILE_PATH))
TF_DIR = $(MAKEFILE_DIR)/tf
BLOCKS_DIR := ../../blocks
include $(BLOCKS_DIR)/common.mk

DEMO_OUTPUT_FILE := demo_cymbal_air.tf

.PHONY: demo_cymbal_air_alloydb step2

#############
# DEMO CYMBAl AIR
demo_cymbal_air_alloydb: build_alloydb_trial demo_common
	@$(BLOCKS_DIR)/utils/block.sh $(BLOCKS_DIR)/demos/cymbal_air $(TF_DIR) $(DEMO_OUTPUT_FILE)

# Build target
build: clean demo_cymbal_air_alloydb
	@echo "Building demo: $(notdir $(CURDIR))"
	$(MAKE) fmt

step2:
	@cp $(TF_DIR)/files/demo-cymbal-air-20-oauth.tf.step2 $(TF_DIR)/demo-cymbal-air-20-oauth.tf
	@cp $(TF_DIR)/files/vars-demo-cymbal-air-oauth.tf.step2 $(TF_DIR)/vars-demo-cymbal-air-oauth.tf
	$(MAKE) apply