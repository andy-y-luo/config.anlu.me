# AGENTS.md

This is a **literate configuration** repository. Source of truth is
`*.org` files; the actual runtime configs are produced by **tangling**
with Emacs `org-babel` and are never committed.

## Layout

The repo is organized as a top-level `src/` directory containing one
subdirectory per **config module** (each maps to a tool whose config
lives under `~/.config/`). Every module has the same shape:

```
src/<module>/
├── Makefile        # tangles every .org in this module
├── tangle_file.sh  # helper invoked by the Makefile
└── *.org           # one or more org sources; per-file :tangle targets
```

Plus two shared bits at `src/`:

- `Makefile` — finds every subdir with a `Makefile` and runs its
  `tangle` target. New modules are picked up automatically.
- `headers` — shared org setupfile pulled in via `#+setupfile: ../headers`
  by every `*.org` file. Carries shared `#+property:` defaults.

The actual filenames inside each module change as the config grows;
treat the module list below as a current snapshot, not a contract.

## Build / tangle

Tangling is the only build step. From the repo root:

```sh
make -C src tangle
```

This walks every subdirectory of `src/` that has a `Makefile` and runs
its `tangle` target. Each module's Makefile is identical:

```make
.PHONY: tangle
tangle:
	find . -name "*.org" -exec sh -c 'echo "[!] Tangling {}"; ./tangle_file.sh "{}"' \;
```

`tangle_file.sh` invokes Emacs in batch mode:

```sh
emacs -q --batch --eval "(require 'ob-tangle)" \
      --eval "(setq org-confirm-babel-evaluate nil)" \
      --eval "(org-babel-tangle-file \"$1\")"
```

So tangling requires `emacs` on `$PATH`. The script uses `#!/bin/zsh`
but is invoked by `find -exec sh`; it works under either shell, but
keep the shebang as `zsh` for consistency with the existing files.

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
2. Run `make -C src tangle` (or `make -C src/<module> tangle` to
   target one module).
3. Reload / restart the affected tool to pick up changes.

### Adding a new config file in an existing module

1. Create a new `*.org` file in the module directory.
2. Add `#+title:` and `#+setupfile: ../headers` headers.
3. Set the `#+property: header-args:<lang> :tangle <abs-path>` (use
   `#+property: header-args:<lang>+` to append to existing defaults).
4. Run `make -C src tangle`. The new file is picked up automatically
   by the `find` in that module's Makefile — no Makefile change needed.

### Adding a new module

1. `mkdir src/<name>` and add a `Makefile` + `tangle_file.sh` copied
   from an existing module (they are all identical).
2. Add at least one `*.org` file with `#+setupfile: ../headers`.
3. The top-level `src/Makefile` uses `wildcard */`, so the new module
   is picked up automatically.

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
- Don't change the `tangle_file.sh` shebang from `#!/bin/zsh`.
- Don't remove `#+setupfile: ../headers` from org files; it carries
  the shared `#+property:` defaults (including `noweb`).
