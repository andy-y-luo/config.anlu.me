+++
title = "Emacs - Packages - Autocompletion"
author = ["Andy Luo"]
keywords = ["dotfiles", "emacs", "configuration"]
draft = false
+++

## Autocompletion {#autocompletion}


### Code Autocompletion {#code-autocompletion}


#### Corfu {#corfu}

Corfu does not provide completions itself but rather gets those from emacs-standard completion-at-point-functions (CAPFs). Since corfu is simply a UI for completion-at-point, it gets summoned anywhere that command is called.

```emacs-lisp
(use-package corfu
  :straight (:build t)
  :defer t
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  :init
  (global-corfu-mode))
```


### Vertico {#vertico}

Vertico provides a minimalistic vertical completion UI for the minibuffer.

```emacs-lisp
(use-package vertico
  :straight (:build t)
  :defer t
  :init
  (vertico-mode))
```


### Marginalia {#marginalia}

Just like notes written in the margin of a page, this package provides annotations in the minibuffer.

```emacs-lisp
(use-package marginalia
  :straight (:build t)
  :defer t
  :init
  (marginalia-mode))
```


### Orderless {#orderless}

Orderless provides an `orderless` completion style that divides the pattern into space-separated components, and matches candidates matching those components in any order (hence `orderless`).

```emacs-lisp
(use-package orderless
  :straight (:build t)
  :defer t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))
```


### Consult {#consult}

Consult provides search and navigation commands based on the Emacs completion function [completing-read](https://www.gnu.org/software/emacs/manual/html_node/elisp/Minibuffer-Completion.html) documented in the Elisp manual.

```emacs-lisp
(use-package consult
  :straight (:build t)
  :defer t
  :hook (completion-list-mode . consult-preview-at-point-mode)
  :custom
  (consult-preview-key nil)
  (consult-narrow-key nil)
  :config
  (consult-customize consult-theme consult-line :preview-key '(:debounce 0.2 any)))
```
