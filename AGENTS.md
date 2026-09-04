# AGENTS.md

This is a **literate configuration** repository. Source of truth is
`*.org` files. Runtime configs are produced by **tangling** with Emacs
`org-babel`. They are never committed.

## Layout

The repo has a top-level `src/` directory. Each subdirectory is a
**config module** for one tool whose config lives under `~/.config/`.
A module is a directory of `*.org` sources with per-file `:tangle`
targets. There are no per-module `Makefile`s.

Shared bits at the repo root:

- `build/tangle.el` — single Emacs entry point. Tangles every `*.org`
  under a directory recursively. One Emacs invocation per `make
  tangle`.
- `build/export_hugo.el` — single Emacs entry point. Exports every
  `*.org` under `src/` to Hugo Markdown via `ox-hugo`.
- `src/headers` — shared org setupfile. Pulled in via
  `#+setupfile: ../headers` by every `*.org` file. Carries shared
  `#+property:` defaults.

Filenames inside each module change as the config grows. Treat the
module list below as a current snapshot, not a contract.

## Build / tangle

Three top-level commands, from the repo root:

```sh
make tangle       # tangle every *.org under src/ → ~/.config/...
make export-site  # export every *.org under src/ → site/content/<module>/...
make serve-site   # cd site && hugo serve (run after make export-site)
```

Scope a tangle to one module or subdirectory:

```sh
make tangle MODULE=tmux               # only src/tmux/
make tangle MODULE=emacs/packages     # only src/emacs/packages/
```

Each target shells out to exactly one Emacs invocation.

`export-site` is not scopeable. The script derives each file's section
from its directory path under `src/`. A file at
`src/<a>/<b>/<file>.org` exports to `site/content/<a>/<b>/<file>.md`.
Walking a subtree mis-derives the section prefix, so scope does not
generalize. The export is all-or-nothing. `build/export_hugo.el` takes
no arguments.

Module directories under `src/` map to top-level Hugo sections.
`src/emacs/` exports to `site/content/emacs/`. `src/opencode/` exports
to `site/content/opencode/`. The one root-level file, `src/index.org`,
is the site's landing page. It exports to `site/content/_index.md`. It
uses hugo-book's `landing` layout with a `site/layouts/landing.html`
override that re-adds the sidebar. The theme's stock `landing.html`
strips the menu container.

The export is Hugo-specific end to end. It uses the `ox-hugo` exporter.
It injects `#+hugo_*` keywords. It produces Hugo TOML front matter. It
is not a general-purpose Markdown export. Both the target and the
script carry `hugo` in their names for that reason. `build/tangle.el`
does not, because tangling is Hugo-independent.

Output filenames are decided at export time by
`my/export-hugo--output-name` in `build/export_hugo.el`. It maps
`index` to `_index` for Hugo's branch-bundle convention. Files are
written with their final names. There is no post-export rename pass.

`make export-site` wipes every `.md` under `site/content/` before
exporting. It prunes empty directories afterwards. The result is
clean on every re-run.

`build/tangle.el` loads only the minimum Emacs needs:

- `cl-lib`, `org`, `ob-tangle`, `ob-emacs-lisp`

It does not load `ox-*` exporters. Tangling never exports. It does not
load non-stock Babel backends like `ob-conf`, `ob-sh`, or `ob-json`.
Tangle walks block bodies and writes them. It never invokes
execute-mode backends. It does not load any user init file. The `-Q`
flag suppresses it.

Failures are fail-fast. The first tangle error aborts the Emacs
batch. `make` exits non-zero.

Tangling requires `emacs` on `$PATH`.

## Org conventions

Every `.org` file starts with a title and pulls in the shared setup:

```org
#+title: ...
#+setupfile: ../headers
```

Page titles in `#+title:` use only the leaf name. Examples:
`Programming`, `Global Rules`. Never the breadcrumb. Wrong example:
`Emacs - Packages - Programming`. The sidebar already nests under the
section tree, so the directory path provides the context. Restating
it in the title makes every sidebar entry redundant.

Tangle targets are declared per-language via property drawers. The
drawers live on the file or on a heading. Example from
`src/tmux/general.org`:

```org
#+property: header-args:conf  :mkdirp yes :lexical t :exports code
#+property: header-args:conf+ :tangle ~/.config/tmux/tmux.conf
```

