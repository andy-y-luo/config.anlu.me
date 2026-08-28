+++
title = "Emacs - Basic Configuration"
author = ["Andy Luo"]
keywords = ["dotfiles", "emacs", "configuration"]
draft = false
+++

## Basic Configuration {#basic-configuration}


### Early initialization {#early-initialization}

:header-args:emacs-lisp: :tangle ~/.config/emacs/early-init.el :mkdirp yes
:header-args:emacs-lisp+: :exports code :results silent :lexical t

The early init file `early-init.el` is loaded before anything else in Emacs. By disabling some built-in features of Emacs, before they can even be loaded, Emacs is sped up a little.

```emacs-lisp
(setq package-enable-at-startup nil
      inhibit-startup-message   t
      frame-resize-pixelwise    t  ; fine resize
      package-native-compile    t) ; native compile packages
(scroll-bar-mode -1)               ; disable scrollbar
(tool-bar-mode -1)                 ; disable toolbar
(tooltip-mode -1)                  ; disable tooltips
(fringe-mode 10)                   ; give some breathing room
(menu-bar-mode -1)                 ; disable menubar
(blink-cursor-mode 0)              ; disable blinking cursor
```


### Emacs behavior {#emacs-behavior}


#### Editing text in Emacs {#editing-text-in-emacs}

Always get rid of trailing whitespace in files:

```emacs-lisp
(add-hook 'before-save-hook #'whitespace-cleanup)
```

Don't add two spaces behind a full stop (why is this a default?):

```emacs-lisp
(setq-default sentence-end-double-space nil)
```

There's a minor mode which provides a finer way of jumping from word to word: `global-subword-mode`. In camelCase words, allow jumping at a finer level.

```emacs-lisp
(global-subword-mode 1)
```

We want scrolling to be gradual (instead of changing half of the screen) whenever the cursor gets too high or low.

```emacs-lisp
(setq scroll-conservatively 1000)
```

Default mode should be `emacs-lisp-mode`.

```emacs-lisp
(setq-default initial-major-mode 'emacs-lisp-mode)
```


##### Indentation {#indentation}

Tabs for indentation brings out a host of problems. Stick with spaces.

```emacs-lisp
(setq-default indent-tabs-mode nil)
(add-hook 'prog-mode-hook (lambda () (setq indent-tabs-mode nil)))
```


#### Programming modes {#programming-modes}

Add a few other modes to fall under the category of "programming mode", so features like line numbers can also be enabled.

<a id="table--line-number-modes-table"></a>

| Modes      |
|------------|
| prog-mode  |
| latex-mode |

<a id="code-snippet--prog-modes-gen"></a>
```emacs-lisp
(mapconcat (lambda (mode) (format "%s-hook" (car mode)))
           modes
           " ")
```


##### Line numbers {#line-numbers}

Line numbers simply make sense in a text editor.

```emacs-lisp
(dolist (mode '(<<prog-modes-gen()>>))
  (add-hook mode #'display-line-numbers-mode))
```


##### Folding code {#folding-code}

Most programming languages support folding code blocks based structure delimiters. `hs-minor-mode` enables that in Emacs.

```emacs-lisp
(dolist (mode '(<<prog-modes-gen()>>))
  (add-hook mode #'hs-minor-mode))
```


#### Stay clean, Emacs! {#stay-clean-emacs}

To not have to wade through a sea of backup files in the same directories as the working files, we tell Emacs to keep its backup files to itself in a dedicated directory.

```emacs-lisp
(setq backup-directory-alist `(("." . ,(expand-file-name ".tmp/backups/"
                                                         user-emacs-directory)))
      tramp-backup-directory-alist `(("." . ,(expand-file-name ".tmp/tramp-backups/"
                                                               user-emacs-directory))))
```

We want to avoid the issue of LSP adding imports that point to the symlinks of backup files (tunneling through my home directory along the way). By forbidding Emacs to create symlinks for backups, this problem should be avoided.

```emacs-lisp
(setq backup-by-copying t)
```

Custom configuration variables added by Emacs when changing options through the GUI should not be added to `init.el`, have them be added to a dedicated file.

```emacs-lisp
(setq-default custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file) ; Don’t forget to load it, we still need it
  (load custom-file))
```

If we delete a file, we want it moved to the trash.

```emacs-lisp
(setq delete-by-moving-to-trash t)
```

The scratch buffer always has some message at its beginning, I don’t want it!

```emacs-lisp
(setq-default initial-scratch-message nil)
```


#### Stay polite, Emacs! {#stay-polite-emacs}

Making us type out "yes" or "no" fully is not very polite, we're not made of time.

```emacs-lisp
(if (version<= emacs-version "28")
    (defalias 'yes-or-no-p 'y-or-n-p)
  (setopt use-short-answers t))
```

Also impolite to keep a certain version of a file in its buffer when said file has changed on disk. By fixing this, note that if the buffer is modified and its changes haven't been saved, it will not automatically revert he buffer and your unsaved changes won't be lost.

```emacs-lisp
(global-auto-revert-mode 1)
```


#### Misc {#misc}

Let’s raise Emacs undo memory to 10 MB, and make Emacs auto-save our files by default.

```emacs-lisp
(setq undo-limit        100000000
      auto-save-default t)
```

```emacs-lisp
(setq window-combination-resize t) ; take new window space from all other windows
```


### Personal information {#personal-information}

Emacs needs to know who I am! For various reasons by the way, some packages rely on these variables to know who it is talking to or dealing with, such as `mu4e` which will guess who you are if you haven’t set it up correctly.

```emacs-lisp
(setq user-full-name       "Andy Luo"
      user-real-login-name "Andy Luo"
      user-login-name      "anlu"
      user-mail-address    "andy@anlu.me")
```


### Visual configurations {#visual-configurations}

Don't let me hear OR see the bell.

```emacs-lisp
(setq ring-bell-function 'ignore)
```

Cursor should cover entire space of a character.

```emacs-lisp
(setq x-stretch-cursor t)
```

When text is ellipsed, I want the ellipsis marker to be a single character of three dots. Let’s make it so:

```emacs-lisp
(with-eval-after-load 'mule-util
 (setq truncate-string-ellipsis "…"))
```


#### Modeline Modules {#modeline-modules}

I want the current date and time to be displayed,in an ISO-8601 style, although not exactly ISO-8601 (this is the best time format)

```emacs-lisp
(require 'time)
(setq display-time-format "%Y-%m-%d %H:%M")
(display-time-mode 1) ; display time in modeline
```

Show column in addition to line number.

```emacs-lisp
(column-number-mode)
```


#### Frame Title {#frame-title}

This is straight-up copied from [TEC](https://tecosaur.github.io/emacs-config/config.html#window-title)’s configuration. See their comment on the matter.

```emacs-lisp
(setq frame-title-format
      '(""
        "%b"
        (:eval
         (let ((project-name (projectile-project-name)))
           (unless (string= "-" project-name)
             (format (if (buffer-modified-p) " ◉ %s" "  ●  %s - Emacs") project-name))))))
```
