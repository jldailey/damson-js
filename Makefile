
all:
	coffee -c *.coffee

test: all
	for f in $(shell ls tests/*.coffee); do echo -n $$f ": "; coffee $$f; done

clean:
	rm *.js

.PHONY: all test clean
