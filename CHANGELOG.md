# Changelog

## [1.0.0](https://github.com/nikbrunner/mdn.nvim/compare/v0.0.1...v1.0.0) (2026-10-02)


### ⚠ BREAKING CHANGES

* Neovim older than 0.13 is no longer supported.
* **config:** The default cycle key changes from <S-CR> to <C-k>. Set mappings.cycle_key = "<S-CR>" to keep the previous mapping.
* **init:** Remove mdn.setup() and mdn.did_setup. Set vim.g.mdn_config before the plugin loads.
* **conceal:** conceal options now use pattern and replace tables instead of plain replacement strings.
* remove insert-mode indent/outdent in favor of built-ins

### Features

* **checkbox:** add in-progress [~] state to checkbox cycle ([ea27d26](https://github.com/nikbrunner/mdn.nvim/commit/ea27d2649065f0801c795aed9f627dbf54f9bb97))
* **checkbox:** support visual-mode range toggle ([cb42679](https://github.com/nikbrunner/mdn.nvim/commit/cb426795a68ac68802383e36fd5fe746d3532f36))
* **conceal:** make conceal rules configurable ([9655e78](https://github.com/nikbrunner/mdn.nvim/commit/9655e7867545e70f004f9bfc5cf6da64f5616630))
* **config:** add bullet_marker option and Tab indent/outdent ([3e06390](https://github.com/nikbrunner/mdn.nvim/commit/3e06390b8166987bdf7a99efaf49a773b7635265))
* **config:** restructure into lists and mappings groups ([4f9017d](https://github.com/nikbrunner/mdn.nvim/commit/4f9017df12247f4a2e9a1c3b65dd62d6650a88ec))
* **config:** use Ctrl-K as the default cycle key ([035a2db](https://github.com/nikbrunner/mdn.nvim/commit/035a2db64b0bdfb1e168ddb8862d257ca730026d))
* **indent:** respect .prettierrc tabWidth when indenting ([0ea264b](https://github.com/nikbrunner/mdn.nvim/commit/0ea264b73646bff1d5a87109a89b0028865ac874))
* **init:** load mdn from global config ([a74dde0](https://github.com/nikbrunner/mdn.nvim/commit/a74dde059dcb1af60cc0dacf2249dfc647f195dc))
* **link:** yank Markdown link or bare URL under cursor with yl ([d4e4ad2](https://github.com/nikbrunner/mdn.nvim/commit/d4e4ad2d187d2bcbfa9ce78a45c291a4b858e1c1))
* **render:** draw table lines and keep cell text unconcealed ([062100c](https://github.com/nikbrunner/mdn.nvim/commit/062100cc2d28b2e83a79f39543c8ce0dfbcd17b6))
* **render:** stabilize Markdown conceal rendering ([1e2b49e](https://github.com/nikbrunner/mdn.nvim/commit/1e2b49e5ab47be8ac427ac7751a888e6db8681ea))


### Bug Fixes

* **build:** package conceal module ([78c9061](https://github.com/nikbrunner/mdn.nvim/commit/78c906105cbd457caa366de0034750da1a4a4815))
* **checkbox:** cycle checked items back to bullets ([291024e](https://github.com/nikbrunner/mdn.nvim/commit/291024ea0fe654fe7ce8c3302a1b2ecf9d81794d))
* **checkbox:** recognize [~] as in-progress task state ([5e0a68d](https://github.com/nikbrunner/mdn.nvim/commit/5e0a68d83d489e3d1be2f4b90e2753f09665c8f9))
* **conceal:** reveal markers across Visual Block selections ([602090b](https://github.com/nikbrunner/mdn.nvim/commit/602090b981bd647cc30418be8d84d1bc78de7597))
* **ftplugin:** attach keymaps synchronously to the sourced buffer ([df41f8a](https://github.com/nikbrunner/mdn.nvim/commit/df41f8afb0994491095cadcd8cff3c9ecb3a8200))
* **list:** clear empty list item on Enter/o instead of inserting line ([c2547b1](https://github.com/nikbrunner/mdn.nvim/commit/c2547b14ef881dc6e13ec67b32040f9b7d505042))
* **list:** split list item at cursor on Enter in middle of line ([6aa8541](https://github.com/nikbrunner/mdn.nvim/commit/6aa8541be2c05da4996de8853db787fba8731044))
* proper &lt;CR&gt; fallback on non-list lines + cursor position tests ([edadb20](https://github.com/nikbrunner/mdn.nvim/commit/edadb20600246d6883f59e82f35608b73cd17067))


### Code Refactoring

* remove insert-mode indent/outdent in favor of built-ins ([024dbc7](https://github.com/nikbrunner/mdn.nvim/commit/024dbc7fc5bde4fc1eb1394e9bf4b531ae66c7e5))


### Build System

* require Neovim 0.13 ([552f13e](https://github.com/nikbrunner/mdn.nvim/commit/552f13e1eed7503fe96508e4b8f04ffa3ee97728))
