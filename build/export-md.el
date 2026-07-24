;;; build/export-md.el --- Batch-export src/**/*.org to Hugo Markdown via ox-hugo
;;
;;; Usage:  emacs -Q --batch -l build/export-md.el
;;;
;;; Walks every `src/<module>/' directory that has a Makefile (matching
;;; the top-level src/Makefile's own auto-discovery rule), and for every
;;; *.org file in such a module:
;;;
;;;   1. find-file's the real source file so #+setupfile: ../headers
;;;      resolves relative to the file's directory.
;;;   2. Inserts (without saving) the three ox-hugo keywords
;;;      (#+hugo_base_dir, #+hugo_section, #+export_file_name) so the
;;;      literate source files stay free of build concerns.
;;;   3. Calls org-hugo-export-to-md, which writes the .md to
;;;      <site>/content/docs/<module>/<export-file-name>.md.
;;;   4. Kills the buffer without saving -- the .org file is never
;;;      modified.
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

(defvar my/src-dir (expand-file-name "src" my/repo-root)
  "Absolute path to the literate config source tree (src/).")

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

;; --- Module discovery -----------------------------------------------------

(defun my/find-modules ()
  "Return a sorted list of module names (basenames of src/<module>/ dirs
that have a Makefile)."
  (let (modules)
    (dolist (entry (directory-files my/src-dir nil "^[^.]" t))
      (let* ((path (expand-file-name entry my/src-dir))
             (makefile (expand-file-name "Makefile" path)))
        (when (and (file-directory-p path) (file-exists-p makefile))
          (push entry modules))))
    (sort modules #'string<)))

(defun my/find-org-files (module)
  "Return all *.org files under src/<MODULE>/, with editor cruft excluded."
  (let (files)
    (dolist (f (directory-files-recursively
                (expand-file-name module my/src-dir) "\\.org$"))
      (let ((name (file-name-nondirectory f)))
        (unless (or (string-prefix-p ".#" name)
                    (string-suffix-p "~" name))
          (push f files))))
    (sort files #'string<)))

;; --- Per-file export -----------------------------------------------------

(defun my/export-one (module org-file)
  "Export ORG-FILE (under src/<MODULE>/) to Hugo Markdown."
  (let* ((rel-from-module
          (file-relative-name org-file
                              (expand-file-name module my/src-dir)))
         ;; Preserve the packages/ subdirectory hierarchy.
         (export-name
          (let ((name (file-name-sans-extension
                       (file-name-nondirectory rel-from-module))))
            (if (string= name "index")
                "_index"
              ;; If the file lives under a subdir (e.g. packages/org.org),
              ;; use just the basename -- the subdir is captured by the
              ;; section path below.
              (file-name-base name))))
         (section
          (concat "docs/" module
                  (let ((dir (file-name-directory rel-from-module)))
                    (if (or (null dir) (string= dir ""))
                        ""
                      (concat "/" (directory-file-name dir))))))
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
  "Export every *.org in every module to Hugo Markdown."
  (let* ((modules (my/find-modules))
         (total 0)
         (failed 0))
    (dolist (m modules)
      (let ((files (my/find-org-files m)))
        (message "[ox-hugo] module %s: %d file(s)" m (length files))
        (dolist (f files)
          (condition-case err
              (progn
                (my/export-one m f)
                (setq total (1+ total))
                (message "[ox-hugo]   %s -> OK" (file-relative-name f my/repo-root)))
            (error
             (setq failed (1+ failed))
             (message "[ox-hugo]   %s -> FAILED: %s"
                      (file-relative-name f my/repo-root)
                      (error-message-string err)))))))
    (message "[ox-hugo] done: %d exported, %d failed" total failed)
    (unless (zerop failed)
      (kill-emacs 1))))

(my/export-all)
