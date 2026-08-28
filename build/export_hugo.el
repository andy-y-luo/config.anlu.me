;;; build/export_hugo.el --- Export every *.org under src/ to Hugo Markdown via ox-hugo
;;;
;;; Usage:
;;;   emacs -Q --batch -l build/export_hugo.el
;;;
;;; Takes no arguments: the export is all-or-nothing. Section paths are
;;; derived from each file's location under src/, so exporting a subset
;;; from a different walk root would mis-derive them. The whole tree
;;; exports in a single Emacs invocation anyway.
;;;
;;; Walks src/ recursively, exporting every *.org file to Hugo
;;; Markdown. There is no separate "module" concept: each file's
;;; section path is derived from its path under src/ -- the first path
;;; segment becomes the section root, and any further subdirs are
;;; preserved verbatim.
;;;
;;; Per file:
;;;
;;;   1. find-file's the real source file so #+setupfile: ../headers
;;;      resolves relative to the file's directory.
;;;   2. Inserts (without saving) the three ox-hugo keywords
;;;      (#+hugo_base_dir, #+hugo_section, #+export_file_name) so the
;;;      literate source files stay free of build concerns.
;;;   3. Calls org-hugo-export-to-md, which writes the .md to
;;;      <site>/content/docs/<section>/<export-file-name>.md.
;;;   4. Kills the buffer without saving -- the .org file is never
;;;      modified.
;;;
;;; Output filenames (including Hugo's `_index.md' section convention)
;;; are decided by `my/export-hugo--output-name'. Files are written
;;; with their final names; there is no post-export rename pass.
;;;
;;; The Hugo base dir is computed from the location of this script so
;;; the same script works locally and in CI.

;; --- Inputs ---------------------------------------------------------------

(defvar my/repo-root
  (file-name-directory
   (directory-file-name
    (file-name-directory
     (or load-file-name buffer-file-name
         (expand-file-name default-directory)))))
  "Absolute path to the repo root (parent of build/).")

(defvar my/hugo-base-dir (expand-file-name "site" my/repo-root)
  "Absolute path to the Hugo project root (the site/ directory).")

(defvar my/src-root (expand-file-name "src" my/repo-root)
  "Absolute path to the literate source tree.")

;; --- Bootstrap -----------------------------------------------------------
;;
;; All of the steps below are no-ops if a user has already bootstrapped
;; Emacs -- e.g. with straight.el. This keeps the script usable both
;; from CI (`emacs -Q --batch`) and from a running user Emacs session,
;; and avoids the "package.el was loaded when straight.el was already
;; loaded" warning.
;;
;; Users with a non-`-Q' init can also silence that warning globally
;; by adding `(setq package-enable-at-startup nil)' to their
;; early-init.el.

(unless (featurep 'package)
  (require 'package))

(unless (assoc "melpa" package-archives)
  (add-to-list 'package-archives
               '("melpa" . "https://melpa.org/packages/") t))

;; package-initialize is idempotent, but skipping it when straight (or
;; another manager) has already initialized packages avoids the
;; double-initialization warning.
(unless (and (boundp 'package--initialized) package--initialized)
  (package-initialize))

(unless (package-installed-p 'ox-hugo)
  (package-refresh-contents)
  (package-install 'ox-hugo))
(require 'ox-hugo)

;; No code-block evaluation in CI: committed #+RESULTS are used as-is,
;; and :noweb no-export means noweb references stay literal (as the
;; source files document). Builds are fully reproducible.
(setq org-export-babel-evaluate nil
      org-export-with-broken-links 'mark
      org-export-with-toc nil)

;; --- Output naming -------------------------------------------------------

(defun my/export-hugo--output-name (base)
  "Return the Hugo output basename for source basename BASE.

Hugo treats `_index.md' as a branch-bundle (section) page and
`index.md' as a leaf-bundle page. A directory's index file must
therefore be `_index.md', or the directory becomes a leaf bundle
and its sibling pages stop being routable."
  (if (string= base "index") "_index" base))

