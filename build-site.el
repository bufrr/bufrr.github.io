;; Set the package installation directory
(require 'package)
(setq package-user-dir (expand-file-name "./.packages"))
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

;; Initialize the package system
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Install dependencies
(dolist (package '(htmlize))
  (unless (package-installed-p package)
    (package-install package)))

;; Load the publishing system
(require 'ox-publish)

;; Customize the HTML output
(setq org-html-validation-link nil            ;; Don't show validation link
      org-html-head-include-scripts nil       ;; Use our own scripts
      org-html-head-include-default-style nil ;; Use our own styles
      org-html-head "<link rel=\"stylesheet\" href=\"https://cdn.simplecss.org/simple.min.css\" />
<link rel=\"stylesheet\" href=\"./css/style.css\" />")

;; Custom function to format date
(defun my-org-publish-format-date (date)
  (format-time-string "%B %d, %Y" (org-time-string-to-time date)))

;; Custom function to generate date info
(defun my-org-publish-date-info (plist)
  (let ((date (plist-get plist :date))
        (mod-date (plist-get plist :last-modified)))
    (cond
     ;; Both dates available
     ((and date mod-date)
      (format "<p class=\"date-info\">Created: %s | Last updated: %s</p>"
              (my-org-publish-format-date date)
              (my-org-publish-format-date mod-date)))
     ;; Only modification date available
     (mod-date
      (format "<p class=\"date-info\">Last updated: %s</p>"
              (my-org-publish-format-date mod-date)))
     ;; Only creation date available
     (date
      (format "<p class=\"date-info\">Created: %s</p>"
              (my-org-publish-format-date date)))
     ;; No dates available
     (t ""))))

;; Define the publishing project
(setq org-publish-project-alist
      (list
       (list "org-site:main"
             :recursive t
             :base-directory "./content"
             :publishing-function 'org-html-publish-to-html
             :publishing-directory "./public"
             :with-author nil           ;; Don't include author name
             :with-creator t            ;; Include Emacs and Org versions in footer
             :with-toc nil              ;; Include a table of contents
             :with-date t
             :section-numbers nil       ;; Don't include section numbers
             :time-stamp-file nil)))    ;; Don't include time stamp in file

;; Add date info after the title
(setq org-html-postamble nil)
(setq org-html-divs '((preamble "div" "preamble")
                      (content "main" "content")
                      (postamble "div" "postamble")))

(setq org-html-container-element "section")

(setq org-html-format-headline-function
      (lambda (todo todo-type priority text tags info)
        (concat (org-html-format-headline-default-function
                 todo todo-type priority text tags info)
                (my-org-publish-date-info info))))

;; Generate the site output
(org-publish-all t)

(message "Build complete!")