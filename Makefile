.PHONY: test test-one lint format typecheck check rockspec-check dev

test:
	nvim -l tests/minit.lua --minitest $(FILE)

test-one:
	nvim -l tests/minit.lua --minitest tests/$(MODULE)_spec.lua

STYLUA_VERSION := 2.4.1

lint:
	stylua --check lua/ tests/

format:
	stylua lua/ tests/

NVIM_VIMRUNTIME := $(shell nvim --headless -c 'lua io.write(vim.env.VIMRUNTIME)' -c 'q' 2>&1)
typecheck:
	VIM="$(NVIM_VIMRUNTIME)/.." lua-language-server --check_format=pretty --check lua/ --checklevel=Warning --configpath="$$(pwd)/.luarc.json"

check: lint typecheck test

rockspec-check:
	@tmp="$$(mktemp -d)"; \
	trap 'rm -rf "$$tmp"' EXIT; \
	luarocks make --tree "$$tmp" mdn.nvim-scm-1.rockspec >/dev/null; \
	for source in lua/mdn/*.lua; do \
		module="$${source#lua/mdn/}"; \
		module="$${module%.lua}"; \
		if test "$$module" = "init"; then key="mdn"; installed="mdn/init.lua"; \
		else key="mdn.$$module"; installed="mdn/$$module.lua"; fi; \
		grep -Fq "[\"$$key\"] = \"$$source\"" mdn.nvim-scm-1.rockspec || exit 1; \
		test -n "$$(find "$$tmp" -path "*/$$installed" -print -quit)" || exit 1; \
	done; \
	test -n "$$(find "$$tmp" -path '*/plugin/mdn.lua' -print -quit)"; \
	test -n "$$(find "$$tmp" -path '*/after/ftplugin/markdown.lua' -print -quit)"

dev:
	nvim -u repro/repro.lua
