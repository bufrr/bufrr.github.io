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

;; Function to get creation date
(defun my-get-creation-date (file)
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (if (re-search-forward "^#\\+CREATED:\\s-*\\(.*\\)" nil t)
        (match-string 1)
      "Unknown")))

;; Function to get last modification date
(defun my-get-modification-date (file)
  (format-time-string "%Y-%m-%d" (nth 5 (file-attributes file))))

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
         :html-preamble ""
         :html-postamble ,(lambda (info)
                            (let* ((input-file (plist-get info :input-file))
                                   (creation-date (my-get-creation-date input-file))
                                   (modification-date (my-get-modification-date input-file))
                                   (file-name (file-name-nondirectory (plist-get info :output-file)))
                                   (is-index (string= file-name "index.html")))
                              (if is-index
                                  (format "<div id=\"metadata\">%s</div>" (plist-get info :creator))
                                (format "<div id=\"metadata\">
Updated: %s<br>
Created: %s<br>
%s
</div>"
                                        modification-date
                                        creation-date
                                        (plist-get info :creator)))))
         :auto-sitemap t
         :sitemap-filename "sitemap.org"
         :sitemap-title "Sitemap"
         :sitemap-sort-files anti-chronologically
         :sitemap-format-entry ,(lambda (file style project)
                                  (format "[[file:%s][%s]] %s"
                                          file
                                          (org-publish-find-title file project)
                                          (my-get-modification-date file))))))

;; Generate the site output
(org-publish-all t)
(message "Build complete!")