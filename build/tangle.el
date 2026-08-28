;;; build/tangle.el --- Tangle every *.org under a directory recursively
;;;
;;; Usage:
;;;   emacs -Q --batch -l build/tangle.el -- <dir>
;;;
;;; Walks <dir> recursively, tangling each .org file found.
;;;
;;; Loads only the minimum Emacs needs to tangle: `org', `ob-tangle',
;;; and `ob-emacs-lisp' (so `#+begin_src emacs-lisp' blocks resolve).
;;; Run with `emacs -Q' to skip the user's init file and customizations.
;;;
;;; Fails fast on the first tangle error (Emacs exits non-zero).

;; Invoking this script  puts the trailing args in
;; `command-line-args-left' OR `argv' depending on Emacs version / how
;; `-l' consumes its argument. Pull from both, skipping any `--' separators,
;; to stay robust.
(defun my/tangle--pop-dir ()
  (let ((candidates (append command-line-args-left argv))
        picked)
    (while (and candidates (null picked))
      (let ((a (pop candidates)))
        (unless (and a (string= a "--"))
          (setq picked a))))
    ;; Don't drain argv of unrelated items; only consume what we read.
    (setq command-line-args-left nil)
    picked))

(let* ((dir (my/tangle--pop-dir)))
  (unless dir
    (error "Usage: emacs -Q --batch -l build/tangle.el -- <dir>"))
  (setq dir (expand-file-name dir))
  (unless (file-directory-p dir)
    (error "build/tangle.el: not a directory: %s" dir))
  (setq default-directory dir)

  ;; minimal package set
  (require 'cl-lib)
  (require 'org)
  (require 'ob-tangle)
  (require 'ob-emacs-lisp)

  (setq org-confirm-babel-evaluate nil
        org-export-babel-evaluate nil)

  ;; recursive walk
  (let* ((files
          (cl-remove-if
           (lambda (f)
             (let ((n (file-name-nondirectory f)))
               (or (string-prefix-p ".#" n)
                   (string-suffix-p "~" n))))
           (sort (directory-files-recursively dir "\\.org$")
                 #'string<)))
         (total (length files))
         (i 0))
    (message "[tangle] %d .org file(s) under %s" total dir)
    (dolist (f files)
      (setq i (1+ i))
      (message "[tangle] (%d/%d) %s" i total
               (file-relative-name f dir))
      ;; fail-fast: any error aborts the Emacs batch.
      (org-babel-tangle-file f))
    (message "[tangle] done: %d file(s) tangled" total)))
