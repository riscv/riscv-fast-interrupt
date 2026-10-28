# Makefile for RISC-V Doc Template
#
# This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
# International License. To view a copy of this license, visit
# http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to
# Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
#
# SPDX-License-Identifier: CC-BY-SA-4.0
#
# Description:
#
# This Makefile is designed to automate the process of building and packaging
# the Doc Template for RISC-V Extensions.

DOCS := \
	aclic.adoc

DATE ?= $(shell date +%Y-%m-%d)
VERSION ?= dev
REVMARK ?= Stable
DOCKER_IMG := ghcr.io/riscv/riscv-docs-base-container-image:latest
ifneq ($(SKIP_DOCKER),true)
	DOCKER_CMD := docker run --rm -v ${PWD}:/build -w /build \
	${DOCKER_IMG} \
	/bin/sh -c
	DOCKER_QUOTE := "
endif

SRC_DIR := src
BUILD_DIR := build
NORM_RULE_DEF_DIR := normative_rule_defs
DOC_NORM_TAG_SUFFIX := -norm-tags.json

ifeq ($(VERSION),dev)
	SUFFIX := $(DATE)
else
	SUFFIX := $(VERSION)
endif

DOCS_PDF := $(DOCS:%.adoc=%-$(SUFFIX).pdf)
DOCS_HTML := $(DOCS:%.adoc=%-$(SUFFIX).html)

# --- Normative rule tagging ---------------------------------------------------
# Per-document extracted tag files, e.g. build/aclic-norm-tags.json
DOCS_NORM_TAGS := $(addprefix $(BUILD_DIR)/, $(DOCS:%.adoc=%$(DOC_NORM_TAG_SUFFIX)))
NORM_RULES_JSON := $(BUILD_DIR)/norm-rules-$(SUFFIX).json
NORM_RULES_HTML := $(BUILD_DIR)/norm-rules-$(SUFFIX).html

