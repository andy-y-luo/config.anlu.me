# AGENTS.md

This is a **literate configuration** repository. Source of truth is
`*.org` files; the actual runtime configs are produced by **tangling**
with Emacs `org-babel` and are never committed.

## Layout

The repo is organized as a top-level `src/` directory containing one
subdirectory per **config module** (each maps to a tool whose config
lives under `~/.config/`). Each module is just a directory of `*.org`
sources with per-file `:tangle` targets — there are no per-module
`Makefile`s.

Plus shared bits at the repo root:

- `build/tangle.el` — single Emacs entry point that tangles every
  `*.org` under a given directory recursively (one Emacs invocation
  per `make tangle`).
- `build/export_hugo.el` — single Emacs entry point that exports every
  `*.org` under `src/` to Hugo Markdown via `ox-hugo`.
- `src/headers` — shared org setupfile pulled in via
  `#+setupfile: ../headers` by every `*.org` file. Carries shared
  `#+property:` defaults.

The actual filenames inside each module change as the config grows;
treat the module list below as a current snapshot, not a contract.

## Build / tangle

Three top-level commands, from the repo root:

```sh
make tangle       # tangle every *.org under src/ → ~/.config/...
make export-site  # export every *.org under src/ → site/content/<module>/...
make serve-site   # cd site && hugo serve (run after make export-site)
```

To scope the tangle to a single module (or subdirectory):

```sh
make tangle MODULE=tmux               # only src/tmux/
make tangle MODULE=emacs/packages     # only src/emacs/packages/
```

Each target shells out to exactly one Emacs invocation.

`export-site` is deliberately **not** scopeable. The script derives
each file's section mechanically from its directory path under `src/`:
a file at `src/<a>/<b>/<file>.org` exports to
`site/content/<a>/<b>/<file>.md`. Walking a subtree instead would
mis-derive the section prefix, so scope doesn't generalize and the
export is all-or-nothing. `build/export_hugo.el` takes no arguments.

