.PHONY: build
build: node_modules
	node_modules/.bin/coffee --map --output lib --compile src

test: node_modules
	node_modules/.bin/jasmine-node --coffee spec

node_modules: yarn.lock
	yarn install
	@touch $@

yarn.lock: package.json
	yarn upgrade
	@touch $@
