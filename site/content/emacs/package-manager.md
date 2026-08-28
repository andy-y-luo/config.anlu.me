+++
title = "Emacs - Package Manager"
author = ["Andy Luo"]
keywords = ["dotfiles", "emacs", "configuration"]
draft = false
+++

## Package Manager {#package-manager}


### Repositories {#repositories}

In addition to the default GNU repositories, I also want to use Melpa and org-mode's repositories. melpa is a community-maintained repository which contains an absurd amount of emacs packages.

```emacs-lisp
(setq package-archives '(("melpa"  . "https://melpa.org/packages/")
                         ("gnu"    . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
```


### Straight {#straight}

I use `straight` ([[<https://github.com/radian-software/straight.el>][GitHub]) for my package management. It integrates nicely with `use-package` and also allows for specifying where to retrieve packages that are not found on the above repositories (such as directly from GitHub and other online Git repositories).
First, let’s bootstrap straight.

```emacs-lisp
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))
```

We finally come to the `use-package` installation. This is done like so:

```emacs-lisp
(straight-use-package '(use-package :build t))
```