Module directories under `src/` map directly to top-level Hugo
sections. So `src/emacs/` exports to `site/content/emacs/`,
`src/opencode/` to `site/content/opencode/`, etc. The one root-level
file, `src/index.org`, is the site's landing page and exports to
`site/content/_index.md`. It uses hugo-book's `landing` layout with a
`site/layouts/landing.html` override that re-adds the sidebar (the
theme's stock `landing.html` strips the menu container).

The export is Hugo-specific end to end — `ox-hugo` exporter, injected
`#+hugo_*` keywords, Hugo TOML front matter in the output. It is not a
general-purpose Markdown export, which is why both the target and the
script carry `hugo` in their names. `build/tangle.el` does not, because
tangling genuinely is Hugo-independent.

Output filenames are decided at export time by
`my/export-hugo--output-name` in `build/export_hugo.el`, which maps
`index` → `_index` for Hugo's branch-bundle (section page) convention.
Files are written with their final names; there is no post-export
rename pass.

`make export-site` wipes every `.md` under `site/content/` before
exporting, and prunes empty directories afterwards, so it's always
clean on re-run.

`build/tangle.el` loads only the minimum Emacs needs:

- `cl-lib`, `org`, `ob-tangle`, `ob-emacs-lisp`

It does **not** load `ox-*` exporters (tangling never exports), nor
non-stock Babel backends like `ob-conf` / `ob-sh` / `ob-json` (tangle
walks block bodies and writes them; it never invokes execute-mode
backends), nor any user init file (the `-Q` flag suppresses it).
Failures are fail-fast: the first tangle error aborts the Emacs batch
and `make` exits non-zero.

Tangling requires `emacs` on `$PATH`.

## Org conventions

Every `.org` file starts with a title and pulls in the shared setup:

```org
#+title: ...
#+setupfile: ../headers
```

Tangle targets are declared **per-language via property drawers** on
the file or on a heading, e.g. (from `src/tmux/general.org`):

```org
#+property: header-args:conf  :mkdirp yes :lexical t :exports code
#+property: header-args:conf+ :tangle ~/.config/tmux/tmux.conf
```

- `conf` blocks → tmux config.
- `emacs-lisp` blocks → elisp (default `:tangle` and other defaults
  come from `src/headers`; per-file/property drawers override).
- `json` blocks (opencode) → JSON config files.

`noweb` is enabled globally in `src/headers`; use `<<block-name>>` to
reference named source blocks across files. When you don't want
noweb-style expansion in a block, set `:noweb no-export` on that
language's properties (see the `conf+` line above).

## Editing configs

1. Edit the `.org` source. Do **not** edit files under `~/.config/...`
   directly — they are generated and will be overwritten on the next
   tangle.
2. Run `make tangle` (or `make tangle MODULE=<name>` to target one
   module).
3. Reload / restart the affected tool to pick up changes.

### Adding a new config file in an existing module

1. Create a new `*.org` file in the module directory.
2. Add `#+title:` and `#+setupfile: ../headers` headers.
3. Set the `#+property: header-args:<lang> :tangle <abs-path>` (use
   `#+property: header-args:<lang>+` to append to existing defaults).
4. Run `make tangle`. The new file is picked up automatically by the
   recursive walk in `build/tangle.el` — no Makefile change needed.

### Adding a new module

1. `mkdir src/<name>` and add at least one `*.org` file with
   `#+setupfile: ../headers`.
2. The recursive walk in `build/tangle.el` picks up the new module
   automatically; no Makefile change is needed.

## Per-module notes

- **tmux** — small module, currently a single `*.org` file tangling to
  `~/.config/tmux/tmux.conf`. Prefix key is `C-a`. Mouse is on.
  `default-terminal` is `tmux-256color`.
- **emacs** — split across several `*.org` topics (basic setup, package
  manager, keybinding managers, custom elisp, plus a `packages/`
  subdir). Each `emacs-lisp` block respects the `:tangle` path declared
  in its property drawer; many blocks noweb together to compose
  `init.el` and friends.
- **opencode** — three tangle targets: server config → `opencode.json`,
  TUI config → `tui.json`, and global rules → `AGENTS.md`. A local
  `index.org` lists the modules. **Note:** the opencode-level
  `AGENTS.md` lives at `~/.config/opencode/AGENTS.md` and is generated
  from `src/opencode/agents.org` — do not confuse it with this
  project-level `AGENTS.md`.

## Commit conventions

Recent history uses Conventional Commits: `feat: ...`, `chore: ...`.
Scope is usually the module name, e.g. `feat(tmux): ...`. Keep the
same style for new commits.

## Things to avoid

- Don't commit anything under `~/.config/` (it's outside this repo,
  but if you ever add output here for testing, clean it up).
- Don't add a `.gitignore` for tangled output — tangled files are
  written outside the repo by design.
- Don't add per-module `Makefile` or `tangle_file.sh` files —
  `build/tangle.el` handles every module from a single Emacs
  invocation. New modules are picked up automatically.
- Don't add a separate rename/post-processing pass for `_index.md`.
  Output naming is decided at export time by
  `my/export-hugo--output-name`; a second pass reintroduces a window
  where `site/content/<module>/` is in a broken state (a directory with
  `index.md` instead of `_index.md` becomes a leaf bundle and its
  sibling pages stop being routable).
- Don't add a `<dir>`/`MODULE` argument to `build/export_hugo.el`.
  Section paths are derived from each file's position under `src/`;
  a different walk root mis-derives them.
- Don't comma-separate list-valued ox-hugo keywords (`#+KEYWORDS:`,
  `#+HUGO_TAGS:`, `#+HUGO_CATEGORIES:`). They're **space**-separated;
  use double quotes for multi-word entries. ox-hugo parses them via
  `org-babel-parse-header-arguments`, where `,` is the elisp unquote
  reader macro, so `a, b` silently becomes nested garbage
  (`["a", [",", "b"]]`) in the front matter instead of failing.
- Don't remove `#+setupfile: ../headers` from org files; it carries
  the shared `#+property:` defaults (including `noweb`).
