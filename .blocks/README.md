# Demo Building Blocks

**Target Audience:** Demo Packagers

This document provides an overview of the building blocks used to create demo terraform deployment scripts. 

**What's Here?**

* Common blocks(components) for constructing final demo terraform scripts.
* Makefile integration for weaving these blocks together.
* Independent demo packaging - updates to one demo don't require changes to others.

**Packaging Process**

* Core Script: `utils/block.sh` handles core packaging logic.
* TF Files:
    * All non-optional `.tf` files are concatenated into a single output file (specified in the Makefile).
    * All non-optional `*vars*.tf` files are combined into a single `variables.tf` file (shared across all blocks).
* Templates & Files:
    * `templates` folder is copied to `tf/templates` (ensure unique template names to avoid overwrites).
    * `files` folder is copied to `tf/files` (ensure unique file names to avoid overwrites).
* Packaging Logic:
    * Most logic resides in `common.mk` and utility scripts.
* Makefiles:
    * Each demo requires a Makefile (copy one from an existing demo).

**Directory Structure**

* **0_landing_zone:**
    * Provides foundational resources like providers, project setup, networking, APIs, etc.
    * Assumes all demos deploy a client VM for database access.
    * `dataflow` block (optional) enables DataFlow APIs, e.g. to facilitates Spanner imports.
* **db/alloydb:**
    * Provisions AlloyDB instances with AI features.
    * Supports both standard and trial deployments based on included variables.
    * `common.mk` defines pre-built targets for trial and standard deployments.
* **db/spanner:**
    * Provisions Spanner instances.
    * Supports both standard and enterprise deployments based on included variables.
    * `common.mk` defines pre-built targets for standard and enterprise deployments.
* **demos:**
    * Contains individual demo files.
    * Non-generic demos might be better suited elsewhere, but packaging them with the final demo simplifies management.

**Common Makefile Targets**

* **build_landing_zone:**
    * Provisions the landing zone with networking, APIs, and a client VM.
    * Requires client VM variables (provided by other blocks or optional packaged variables).
* **build_dataflow_service:**
    * Enables the DataFlow API.
* **build_spanner_standard/enterprise:**
    * Provisions landing zone + Spanner (standard/enterprise edition).
* **build_alloydb_trial/standard:**
    * Provisions landing zone + AlloyDB (free trial/standard edition) with AI enabled.
