test:
	nvim --headless --noplugin -u scripts/minimal.vim -c "PlenaryBustedDirectory lua/ {minimal_init = 'scripts/minimal.vim'}"

lint:
	stylua --check .

push:
	rm -rf docs && ldoc lua && git add . && git commit -m "update docs" && git push
