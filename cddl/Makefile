include mk/tools.mk
include mk/check.mk
include mk/frags.mk

check: check-da-token check-da-token-examples
.PHONY: check

clean: ; rm -f $(CLEANFILES)
.PHONY: clean

$(eval $(call cddl_check_template,da-token,$(DA_TOKEN_FRAGS),$(DA_TOKEN_EXAMPLES)))
