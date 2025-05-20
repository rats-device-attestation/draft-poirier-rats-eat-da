include tools.mk
include check.mk
include frags.mk

check: check-da-eat check-da-eat-examples
.PHONY: check

clean: ; rm -f $(CLEANFILES)
.PHONY: clean

$(eval $(call cddl_check_template,da-eat,$(DA_EAT_FRAGS),$(DA_EAT_EXAMPLES)))
