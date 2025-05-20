%.cbor: %.diag ; $(diag2cbor) $< > $@

# $1: label
# $2: cddl fragments
# $3: diag test files
define cddl_check_template

check-$(1): $(1)-autogen.cddl
	$$(cddl) $$< g 1 | $$(diag2diag) -e

.PHONY: check-$(1)

$(1)-autogen.cddl: $(2)
	cddlc -t cddl -2 $$^ > $$@

CLEANFILES += $(1)-autogen.cddl

check-$(1)-examples: $(1)-autogen.cddl $(3:.diag=.cbor)
	@for f in $(3:.diag=.cbor); do \
	  echo ">> validating $$$$f against $$<" ; \
	  $$(cddl) $$< validate $$$$f &>/dev/null || exit 1 ; \
	  echo ">> saving prettified CBOR to $$$${f%.cbor}.pretty" ; \
	  $$(cbor2pretty) $$$$f > $$$${f%.cbor}.pretty ; \
	  echo ">> saving hexified CBOR to $$$${f%.cbor}.hex" ; \
	  $$(xxd) -p $$$$f > $$$${f%.cbor}.hex ; \
	done

.PHONY: check-$(1)-examples

CLEANFILES += $(3:.diag=.cbor)
CLEANFILES += $(3:.diag=.pretty)
CLEANFILES += $(3:.diag=.hex)

endef # cddl_check_template
