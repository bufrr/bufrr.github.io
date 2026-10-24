;;; build.el --- Build system for the blog

;; This file contains the Emacs Lisp code for building the blog
;; It converts Org-mode files to HTML with proper templating

;;; Code:

;; Set up directories
;; Prefer explicit env vars, then CI workspace, then the directory of this file.
(setq blog-directory
      (file-name-as-directory
       (expand-file-name
        (or (getenv "BLOG_DIR")
            (getenv "GITHUB_WORKSPACE")
            (and load-file-name (file-name-directory load-file-name))
            default-directory))))
(setq blog-posts-directory (concat blog-directory "posts/"))
(setq blog-publish-directory (concat blog-directory "public/"))
(setq blog-static-directory (concat blog-directory "static/"))
(setq blog-templates-directory (concat blog-directory "templates/"))

;; HTML escaping function for security
(defun blog/html-escape (str)
  "Escape HTML special characters to prevent XSS attacks."
  (if (not str)
      ""
    (unless (stringp str)
      (setq str (format "%s" str)))
    (with-temp-buffer
      (insert str)
      (goto-char (point-min))
      (while (search-forward-regexp "[&<>\"']" nil t)
        (replace-match
         (pcase (match-string 0)
           ("&" "&amp;")
           ("<" "&lt;")
           (">" "&gt;")
           ("\"" "&quot;")
           ("'" "&#39;"))
         t t))
      (buffer-string))))

;; Set user info (use environment variables for security)
(setq user-full-name (or (getenv "BLOG_AUTHOR") "bytenoob"))
(setq user-mail-address (or (getenv "BLOG_EMAIL") "noreply@example.com"))
(setq blog-title-raw (or (getenv "BLOG_TITLE") "bytenoob"))
(setq blog-title (blog/html-escape blog-title-raw))