;; --- Recursive walk -----------------------------------------------------

(defun my/find-org-files (root)
  "Return all *.org files under ROOT, with editor cruft excluded."
  (let (files)
    (dolist (f (directory-files-recursively root "\\.org$"))
      (let ((name (file-name-nondirectory f)))
        (unless (or (string-prefix-p ".#" name)
                    (string-suffix-p "~" name))
          (push f files))))
    (sort files #'string<)))

;; --- Per-file export ----------------------------------------------------

(defun my/export-one (root org-file)
  "Export ORG-FILE (under ROOT) to Hugo Markdown."
  (let* ((rel-from-root (file-relative-name org-file root))
         (path-parts (split-string rel-from-root "/" 'omit-nulls))
         ;; Every source file must live in a module directory under
         ;; src/. A file directly under src/ would make its own
         ;; basename the section root (e.g. section "docs/foo.org"),
         ;; so fail loudly instead of writing to a bogus path.
         (_ (unless (cdr path-parts)
              (error "%s sits directly under %s; every .org file must live in a module directory"
                     rel-from-root root)))
         ;; section root = first path segment
         (module (car path-parts))
         ;; preserve any deeper subdirs (e.g. packages/) under the section
         (subdirs (cdr path-parts))
         (mid-dirs (butlast subdirs))
         (subdir-path
          (if mid-dirs
              (concat "/" (mapconcat #'identity mid-dirs "/"))
            ""))
         (export-name (my/export-hugo--output-name
                       (file-name-base (car (last path-parts)))))
         (section (concat "docs/" module subdir-path))
         (buf (find-file-noselect org-file)))
    (unwind-protect
        (with-current-buffer buf
          (goto-char (point-min))
          ;; Strip any pre-existing ox-hugo keywords so re-runs are idempotent.
          (save-excursion
            (let ((case-fold-search t))
              (while (re-search-forward
                      "^[ \t]*#\\+hugo_base_dir:[^\n]*\n" nil t)
                (replace-match ""))
              (while (re-search-forward
                      "^[ \t]*#\\+hugo_section:[^\n]*\n" nil t)
                (replace-match ""))
              (while (re-search-forward
                      "^[ \t]*#\\+export_file_name:[^\n]*\n" nil t)
                (replace-match ""))))
          ;; Insert fresh keywords at the top of the file.
          (goto-char (point-min))
          (insert (format "#+hugo_base_dir: %s\n" my/hugo-base-dir))
          (insert (format "#+hugo_section: %s\n" section))
          (insert (format "#+export_file_name: %s\n" export-name))
          (let ((org-hugo-base-dir my/hugo-base-dir)
                (org-hugo-section section)
                (org-hugo-export-with-toc nil))
            (org-hugo-export-to-md)))
      (when (buffer-live-p buf)
        (kill-buffer buf)))))

(defun my/export-all ()
  "Export every *.org under `my/src-root' to Hugo Markdown."
  (unless (file-directory-p my/src-root)
    (error "build/export_hugo.el: not a directory: %s" my/src-root))
  (let* ((files (my/find-org-files my/src-root))
         (total (length files))
         (i 0)
         (failed 0))
    (message "[export-hugo] %d .org file(s) under %s" total my/src-root)
    (dolist (f files)
      (setq i (1+ i))
      (condition-case err
          (progn
            (my/export-one my/src-root f)
            (message "[export-hugo]   (%d/%d) %s -> OK"
                     i total (file-relative-name f my/repo-root)))
        (error
         (setq failed (1+ failed))
         (message "[export-hugo]   (%d/%d) %s -> FAILED: %s"
                  i total (file-relative-name f my/repo-root)
                  (error-message-string err)))))
    (message "[export-hugo] done: %d exported, %d failed"
             (- total failed) failed)
    (unless (zerop failed)
      (kill-emacs 1))))

(my/export-all)
