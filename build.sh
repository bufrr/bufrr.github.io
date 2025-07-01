#!/usr/bin/env bash

# Build script for the blog
# This script runs Emacs in batch mode to generate HTML from org files

set -euo pipefail

# Source configuration if available
if [ -f ".blogrc" ]; then
  # shellcheck source=/dev/null
  source .blogrc
fi

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Building blog...${NC}"

# Get version numbers for cache busting based on file modification time
CSS_VERSION=$(stat -c %Y static/css/blog.css 2> /dev/null || stat -f %m static/css/blog.css 2> /dev/null || echo "1")
JS_VERSION=$(stat -c %Y static/js/blog.js 2> /dev/null || stat -f %m static/js/blog.js 2> /dev/null || echo "1")

# Export for use in Emacs
export CSS_VERSION
export JS_VERSION

# Run Emacs in batch mode to publish the blog
if emacs --batch \
  --eval "
(progn
  ;; Set up directories
  (setq blog-directory (file-name-as-directory (or (getenv \"GITHUB_WORKSPACE\") (expand-file-name \"~/blog\"))))
  (setq blog-posts-directory (concat blog-directory \"posts/\"))
  (setq blog-publish-directory (concat blog-directory \"public/\"))
  (setq blog-static-directory (concat blog-directory \"static/\"))
  (setq blog-templates-directory (concat blog-directory \"templates/\"))
  
  ;; Set user info (use environment variables for security)
  (setq user-full-name (or (getenv \"BLOG_AUTHOR\") \"bytenoob\"))
  (setq user-mail-address (or (getenv \"BLOG_EMAIL\") \"noreply@example.com\"))
  
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
          (let ((htmlize-file (expand-file-name \"htmlize.el\" blog-directory)))
            (when (file-exists-p htmlize-file)
              (load-file htmlize-file))))
        ;; Set htmlize output type if available
        (when (featurep 'htmlize)
          (setq org-html-htmlize-output-type 'css)
          (setq org-html-htmlize-font-prefix \"org-\")
          
          ;; Try to load language modes for better syntax highlighting
          ;; Support multiple Emacs versions by finding any build directory
          (when (getenv \"HOME\")
            (let ((straight-dir (expand-file-name \".config/doom/.local/straight/\" (getenv \"HOME\"))))
              (when (file-directory-p straight-dir)
                (dolist (build-dir (directory-files straight-dir t \"^build\"))
                  (when (file-directory-p build-dir)
                    (dolist (pkg '(\"go-mode\" \"rust-mode\" \"python-mode\" \"js2-mode\"))
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
          (add-to-list 'auto-mode-alist '(\"\\\\.go\\\\'\" . go-mode))
          (add-to-list 'auto-mode-alist '(\"\\\\.rs\\\\'\" . rust-mode))
          (add-to-list 'auto-mode-alist '(\"\\\\.py\\\\'\" . python-mode))
          (add-to-list 'auto-mode-alist '(\"\\\\.js\\\\'\" . js-mode))
          ))
    (error
     ;; If htmlize fails to load, continue without syntax highlighting
     (message \"Warning: htmlize not available, syntax highlighting disabled\")))
  
  ;; Custom HTML preamble and postamble
  (defun blog/preamble (info)
    (concat
     \"<header class=\\\"site-header\\\">\"
     \"<div class=\\\"container\\\">\"
     \"<h1 class=\\\"site-title\\\"><a href=\\\"/\\\">Noob Notes</a></h1>\"
     \"<nav class=\\\"site-nav\\\">\"
     \"<a href=\\\"/\\\">Home</a>\"
     \"<a href=\\\"/about.html\\\">About</a>\"
     \"<div class=\\\"lang-switcher\\\">\"
     \"<button class=\\\"lang-btn active\\\" data-lang=\\\"en\\\">EN</button>\"
     \"<span class=\\\"lang-divider\\\">|</span>\"
     \"<button class=\\\"lang-btn\\\" data-lang=\\\"cn\\\">中文</button>\"
     \"</div>\"
     \"</nav>\"
     \"</div>\"
     \"</header>\"))
  
  (defun blog/postamble (info)
    (concat
     \"<footer class=\\\"site-footer\\\">\"
     \"<div class=\\\"container\\\">\"
     \"<p>&copy; \" (format-time-string \"%Y\") 
     \" - Built with Emacs \" emacs-version 
     \" & Org-mode \" (org-version) \"</p>\"
     \"</div>\"
     \"</footer>\"))
  
  ;; Function to check if a file is a draft
  (defun blog/is-draft-p (file)
    \"Check if FILE has #+DRAFT: true property.\"
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (re-search-forward \"^#\\\\+DRAFT:\\\\s-*\\\\(true\\\\|t\\\\|yes\\\\)\" nil t)))
  
  ;; Custom publishing function that skips drafts
  (defun blog/publish-to-html (plist filename pub-dir)
    \"Publish an org file to HTML, but skip if it's a draft.\"
    (unless (blog/is-draft-p filename)
      (org-html-publish-to-html plist filename pub-dir)))
  
  ;; Custom sitemap function to exclude author and draft posts
  (defun blog/sitemap-function (title list)
    \"Generate sitemap as an Org file without author metadata and draft posts.\"
    (concat \"#+TITLE: Noob Notes\\n\"
            \"#+AUTHOR:\\n\"
            \"#+OPTIONS: author:nil toc:nil num:nil h:0\\n\\n\"
            (org-list-to-org list)))
  
  ;; Publishing configuration
  (setq org-publish-project-alist
        \`((\"blog-posts\"
           :base-directory ,blog-posts-directory
           :base-extension \"org\"
           :publishing-directory ,blog-publish-directory
           :recursive t
           :publishing-function blog/publish-to-html
           :headline-levels 4
           :section-numbers nil
           :with-toc t
           :with-author t
           :with-date t
           :html-head ,(concat \"<link rel=\\\"icon\\\" type=\\\"image/svg+xml\\\" href=\\\"/static/favicon.svg\\\">
<link rel=\\\"preconnect\\\" href=\\\"https://fonts.googleapis.com\\\">
<link rel=\\\"preconnect\\\" href=\\\"https://fonts.gstatic.com\\\" crossorigin>
<link href=\\\"https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap\\\" rel=\\\"stylesheet\\\">
<link rel=\\\"stylesheet\\\" type=\\\"text/css\\\" href=\\\"/static/css/blog.css?v=\" (or (getenv \"CSS_VERSION\") \"$CSS_VERSION\") \"\\\" />
<script src=\\\"/static/js/blog.js?v=\" (or (getenv \"JS_VERSION\") \"$JS_VERSION\") \"\\\" defer></script>\")
           :html-preamble blog/preamble
           :html-postamble blog/postamble
           :html-head-include-default-style nil
           :html-head-include-scripts nil
           :auto-sitemap t
           :sitemap-filename \"index.org\"
           :sitemap-title \"Posts\"
           :sitemap-sort-files anti-chronologically
           :sitemap-style list
           :sitemap-format-entry (lambda (entry style project)
                                   (format \"[[file:%s][%s]]\"
                                           entry
                                           (org-publish-find-title entry project)))
           :sitemap-function blog/sitemap-function
           :exclude \"404\\\\.org\\\\|about\\\\.org\\\\|-cn\\\\.org\\\\|index-cn\\\\.org\")
          
          (\"blog-pages\"
           :base-directory ,blog-posts-directory
           :base-extension \"org\"
           :publishing-directory ,blog-publish-directory
           :recursive nil
           :publishing-function blog/publish-to-html
           :headline-levels 4
           :section-numbers nil
           :with-toc t
           :with-author t
           :with-date t
           :html-head ,(concat \"<link rel=\\\"icon\\\" type=\\\"image/svg+xml\\\" href=\\\"/static/favicon.svg\\\">
<link rel=\\\"preconnect\\\" href=\\\"https://fonts.googleapis.com\\\">
<link rel=\\\"preconnect\\\" href=\\\"https://fonts.gstatic.com\\\" crossorigin>
<link href=\\\"https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap\\\" rel=\\\"stylesheet\\\">
<link rel=\\\"stylesheet\\\" type=\\\"text/css\\\" href=\\\"/static/css/blog.css?v=\" (or (getenv \"CSS_VERSION\") \"$CSS_VERSION\") \"\\\" />
<script src=\\\"/static/js/blog.js?v=\" (or (getenv \"JS_VERSION\") \"$JS_VERSION\") \"\\\" defer></script>\")
           :html-preamble blog/preamble
           :html-postamble blog/postamble
           :html-head-include-default-style nil
           :html-head-include-scripts nil
           :include (\"about.org\" \"index-cn.org\"))
          
          (\"blog-static\"
           :base-directory ,blog-static-directory
           :base-extension \"css\\\\|js\\\\|png\\\\|jpg\\\\|gif\\\\|pdf\\\\|mp3\\\\|ogg\\\\|swf\\\\|svg\\\\|woff\\\\|woff2\\\\|ico\\\\|webp\\\\|avif\"
           :publishing-directory ,(concat blog-publish-directory \"static/\")
           :recursive t
           :publishing-function org-publish-attachment)
          
          (\"blog\" :components (\"blog-posts\" \"blog-pages\" \"blog-static\"))))
  
  ;; Publish the blog
  (org-publish \"blog\" t)
  (message \"Blog published successfully!\"))
"; then
  echo -e "${GREEN}Build complete!${NC} HTML files generated in public/"

  # Generate sitemap
  if [ -x "./generate-sitemap.sh" ]; then
    ./generate-sitemap.sh
  fi

  # Show build statistics
  if [ -d "public" ]; then
    POST_COUNT=$(find public -name "*.html" -not -name "index.html" | wc -l)
    TOTAL_SIZE=$(du -sh public | cut -f1)
    echo -e "${GREEN}Generated:${NC} $POST_COUNT posts"
    echo -e "${GREEN}Total size:${NC} $TOTAL_SIZE"
  fi
else
  echo -e "${YELLOW}Build completed with warnings${NC}"
fi