;; Load org and ox-publish
(require 'org)
(require 'ox-publish)

;; Try to load htmlize for syntax highlighting
(condition-case nil
    (progn
      ;; Try to load from standard locations
      (require 'htmlize nil t)
      ;; If not found, try to load from a local copy
      (unless (featurep 'htmlize)
        (let ((htmlize-file (expand-file-name "htmlize.el" blog-directory)))
          (when (file-exists-p htmlize-file)
            (load-file htmlize-file))))
      ;; Set htmlize output type if available
      (when (featurep 'htmlize)
        (setq org-html-htmlize-output-type 'css)
        (setq org-html-htmlize-font-prefix "org-")
        
        ;; Try to load language modes for better syntax highlighting
        ;; Support multiple Emacs versions by finding any build directory
        (when (getenv "HOME")
          (let ((straight-dir (expand-file-name ".config/doom/.local/straight/" (getenv "HOME"))))
            (when (file-directory-p straight-dir)
              (dolist (build-dir (directory-files straight-dir t "^build"))
                (when (file-directory-p build-dir)
                  (dolist (pkg '("go-mode" "rust-mode" "python-mode" "js2-mode"))
                    (let ((pkg-dir (expand-file-name pkg build-dir)))
                      (when (file-directory-p pkg-dir)
                        (add-to-list 'load-path pkg-dir)))))))))
        
        ;; Load language modes if available
        (ignore-errors (require 'python-mode nil t))
        (ignore-errors (require 'js2-mode nil t))
        (ignore-errors (require 'js-mode nil t))
        (ignore-errors (require 'go-mode nil t))
        (ignore-errors (require 'rust-mode nil t))
        (ignore-errors (require 'sql-mode nil t))
        (ignore-errors (require 'sh-script nil t))
        (ignore-errors (require 'css-mode nil t))
        (ignore-errors (require 'json-mode nil t))
        (ignore-errors (require 'yaml-mode nil t))
        
        ;; Set up file associations for proper mode detection
        (add-to-list 'auto-mode-alist '("\\.go\\'" . go-mode))
        (add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-mode))
        (add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))
        (add-to-list 'auto-mode-alist '("\\.js\\'" . js-mode))
        ))
  (error
   ;; If htmlize fails to load, continue without syntax highlighting
   (message "Warning: htmlize not available, syntax highlighting disabled")))

;; Per-page SEO and sharing tags. Crawlers and link previews don't run JS,
;; so these are written into the HTML at export time.
(setq blog-url (string-remove-suffix "/" (or (getenv "BLOG_URL") "https://bytenoob.io")))

(defun blog/page-path (name)
  "Site-relative path of the page exported as NAME.html."
  (if (string= name "index") "/" (concat "/" name ".html")))

(defun blog/page-url (name)
  "Public URL of the page exported as NAME.html."
  (concat blog-url (blog/page-path name)))

(defun blog/translated-p (dir base)
  "Non-nil if both BASE.org and BASE-cn.org in DIR are published (not drafts).
about and 404 are English-only pages."
  (let ((en (expand-file-name (concat base ".org") dir))
        (cn (expand-file-name (concat base "-cn.org") dir)))
    (and (not (member base '("about" "404")))
         (file-exists-p en) (file-exists-p cn)
         (not (blog/is-draft-p en)) (not (blog/is-draft-p cn)))))

(defun blog/seo-head (info)
  "Return head tags for the page described by export INFO."
  (let* ((file (plist-get info :input-file))
         (dir (file-name-directory file))
         (name (file-name-base file))
         (cn (string-suffix-p "-cn" name))
         (base (string-remove-suffix "-cn" name))
         (title (blog/html-escape
                 (string-trim (org-element-interpret-data (plist-get info :title)))))
         (desc (blog/html-escape (string-trim (or (plist-get info :description) ""))))
         (date (and (string-match "\\`\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\\)-" name)
                    (match-string 1 name)))
         (url (blog/page-url name))
         (meta (lambda (attr key value)
                 (format "<meta %s=\"%s\" content=\"%s\" />\n" attr key value))))
    (if (string= name "404")
        "<meta name=\"robots\" content=\"noindex\" />\n"
      (concat
       (format "<link rel=\"canonical\" href=\"%s\" />\n" url)
       (funcall meta "property" "og:type" (if date "article" "website"))
       (funcall meta "property" "og:title" title)
       (funcall meta "property" "og:url" url)
       (funcall meta "property" "og:site_name" blog-title)
       (funcall meta "property" "og:locale" (if cn "zh_CN" "en_US"))
       (if (string-empty-p desc) ""
         (funcall meta "property" "og:description" desc))
       (funcall meta "name" "twitter:card" "summary")
       (if date (funcall meta "property" "article:published_time" date) "")
       ;; Link EN/CN translations when both are published
       (if (blog/translated-p dir base)
           (concat
            (format "<link rel=\"alternate\" hreflang=\"en\" href=\"%s\" />\n" (blog/page-url base))
            (format "<link rel=\"alternate\" hreflang=\"zh-CN\" href=\"%s\" />\n" (blog/page-url (concat base "-cn")))
            (format "<link rel=\"alternate\" hreflang=\"x-default\" href=\"%s\" />\n" (blog/page-url base)))
         "")))))

(defun blog/seo-filter (output backend info)
  "Insert per-page SEO tags before </head> in HTML OUTPUT, and suffix the
tab title of every page except the home pages with the site name."
  (if (org-export-derived-backend-p backend 'html)
      ;; Build the tags first: blog/seo-head clobbers the match data
      (let ((tags (blog/seo-head info))
            (name (file-name-base (plist-get info :input-file))))
        (when (string-match "</head>" output)
          (setq output (replace-match (concat tags "</head>") t t output)))
        ;; Scroll container for wide tables (works without JS)
        (setq output (replace-regexp-in-string "<table\\b" "<div class=\"table-wrap\"><table" output t t))
        (setq output (replace-regexp-in-string "</table>" "</table></div>" output t t))
        (when (and (not (member name '("index" "index-cn")))
                   (string-match "<title>\\(.*?\\)</title>" output))
          (setq output (replace-match
                        (concat "<title>\\1 · " blog-title "</title>") t nil output)))
        output)
    output))

;; Common HTML head content
(defun blog/html-head ()
  (concat "<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'self'; script-src 'self'; style-src 'self'; font-src 'self'; img-src 'self' data: https:; connect-src 'self';\">
<meta name=\"referrer\" content=\"strict-origin-when-cross-origin\">
<link rel=\"icon\" type=\"image/svg+xml\" href=\"/static/favicon.svg\">
<link rel=\"apple-touch-icon\" href=\"/static/apple-touch-icon.png\">
<link rel=\"stylesheet\" type=\"text/css\" href=\"/static/css/blog.css?v=" (or (getenv "CSS_VERSION") "1") "\" />
<script src=\"/static/js/blog.js?v=" (or (getenv "JS_VERSION") "1") "\" defer></script>"))

;; Custom HTML preamble and postamble
(setq blog-github-user (or (getenv "GITHUB_USERNAME") "bufrr"))

(defun blog/nav-link (key label href &optional external)
  "Render a keyboard-style nav link: [KEY] LABEL."
  (concat "<a href=\"" href "\" data-key=\"" key "\""
          (if external " rel=\"noopener\"" "")
          "><span class=\"k\">[" key "]</span><span class=\"w\">" label "</span></a>"))

(defun blog/lang-switcher (info)
  "EN/中文 links for the page in INFO: to its translation when both versions
are published, otherwise to that language's home page (marked as fallback)."
  (let* ((file (plist-get info :input-file))
         (name (file-name-base file))
         (cn (string-suffix-p "-cn" name))
         (base (string-remove-suffix "-cn" name))
         (pair (blog/translated-p (file-name-directory file) base))
         (link (lambda (lang label href active)
                 (format "<a class=\"lang-btn%s\" data-lang=\"%s\" href=\"%s\"%s%s>%s</a>"
                         (if active " active" "") lang href
                         (if active " aria-current=\"true\"" "")
                         (if (or pair active) "" " data-fallback=\"true\"")
                         label))))
    (concat
     "<div class=\"lang-switcher\" role=\"group\" aria-label=\"Language\">"
     (funcall link "en" "EN"
              (cond (pair (blog/page-path base)) (cn "/") (t (blog/page-path name)))
              (not cn))
     "<span class=\"lang-divider\" aria-hidden=\"true\">/</span>"
     (funcall link "cn" "中文"
              (cond (pair (blog/page-path (concat base "-cn"))) (cn (blog/page-path name)) (t "/index-cn.html"))
              cn)
     "</div>")))

(defun blog/preamble (info)
  (concat
   "<header class=\"site-header\">"
   "<nav class=\"nav\" aria-label=\"Primary\">"
   "<a class=\"nav-brand\" href=\"/\">" blog-title "<span class=\"cursor\" aria-hidden=\"true\">_</span></a>"
   "<div class=\"nav-links\">"
   (blog/nav-link "H" "HOME" "/")
   (blog/nav-link "A" "ABOUT" "/about.html")
   (blog/nav-link "G" "GITHUB" (concat "https://github.com/" (blog/html-escape blog-github-user)) t)
   "</div>"
   (blog/lang-switcher info)
   "</nav>"
   "</header>"))

(defun blog/postamble (info)
  (concat
   "<footer class=\"site-footer\">"
   "<span class=\"cc\">&copy; " (format-time-string "%Y") " " (blog/html-escape user-full-name) "</span>"
   "<nav class=\"fb-links\" aria-label=\"Footer\">"
   "<a href=\"/\">Home</a>"
   "<a href=\"/about.html\">About</a>"
   "<a href=\"https://github.com/" (blog/html-escape blog-github-user) "\" rel=\"noopener\">GitHub</a>"
   "</nav>"
   "<span class=\"fb-built\">Built with Emacs " emacs-version " &amp; Org-mode " (org-version) "</span>"
   "</footer>"))

;; Function to check if a file is a draft
(defun blog/is-draft-p (file)
  "Check if FILE has #+DRAFT: true in its header (before the first heading)."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let ((case-fold-search t)
          (header-end (save-excursion
                        (if (re-search-forward "^\\*+ " nil t)
                            (match-beginning 0)
                          (point-max)))))
      (re-search-forward "^#\\+DRAFT:\\s-*\\(true\\|t\\|yes\\)\\s-*$" header-end t))))

;; Special pages and Chinese variants are published by "blog-pages" and kept
;; out of the post index. org-publish matches :exclude against file names
;; relative to the base directory, so anchor at the start of the string.
(setq blog-page-regexp "\\`\\(404\\|about\\|index-cn\\)\\.org\\'\\|-cn\\.org\\'")

(defun blog/draft-files ()
  "Return absolute paths of draft posts in `blog-posts-directory'."
  (seq-filter #'blog/is-draft-p
              (directory-files blog-posts-directory t "\\.org\\'")))

(defun blog/posts-exclude-regexp ()
  "Regexp of files to keep out of the post index: special pages and drafts."
  (mapconcat #'identity
             (cons blog-page-regexp
                   (mapcar (lambda (f)
                             (concat "\\`"
                                     (regexp-quote (file-relative-name f blog-posts-directory))
                                     "\\'"))
                           (blog/draft-files)))
             "\\|"))

(defun blog/page-files ()
  "Return file names, relative to posts/, published by \"blog-pages\"."
  (seq-filter (lambda (f) (string-match-p blog-page-regexp f))
              (directory-files blog-posts-directory nil "\\.org\\'")))

;; Function to check if file needs rebuilding
(defun blog/needs-rebuild-p (org-file html-file)
  "Check if ORG-FILE needs to be rebuilt by comparing with HTML-FILE."
  (or (not (file-exists-p html-file))
      (file-newer-than-file-p org-file html-file)
      (not (string= (getenv "INCREMENTAL_BUILD") "true"))))

;; Custom publishing function that skips drafts and unchanged files
(defun blog/publish-to-html (plist filename pub-dir)
  "Publish an org file to HTML, but skip if it's a draft or unchanged."
  (unless (blog/is-draft-p filename)
    (let* ((html-file (concat pub-dir 
                             (file-name-sans-extension 
                              (file-name-nondirectory filename)) 
                             ".html")))
      (if (blog/needs-rebuild-p filename html-file)
          (progn
            (message "Building: %s" filename)
            ;; Chinese variants export with lang="zh-CN" unless #+LANGUAGE says otherwise
            (let ((org-export-default-language
                   (if (string-match-p "-cn\\.org\\'" filename) "zh-CN" "en")))
              (org-html-publish-to-html plist filename pub-dir)))
        (message "Skipping unchanged: %s" filename)))))

;; Custom sitemap function to exclude author and draft posts
(defun blog/sitemap-function (title list)
  "Generate sitemap as an Org file without author metadata and draft posts."
  (concat "#+TITLE: " blog-title-raw "\n"
          "#+AUTHOR:\n"
          (let ((desc (getenv "BLOG_DESCRIPTION")))
            (if (and desc (not (string-empty-p desc)))
                (concat "#+DESCRIPTION: " desc "\n")
              ""))
          "#+OPTIONS: author:nil toc:nil num:nil\n\n"
          ;; Newest first by the date-prefixed file name. Org's own date sort
          ;; falls back to file mtimes for bare #+DATE values.
          (org-list-to-org
           (cons (car list)
                 (sort (copy-sequence (cdr list))
                       (lambda (a b) (string> (car a) (car b))))))))

;; Publishing configuration
(setq org-publish-project-alist
      `(("blog-posts"
         :base-directory ,blog-posts-directory
         :base-extension "org"
         :publishing-directory ,blog-publish-directory
         ;; Posts live directly in posts/; subdirectories are not supported
         :recursive nil
         :publishing-function blog/publish-to-html
         :headline-levels 4
         :section-numbers nil
         :with-toc t
         :with-author t
         :with-date t
         :html-head ,(blog/html-head)
         :html-preamble blog/preamble
         :html-postamble blog/postamble
         :filter-final-output (blog/seo-filter)
         :html-head-include-default-style nil
         :html-head-include-scripts nil
         :auto-sitemap t
         :sitemap-filename "index.org"
         :sitemap-title "Posts"
         :sitemap-sort-files alphabetically
         :sitemap-style list
         :sitemap-format-entry (lambda (entry style project)
                                 (format "[[file:%s][%s]]"
                                         entry
                                         (org-publish-find-title entry project)))
         :sitemap-function blog/sitemap-function
         :exclude ,(blog/posts-exclude-regexp))
        
        ("blog-pages"
         :base-directory ,blog-posts-directory
         :base-extension "org"
         :publishing-directory ,blog-publish-directory
         :recursive nil
         :publishing-function blog/publish-to-html
         :headline-levels 4
         :section-numbers nil
         :with-toc t
         :with-author t
         :with-date t
         :html-head ,(blog/html-head)
         :html-preamble blog/preamble
         :html-postamble blog/postamble
         :filter-final-output (blog/seo-filter)
         :html-head-include-default-style nil
         :html-head-include-scripts nil
         :exclude ".*"
         :include ,(blog/page-files))
        
        ("blog-static"
         :base-directory ,blog-static-directory
         :base-extension "css\\|js\\|txt\\|png\\|jpg\\|gif\\|pdf\\|mp3\\|ogg\\|swf\\|svg\\|woff\\|woff2\\|ico\\|webp\\|avif"
         :publishing-directory ,(concat blog-publish-directory "static/")
         :recursive t
         :publishing-function org-publish-attachment)
        
        ("blog" :components ("blog-posts" "blog-pages" "blog-static"))))

;; Main publishing function
(defun blog/publish-all ()
  "Publish the entire blog."
  (org-publish "blog" t)
  (message "Blog published successfully!"))

(provide 'build)
;;; build.el ends here
