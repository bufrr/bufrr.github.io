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
(setq blog-title-raw (or (getenv "BLOG_TITLE") "Noob Notes"))
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

(defun blog/page-url (name)
  "Public URL of the page exported as NAME.html."
  (if (string= name "index") (concat blog-url "/") (concat blog-url "/" name ".html")))

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
       ;; Link EN/CN translations when both exist
       (let ((en-name base) (cn-name (concat base "-cn")))
         (if (and (file-exists-p (expand-file-name (concat en-name ".org") dir))
                  (file-exists-p (expand-file-name (concat cn-name ".org") dir)))
             (concat
              (format "<link rel=\"alternate\" hreflang=\"en\" href=\"%s\" />\n" (blog/page-url en-name))
              (format "<link rel=\"alternate\" hreflang=\"zh-CN\" href=\"%s\" />\n" (blog/page-url cn-name))
              (format "<link rel=\"alternate\" hreflang=\"x-default\" href=\"%s\" />\n" (blog/page-url en-name)))
           ""))))))

(defun blog/seo-filter (output backend info)
  "Insert per-page SEO tags before </head> in HTML OUTPUT."
  (if (org-export-derived-backend-p backend 'html)
      ;; Build the tags first: blog/seo-head clobbers the match data
      (let ((tags (blog/seo-head info)))
        (if (string-match "</head>" output)
            (replace-match (concat tags "</head>") t t output)
          output))
    output))

;; Common HTML head content
(defun blog/html-head ()
  (concat "<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self';\">
<meta name=\"referrer\" content=\"strict-origin-when-cross-origin\">
<link rel=\"icon\" type=\"image/svg+xml\" href=\"/static/favicon.svg\">
<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">
<link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>
<link href=\"https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600&family=Geist+Mono:wght@400;500&display=swap\" rel=\"stylesheet\">
<link rel=\"stylesheet\" type=\"text/css\" href=\"/static/css/blog.css?v=" (or (getenv "CSS_VERSION") "1") "\" />
<script src=\"/static/js/blog.js?v=" (or (getenv "JS_VERSION") "1") "\" defer></script>"))

;; Custom HTML preamble and postamble
(setq blog-github-user (or (getenv "GITHUB_USERNAME") "bufrr"))

(defun blog/nav-link (key label href &optional external)
  "Render a keyboard-style nav link: [KEY] LABEL."
  (concat "<a href=\"" href "\" data-key=\"" key "\""
          (if external " rel=\"noopener\"" "")
          "><span class=\"k\">[" key "]</span><span class=\"w\">" label "</span></a>"))

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
   "<div class=\"lang-switcher\">"
   "<button class=\"lang-btn active\" data-lang=\"en\">EN</button>"
   "<span class=\"lang-divider\">/</span>"
   "<button class=\"lang-btn\" data-lang=\"cn\">中文</button>"
   "</div>"
   "</nav>"
   "</header>"))

(defun blog/postamble (info)
  (concat
   "<footer class=\"site-footer\">"
   "<div class=\"fb-brand\">"
   "<a class=\"wm\" href=\"/\">" blog-title "</a>"
   "<span class=\"cc\">&copy; " (format-time-string "%Y") " " (blog/html-escape user-full-name) "</span>"
   "</div>"
   "<div class=\"fb-col\">"
   "<div class=\"th\">SITE</div>"
   "<a href=\"/\">Home</a>"
   "<a href=\"/about.html\">About</a>"
   "</div>"
   "<div class=\"fb-col\">"
   "<div class=\"th\">ELSEWHERE</div>"
   "<a href=\"https://github.com/" (blog/html-escape blog-github-user) "\" rel=\"noopener\">GitHub</a>"
   "</div>"
   "<div class=\"fb-built\">"
   "<div class=\"th\">BUILT WITH</div>"
   "<span>Emacs " emacs-version " &amp; Org-mode " (org-version) "</span>"
   "</div>"
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
          (org-list-to-org list)))

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
         :sitemap-sort-files anti-chronologically
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
         :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|mp3\\|ogg\\|swf\\|svg\\|woff\\|woff2\\|ico\\|webp\\|avif"
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