- `conf` blocks → tmux config.
- `emacs-lisp` blocks → elisp. Default `:tangle` and other defaults
  come from `src/headers`. Per-file and property drawers override.
- `json` blocks → opencode JSON config files.

`noweb` is enabled globally in `src/headers`. Use `<<block-name>>` to
reference named source blocks across files. To opt out of noweb
expansion in a block, set `:noweb no-export` on that language's
properties. See the `conf+` line above.

## Editing configs

1. Edit the `.org` source. Do not edit files under `~/.config/...`
   directly. They are generated and will be overwritten on the next
   tangle.
2. Run `make tangle`. Use `make tangle MODULE=<name>` to target one
   module.
3. Reload or restart the affected tool to pick up changes.

### Adding a new config file in an existing module

1. Create a new `*.org` file in the module directory.
2. Add `#+title:` and `#+setupfile: ../headers` headers.
3. Set the `#+property: header-args:<lang> :tangle <abs-path>`. Use
   `#+property: header-args:<lang>+` to append to existing defaults.
4. Run `make tangle`. The recursive walk in `build/tangle.el` picks
   up the new file automatically. No Makefile change is needed.

### Adding a new module

1. `mkdir src/<name>`. Add at least one `*.org` file with
   `#+setupfile: ../headers`.
2. The recursive walk in `build/tangle.el` picks up the new module
   automatically. No Makefile change is needed.

## Per-module notes

- **tmux** — small module. One `*.org` file tangling to
  `~/.config/tmux/tmux.conf`. Prefix key is `C-a`. Mouse is on.
  `default-terminal` is `tmux-256color`.
- **emacs** — split across several `*.org` topics. Topics: basic
  setup, package manager, keybinding managers, custom elisp, plus a
  `packages/` subdir. Each `emacs-lisp` block respects the `:tangle`
  path declared in its property drawer. Many blocks noweb together to
  compose `init.el` and friends.
- **opencode** — three tangle targets. Server config →
  `opencode.json`. TUI config → `tui.json`. Global rules →
  `AGENTS.md`. A local `index.org` lists the modules. The
  opencode-level `AGENTS.md` lives at `~/.config/opencode/AGENTS.md`.
  It is generated from `src/opencode/agents.org`. Do not confuse it
  with this project-level `AGENTS.md`.
- **pi** — tangles to `~/.config/pi/agent/AGENTS.md`. See
  `src/pi/writing-style.org` for the writing style and
  `src/pi/index.org` for the module index.

## Commit conventions

Recent history uses Conventional Commits. Examples: `feat: ...`,
`chore: ...`. Scope is usually the module name. Example:
`feat(tmux): ...`. Keep the same style for new commits.

## Things to avoid

- Do not commit anything under `~/.config/`. It is outside this repo.
  If you add output there for testing, clean it up.
- Do not add a `.gitignore` for tangled output. Tangled files are
  written outside the repo by design.
- Do not add per-module `Makefile` or `tangle_file.sh` files.
  `build/tangle.el` handles every module from a single Emacs
  invocation. New modules are picked up automatically.
- Do not add a separate rename pass for `_index.md`. Output naming is
  decided at export time by `my/export-hugo--output-name`. A second
  pass reintroduces a window where `site/content/<module>/` is broken.
  A directory with `index.md` instead of `_index.md` becomes a leaf
  bundle. Its sibling pages stop being routable.
- Do not add a `<dir>` or `MODULE` argument to `build/export_hugo.el`.
  Section paths are derived from each file's position under `src/`. A
  different walk root mis-derives them.
- Do not comma-separate list-valued ox-hugo keywords. The keywords
  are `#+KEYWORDS:`, `#+HUGO_TAGS:`, and `#+HUGO_CATEGORIES:`. They
  are space-separated. Use double quotes for multi-word entries.
  ox-hugo parses them via `org-babel-parse-header-arguments`. In
  that parser, `,` is the elisp unquote reader macro. So `a, b`
  silently becomes nested garbage (`["a", [",", "b"]]`) in the front
  matter instead of failing.
- Do not remove `#+setupfile: ../headers` from org files. It carries
  the shared `#+property:` defaults, including `noweb`.
- Prose in `*.org` sources is the user's. Add new bullets or fix
  typos in place. Do not restyle surrounding sentences.
