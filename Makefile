src_files = $(wildcard fnl/*.fnl)
out_files = $(src_files:fnl/%.fnl=lua/%.lua)

compile: $(out_files)

lua/%.lua: fnl/%.fnl lua/
	fennel --compile $< > $@

lua/:
	mkdir -p lua

clean:
	rm -rf lua

.PHONY: clean compile

# vim:setlocal noexpandtab
