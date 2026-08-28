+++
title = "Emacs Configuration"
author = ["Andy Luo"]
keywords = ["dotfiles", "emacs", "configuration"]
draft = false
+++

## Emacs Configuration {#emacs-configuration}


### Introduction {#introduction}

My journey of using Emacs begins here, with configuring a vanilla installation. These configurations will follow the literate programming paradigm (you're welcome future me), and uses \`org\` tangling to spit out the actual configuration files.

The organization and structure of these configs are highly inspired by [Phundrak's Dotfiles](https://config.phundrak.com/emacs/), with many snippets and ideas shamelessy copied.


### Warning on noweb syntax {#warning-on-noweb-syntax}

This configuration makes heavy use of the [noweb](https://orgmode.org/manual/Noweb-Reference-Syntax.html) syntax. This means if you encounter some code that looks `<<like-this>>`, org-mode will replace this snippet with another code snippet declared elsewhere in my configuration. If you see some code that looks `<<like-this()>>`, some generating code will run and replace this piece of text with the text generated. A quick example:

```elisp
(defun hello ()
  <<generate-docstring()>>
  <<print-hello>>)
```

Will instead appear as

```emacs-lisp
(defun hello ()
  <<generate-docstring()>>
  <<print-hello>>)
```

This is because I have the block of code below named `generate-docstring` which generates an output, which replaces its noweb tag. You can recognize noweb snippets generating code with the parenthesis. Often, such blocks aren’t visible in my HTML exports, but you can still see them if you open the actual org source file.

<a id="code-snippet--generate-docstring"></a>
```emacs-lisp
(concat "\""
        "Print \\\"Hello World!\\\" in the minibuffer."
        "\"")
```

On the other hand, noweb snippets without parenthesis simply replace the snippet with the equivalent named code block. For instance the one below is named `print-hello` and is placed as-is in the target source block.

<a id="code-snippet--print-hello"></a>
```emacs-lisp
(message "Hello World!")
```


### Loading all configuration modules {#loading-all-configuration-modules}

The configuration is split between files for better organization and navigation (a single thousand+ line file is too hard to work with imo).

<a id="table--emacs-modules"></a>

| Module Name              | Config Page                                                       |
|--------------------------|-------------------------------------------------------------------|
| `basic-config.el`        | [Basic Configuration]({{< relref "basic-config" >}})              |
| `custom-elisp.el`        | [Custom Elisp]({{< relref "custom-elisp" >}})                     |
| `package-manager.el`     | [Package Manager]({{< relref "package-manager" >}})               |
| `keybinding-managers.el` | [Keybinding Managers]({{< relref "keybinding-managers" >}})       |
| `applications.el`        | [Packages - Applications]({{< relref "applications" >}})          |
| `autocompletion.el`      | [Packages - Autocompletion]({{< relref "autocompletion" >}})      |
| `org.el`                 | [Packages - Org]({{< relref "org" >}})                            |
| `programming.el`         | [Packages - Programming]({{< relref "programming" >}})            |
| `visual-config.el`       | [Packages - Visual Configuration]({{< relref "visual-config" >}}) |

<a id="code-snippet--generate-modules"></a>
```emacs-lisp
(mapconcat (lambda (line)
             (concat "\"" (string-trim (car line) "=" "=") "\""))
           modules
           " ")
```

```text
"basic-config.el" "custom-elisp.el" "package-manager.el"
```

```emacs-lisp
(dolist (module '(<<generate-modules()>>))
  (load (expand-file-name module
                          (expand-file-name "lisp" user-emacs-directory))))
```
