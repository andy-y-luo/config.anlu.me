+++
title = "Emacs - Packages - Programming"
author = ["Andy Luo"]
keywords = ["dotfiles", "emacs", "configuration"]
draft = false
+++

## Programming {#programming}


### Tools {#tools}


#### Treesitter {#treesitter}

Treesit is a native Emacs [tree-sitter](https://tree-sitter.github.io/tree-sitter/) implementation which provides a very fast and flexible way of performing code-highlighting in Emacs. It is built-in in Emacs 29 and newer, and I just need to tweak a couple of variables to install grammars for different languages.

```emacs-lisp
(use-package treesit
  :defer t
  :straight (:type built-in)
  :hook ((bash-ts-mode c-ts-mode c++-ts-mode
          html-ts-mode js-ts-mode typescript-ts-mode
          json-ts-mode rust-ts-mode tsx-ts-mode python-ts-mode
          css-ts-mode yaml-ts-mode) . lsp-deferred))
```

```emacs-lisp
(use-package tree-sitter-langs
  :after tree-sitter
  :straight t
  :custom (global-tree-sitter-mode t)
  :init
  (add-to-list 'treesit-extra-load-path
               (expand-file-name "bin" tree-sitter-langs-grammar-dir)))

(use-package treesit-auto
  :after tree-sitter
  :straight t
  :config (global-treesit-auto-mode))
```


#### Flycheck {#flycheck}

FlyCheck is a syntax checker, more modern and actively maintained compared to FlyMake.

```emacs-lisp
(use-package flycheck
  :straight (:build t)
  :defer t
  :init
  (global-flycheck-mode)
  :config
  (setq flycheck-emacs-lisp-load-path 'inherit)

  ;; rerunning checks on every newline is a mote excessive
  (delq 'new-line flycheck-check-syntax-automatically)
  ;; also don't recheck on idle as often
  (setq flycheck-idle-change-delay 2.0)

  ;; for the above functionality, check syntax in a buffer that you switched to on briefly. Allows for quick refreshing of the syntax check state for several buffers
  (setq flycheck-buffer-switch-check-intermediate-buffers t)

  ;; display errors a little quicker (default is 0.9s)
  (setq flycheck-display-errors-delay 0.2))
```


#### Eglot {#eglot}

Seems like the built-in Eglot LSP client is lighter weight than lsp-mode. Less like a heavy IDE, more minimal.

```emacs-lisp
(use-package eglot
  :straight (:type built-in))
(setq eglot-ignored-server-capabilities '(:inlayHintProvider))
```

```emacs-lisp
(use-package exec-path-from-shell
  :straight (:build t)
  :custom
  (exec-path-from-shell-variables '("PATH" "MANPATH" "SSH_AUTH_SOCK" "SSH_AGENT_PID"))
  :init
  (exec-path-from-shell-initialize))
```


#### Dape {#dape}

Dape is a debug adapter client for Emacs. Unfortunately `dap-mode` is tightly coupled with `lsp-mode` and we're using Eglot instead. Dape does not support `launch.json` files. If per project configuration is needed, use `dir-locals` and `dape-command`.

```emacs-lisp
(use-package dape
  :after eglot
  :defer t
  :straight (:build t)
  :custom
  (dape-breakpoint-global-mode +1))
```


### General Languages {#general-languages}


#### Python {#python}


##### Ty {#ty}

As of Dec 2025, Astral has removed the "not ready for production use" wording from `ty` documentation. Seems like a good time to start trying it out.

```emacs-lisp
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
            '((python-base-mode) . ("ty" "server"))))
```


##### Ruff {#ruff}

Blazing fast linter and formatter, and provides a language server, but we'll use it with FlyCheck instead (Eglot only supports one language server per mode).

```emacs-lisp
(defun python-flycheck-setup ()
  (flycheck-select-checker 'python-ruff))

(add-to-list 'flycheck-checkers 'python-ruff)
(add-hook 'python-base-mode-hook #'python-flycheck-setup 'append)

```


### Domain Specific Languages {#domain-specific-languages}

DSLs, or _Domain Specific Languages_ are languages dedicated to some very specific tasks, such as configuration languages, or non-general programming such as SQL.


#### Makefiles {#makefiles}

Unfortunately makefiles require tabs for indentation.

```emacs-lisp
(defun my/local-tab-indent ()
  (setq-local indent-tabs-mode 1))
(add-hook 'makefile-mode-hook #'my/local-tab-indent)
```


#### SSH config files {#ssh-config-files}

```emacs-lisp
(use-package ssh-config-mode
  :defer t
  :straight (:build t))
```


#### TOML {#toml}

```emacs-lisp
(use-package toml-mode
  :straight (:build t)
  :defer t)
```


#### YAML {#yaml}

```emacs-lisp
(use-package yaml-mode
  :defer t
  :straight (:build t)
  :mode "\\.yml\\'"
  :mode "\\.yaml\\'")
```


#### Terraform (HCL) {#terraform--hcl}

```emacs-lisp
(use-package terraform-mode
  :straight (:build t)
  :defer t
  :custom (terraform-indent-level 2)
  :config
  (defun my/terraform-mode-init()
    (outline-minor-mode 1))
  (add-hook 'terraform-mode-hook 'my/terraform-mode-init))
```
