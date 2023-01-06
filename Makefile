test:
	nvim --headless --noplugin -u scripts/minimal.vim -c "PlenaryBustedDirectory lua/ {minimal_init = 'scripts/minimal.vim'}"

lint:
	stylua --check .

docspush:
	rm -rf docs && ldoc -i lua && git add -f docs && git commit -m "update docs" && git push
