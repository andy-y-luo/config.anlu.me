.PHONY: tangle export-hugo serve-hugo

MODULE ?=
tangle:
	@if [ -n "$(MODULE)" ]; then \
		emacs -Q --batch -l build/tangle.el -- src/$(MODULE); \
	else \
		emacs -Q --batch -l build/tangle.el -- src; \
	fi

export-site:
	mkdir -p site/content
	find site/content -name '*.md' -delete
	emacs -Q --batch -l build/export_hugo.el
	find site/content -type d -empty -delete

serve-site:
	cd site && hugo serve
