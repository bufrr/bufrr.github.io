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
(setq org-html-validation-link nil
      org-html-head-include-scripts t
      org-html-head-include-default-style t
      org-html-head "<link rel=\"stylesheet\" href=\"css/style.css\" />")

;; Simple function to get tags
(defun my-get-filetags (file project)
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (when (re-search-forward "^#\\+FILETAGS:\\s-*\\(.*\\)" nil t)
      (match-string 1))))

;; Define the publishing project
(setq org-publish-project-alist
      `(("org-site:main"
         :recursive t
         :base-directory "./content"
         :publishing-function org-html-publish-to-html
         :publishing-directory "./public"
         :with-author nil
         :with-creator t
         :with-toc t
         :section-numbers nil
         :time-stamp-file nil
         :html-preamble ,(lambda (info)
                           (let ((tags (my-get-filetags (plist-get info :input-file)
                                                        (plist-get info :project))))
                             (format "<p class=\"date\">Date: %s</p><p class=\"author\">Author: %s</p><p class=\"creator\">%s</p><p class=\"tags\">Tags: %s</p>"
                                     (format-time-string "%Y-%m-%d" (plist-get info :date))
                                     (or (plist-get info :author) "")
                                     (plist-get info :creator)
                                     (or tags ""))))
         :auto-sitemap t
         :sitemap-filename "sitemap.org"
         :sitemap-title "Sitemap"
         :sitemap-sort-files anti-chronologically
         :sitemap-format-entry ,(lambda (file style project)
                                  (format "[[file:%s][%s]] %s"
                                          file
                                          (org-publish-find-title file project)
                                          (format-time-string "%Y-%m-%d" (org-publish-find-date file project))))
         :html-postamble "<p class=\"postamble\">Last Updated %C. Created by %c</p>")))

;; Generate the site output
(org-publish-all t)
(message "Build complete!")
