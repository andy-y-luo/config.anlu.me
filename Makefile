.PHONY: tangle export-hugo

MODULE ?=
tangle:
	@if [ -n "$(MODULE)" ]; then \
		emacs -Q --batch -l build/tangle.el -- src/$(MODULE); \
	else \
		emacs -Q --batch -l build/tangle.el -- src; \
	fi

export-hugo:
	mkdir -p site/content/docs
	find site/content/docs -name '*.md' -delete
	emacs -Q --batch -l build/export_hugo.el
	find site/content/docs -type d -empty -delete
