+++
title = "Emacs - Packages - Applications"
author = ["Andy Luo"]
keywords = ["dotfiles", "emacs", "configuration"]
draft = false
+++

## Applications {#applications}


### Project Management {#project-management}


#### Magit {#magit}

Magit is an awesome wrapper around git for Emacs!

```emacs-lisp
(use-package magit
  :straight (:build t)
  :defer t
  :init
  (setq forge-add-default-bindings nil)
  :config
  (add-hook 'magit-process-find-password-functions 'magit-process-password-auth-source)
  (setopt magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))
```
