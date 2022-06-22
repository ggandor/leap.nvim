src_files = $(wildcard fnl/leap/*.fnl)
out_files = $(src_files:fnl/leap/%.fnl=lua/leap/%.lua)

compile: $(out_files)

lua/leap/%.lua: fnl/leap/%.fnl lua/leap/
	fennel --compile $< > $@

lua/leap/:
	rm -rf lua
	mkdir -p lua/leap/

clean:
	rm -rf lua

.PHONY: clean compile

# vim:setlocal noexpandtab
