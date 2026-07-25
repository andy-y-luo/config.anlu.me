.PHONY: tangle docs docs-tangle docs-build docs-clean

tangle:
	$(MAKE) -C src tangle

docs-tangle:
	emacs -Q --batch -l build/export-md.el

docs-build: docs-tangle
	hugo --source site

docs: docs-tangle
	hugo server --source site

docs-clean:
	rm -rf site/content/docs/* site/resources