# All normative rule definition input YAML files.
NORM_RULE_DEF_FILES := $(wildcard $(NORM_RULE_DEF_DIR)/*.yaml)

# asciidoctor "tags" backend (the source-of-truth extractor) and the
# generator tool shipped in the docs-resources submodule.
ASCIIDOCTOR_TAGS := asciidoctor --backend tags --require=./docs-resources/converters/tags.rb
CREATE_NORM_RULE_TOOL := docs-resources/tools/create_normative_rules.py
CREATE_NORM_RULE_PYTHON := python3 $(CREATE_NORM_RULE_TOOL)

# -t <tagfile> for each extracted tag file (input to the generator).
NORM_TAG_FILE_ARGS := $(foreach f,$(DOCS_NORM_TAGS),-t $(f))

# -d <deffile> for each definition YAML.
NORM_RULE_DEF_ARGS := $(foreach f,$(NORM_RULE_DEF_FILES),-d $(f))
# -tag2url mapping: tag file -> the rendered HTML it links into. The tag-file
# path here MUST match the path passed via -t above.
NORM_RULE_DOC2URL_ARGS := $(foreach d,$(DOCS),-tag2url $(BUILD_DIR)/$(d:%.adoc=%$(DOC_NORM_TAG_SUFFIX)) $(d:%.adoc=%)-$(SUFFIX).html)
# ------------------------------------------------------------------------------

XTRA_ADOC_OPTS :=
ASCIIDOCTOR_PDF := asciidoctor-pdf
ASCIIDOCTOR_HTML := asciidoctor
OPTIONS := --trace \
           -a compress \
           -a mathematical-format=svg \
           -a revnumber=${VERSION} \
           -a revremark=${REVMARK} \
           -a revdate=${DATE} \
           -a pdf-fontsdir=docs-resources/fonts \
           -a pdf-theme=docs-resources/themes/riscv-pdf.yml \
           $(XTRA_ADOC_OPTS) \
		   -D build \
           --failure-level=ERROR
REQUIRES := --require=asciidoctor-bibtex \
            --require=asciidoctor-diagram \
			--require=asciidoctor-lists \
            --require=asciidoctor-mathematical

.PHONY: all build clean build-container build-no-container build-docs
.PHONY: build-tags build-norm-rules build-norm-rules-json build-norm-rules-html


all: build

build-docs: $(DOCS_PDF) $(DOCS_HTML) build-norm-rules

vpath %.adoc $(SRC_DIR)

$(DOCS_PDF): %-$(SUFFIX).pdf: %.adoc
	$(DOCKER_CMD) $(DOCKER_QUOTE) $(ASCIIDOCTOR_PDF) $(OPTIONS) $(REQUIRES) -o $@ $< $(DOCKER_QUOTE)

$(DOCS_HTML): %-$(SUFFIX).html: %.adoc
	$(DOCKER_CMD) $(DOCKER_QUOTE) $(ASCIIDOCTOR_HTML) $(OPTIONS) $(REQUIRES) -o $@ $< $(DOCKER_QUOTE)

build:
	@echo "Checking if Docker is available..."
	@if command -v docker >/dev/null 2>&1 ; then \
		echo "Docker is available, building inside Docker container..."; \
		$(MAKE) build-container; \
	else \
		echo "Docker is not available, building without Docker..."; \
		$(MAKE) build-no-container; \
	fi

build-container:
	@echo "Starting build inside Docker container..."
	$(MAKE) build-docs
	@echo "Build completed successfully inside Docker container."

build-no-container:
	@echo "Starting build..."
	$(MAKE) SKIP_DOCKER=true build-docs
	@echo "Build completed successfully."

# --- Normative rule targets ---------------------------------------------------
#
# build-tags            : extract "norm:" tags from the .adoc sources into
#                         build/<doc>-norm-tags.json
# build-norm-rules-json : combine extracted tags + definition YAML into
#                         build/norm-rules-<suffix>.json
# build-norm-rules-html : same, but human-readable build/norm-rules-<suffix>.html
# build-norm-rules      : both of the above
#
# Tag extraction uses the asciidoctor "tags" backend (source of truth), run
# inside the RISC-V docs Docker image when available, or a local asciidoctor
# otherwise. Docker or asciidoctor is required for tag extraction.

build-tags: $(DOCS_NORM_TAGS)
build-norm-rules-json: $(NORM_RULES_JSON)
build-norm-rules-html: $(NORM_RULES_HTML)
build-norm-rules: build-norm-rules-json build-norm-rules-html

$(BUILD_DIR)/%$(DOC_NORM_TAG_SUFFIX): $(SRC_DIR)/%.adoc docs-resources/converters/tags.rb
	@mkdir -p $(BUILD_DIR)
	@if command -v docker >/dev/null 2>&1 ; then \
		echo "Extracting tags via asciidoctor tags backend (Docker)..."; \
		$(DOCKER_CMD) $(DOCKER_QUOTE) $(ASCIIDOCTOR_TAGS) --trace -a tags-match-prefix='norm:' -a tags-output-suffix='$(DOC_NORM_TAG_SUFFIX)' -D $(BUILD_DIR) $< $(DOCKER_QUOTE); \
	elif command -v asciidoctor >/dev/null 2>&1 ; then \
		echo "Extracting tags via asciidoctor tags backend (local)..."; \
		SKIP_DOCKER=true $(ASCIIDOCTOR_TAGS) --trace -a tags-match-prefix='norm:' -a tags-output-suffix='$(DOC_NORM_TAG_SUFFIX)' -D $(BUILD_DIR) $< ; \
	else \
		echo "ERROR: Docker or asciidoctor is required to extract norm: tags." >&2 ; \
		exit 1 ; \
	fi


$(NORM_RULES_JSON): $(DOCS_NORM_TAGS) $(NORM_RULE_DEF_FILES) $(CREATE_NORM_RULE_TOOL)
	@mkdir -p $(BUILD_DIR)
	$(DOCKER_CMD) $(DOCKER_QUOTE) $(CREATE_NORM_RULE_PYTHON) -j $(NORM_TAG_FILE_ARGS) $(NORM_RULE_DEF_ARGS) $(NORM_RULE_DOC2URL_ARGS) $@ $(DOCKER_QUOTE)

$(NORM_RULES_HTML): $(DOCS_NORM_TAGS) $(NORM_RULE_DEF_FILES) $(CREATE_NORM_RULE_TOOL)
	@mkdir -p $(BUILD_DIR)
	$(DOCKER_CMD) $(DOCKER_QUOTE) $(CREATE_NORM_RULE_PYTHON) --html $(NORM_TAG_FILE_ARGS) $(NORM_RULE_DEF_ARGS) $(NORM_RULE_DOC2URL_ARGS) $@ $(DOCKER_QUOTE)

# Update docker image to latest
docker-pull-latest:
	docker pull ${DOCKER_IMG}

clean:
	@echo "Cleaning up generated files..."
	rm -rf $(BUILD_DIR)
	@echo "Cleanup completed."
