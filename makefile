test:
	jasmine-node --coffee spec

travis:
	$(MAKE) test

.PHONY: test
