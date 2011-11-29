
all:
	coffee -c *.coffee

test:
	coffee test.coffee

clean:
	rm *.js

.PHONY: all test clean
