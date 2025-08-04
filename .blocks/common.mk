
# Function to create symlinks
define create_symlink
    @$(BLOCKS_DIR)/utils/lns.sh $(1) $(TF_DIR)
endef

define create_files_symlink
    @$(BLOCKS_DIR)/utils/lns.sh $(1) $(TF_DIR)/files
endef

# Phony targets
.PHONY: login build clean apply destroy build_provider \
build_landing_zone build_spanner_generic build_spanner_standard build_spanner_enterprise \
auto-vars.sh set-vars.sh $(TF_DIR) build_dataflow_service

$(TF_DIR):
	@mkdir -p $@
	@mkdir -p $@/files

auto-vars.sh: $(TF_DIR)
	$(call create_files_symlink,$(BLOCKS_DIR)/utils/auto-vars.sh)

set-vars.sh: $(TF_DIR)
	$(call create_files_symlink,$(BLOCKS_DIR)/utils/set-vars.sh)

##############
# LANDING ZONE
build_provider: auto-vars.sh set-vars.sh
	@$(BLOCKS_DIR)/utils/block.sh $(BLOCKS_DIR)/0_landing_zone/provider $(TF_DIR) provider.tf

build_landing_zone: build_provider 
	@$(BLOCKS_DIR)/utils/block.sh $(BLOCKS_DIR)/0_landing_zone $(TF_DIR) landing_zone.tf

build_dataflow_service: build_landing_zone
	@$(BLOCKS_DIR)/utils/block.sh $(BLOCKS_DIR)/0_landing_zone/dataflow $(TF_DIR) landing_zone.tf


#########
# SPANNER
build_spanner_generic: $(TF_DIR) build_landing_zone 
	@$(BLOCKS_DIR)/utils/block.sh $(BLOCKS_DIR)/db/spanner $(TF_DIR) spanner.tf

build_spanner_standard: build_spanner_generic
	@cat $(BLOCKS_DIR)/db/spanner/vars-optional-standard-edition.tf >> $(TF_DIR)/variables.tf

build_spanner_enterprise: build_spanner_generic
	@cat $(BLOCKS_DIR)/db/spanner/vars-optional-enterprise-edition.tf >> $(TF_DIR)/variables.tf


##########
# ALLOY DB
build_alloydb_generic: $(TF_DIR) build_landing_zone
	@$(BLOCKS_DIR)/utils/block.sh $(BLOCKS_DIR)/db/alloydb $(TF_DIR) alloydb.tf

build_alloydb_trial: build_alloydb_generic
	@cat $(BLOCKS_DIR)/db/alloydb/vars-optional-trial-instance.tf >> $(TF_DIR)/variables.tf

build_alloydb_standard: build_alloydb_generic
	@cat $(BLOCKS_DIR)/db/alloydb/vars-optional-standard-instance.tf >> $(TF_DIR)/variables.tf


#############
# COMMON DEMO
demo_common:
	@$(BLOCKS_DIR)/utils/block.sh $(BLOCKS_DIR)/demos/common $(TF_DIR) $(DEMO_OUTPUT_FILE)


# Run Terraform fmt (common)
fmt:
	@cd $(TF_DIR) && terraform fmt

# Run Terraform apply (common)
apply: auto-vars.sh set-vars.sh
	@echo "Applying demo: $(notdir $(CURDIR))"
	@cd $(TF_DIR) && ./files/set-vars.sh && terraform init && terraform apply -auto-approve

# Run Terraform apply (common)
deploy: apply

# Run Terraform destroy (common)
destroy:
	@echo "Destroying demo: $(notdir $(CURDIR))"
	@cd $(TF_DIR) && terraform destroy -auto-approve

# Clean target
clean:
	@echo "WARNING: This will destroy the Terraform state and delete the configuration for demo: $(notdir $(CURDIR))"
	@echo "All Terraform-managed resources will be destroyed, and the 'tf' directory will be removed."
	@echo "You will lose all your Terraform state and configuration for this demo!"
	@read -r -p "Are you sure you want to proceed? This action cannot be undone! (yes/no): " CONFIRM; \
	if [ "$$CONFIRM" = "yes" ]; then \
		echo "Cleaning demo: $(notdir $(CURDIR))" ; \
		rm -rf $(TF_DIR) ; \
		rm -f *.sh; \
	else \
		echo "Clean operation cancelled." ; \
	fi

login:
	@gcloud auth login
	@gcloud auth application-default login
	@read -p "Enter Project ID: " PROJECT_ID; \
	gcloud config set project $$PROJECT_ID; \
	gcloud auth application-default set-quota-project $$PROJECT_ID;