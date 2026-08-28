;;; build/export_hugo.el --- Export every *.org under src/ to Hugo Markdown via ox-hugo
;;;
;;; Usage:
;;;   emacs -Q --batch -l build/export_hugo.el
;;;
;;; Walks src/ recursively and exports each *.org to Hugo Markdown.
;;; The section is the file's directory path under src/ (joined by
;;; "/"); for files at src/ root, the section is empty. For each file:
;;;
;;;   1. find-file it so #+setupfile: ../headers resolves correctly.
;;;   2. Inject #+hugo_base_dir and #+export_file_name (and
;;;      #+hugo_section when the section is non-empty) without saving.
;;;   3. Call org-hugo-export-to-md, which writes the .md to
;;;      <site>/content/<section>/<export-file-name>.md.
;;;   4. Kill the buffer without saving -- the .org file is never
;;;      modified.
;;;
;;; Output filenames (including the `_index' branch-bundle convention)
;;; are decided by `my/export-hugo--output-name'. The Hugo base dir is
;;; computed from the location of this script.

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

;; bootstrap emacs with necessary dependencies

(unless (featurep 'package)
  (require 'package))

(unless (assoc "melpa" package-archives)
  (add-to-list 'package-archives
               '("melpa" . "https://melpa.org/packages/") t))

(unless (and (boundp 'package--initialized) package--initialized)
  (package-initialize))

(unless (package-installed-p 'ox-hugo)
  (package-refresh-contents)
  (package-install 'ox-hugo))
(require 'ox-hugo)

;; No code-block evaluation: the export uses committed #+RESULTS as-is
;; and keeps noweb references literal.
(setq org-export-babel-evaluate nil
      org-export-with-broken-links 'mark
      org-export-with-toc nil)

(defun my/export-hugo--output-name (base)
  "Return the Hugo output basename for source basename BASE.

Hugo treats `_index.md' as a branch-bundle (section) page and
`index.md' as a leaf-bundle page. A directory's index file must
therefore be `_index.md', or the directory becomes a leaf bundle
and its sibling pages stop being routable."
  (if (string= base "index") "_index" base))

(defun my/find-org-files (root)
  "Return all *.org files under ROOT, with editor cruft excluded."
  (let (files)
    (dolist (f (directory-files-recursively root "\\.org$"))
      (let ((name (file-name-nondirectory f)))
        (unless (or (string-prefix-p ".#" name)
                    (string-suffix-p "~" name))
          (push f files))))
    (sort files #'string<)))

(defun my/export-one (root org-file)
  "Export ORG-FILE (under ROOT) to Hugo Markdown."
  (let* ((rel-from-root (file-relative-name org-file root))
         (path-parts (split-string rel-from-root "/" 'omit-nulls))
         (dir-parts (butlast path-parts))
         (section (mapconcat #'identity dir-parts "/"))
         (export-name (my/export-hugo--output-name
                       (file-name-base (car (last path-parts)))))
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
          (goto-char (point-min))
          (insert (format "#+hugo_base_dir: %s\n" my/hugo-base-dir))
          (unless (string= section "")
            (insert (format "#+hugo_section: %s\n" section)))
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
