# Emacs Org-mode Blog Setup

This blog is configured in your Doom Emacs with the Claude Code documentation style.

## Usage

### Create a new blog post

- Use `SPC B n` (capital B) to create a new post
- Enter the title when prompted
- The post will be created with automatic filename and filled template

### Publish your blog

- Use `SPC B p` (capital B) to publish all posts
- Files will be generated in `~/blog/public/`
- Run `./build.sh` for command-line building
- Run `make build-prod` for production build with minification

### Directory Structure

```
~/blog/
├── posts/           # Your org-mode blog posts
├── static/          # CSS, JS, and other assets
│   ├── css/        # Stylesheets
│   ├── js/         # JavaScript files
│   └── favicon.svg # Site favicon
├── templates/       # Post templates
├── public/          # Generated HTML output
├── .github/         # GitHub Actions workflows
│   └── workflows/
│       ├── publish.yml    # Main deployment workflow
│       ├── pr-preview.yml # Pull request previews
│       └── ci.yml         # Continuous integration
├── build.sh         # Build script
├── generate-sitemap.sh  # Sitemap generator
├── minify.sh        # Asset minification
├── Makefile         # Build automation
├── .blogrc          # Configuration file
└── htmlize.el       # Syntax highlighting support
```

### Configuration

The blog can be configured through environment variables in `.blogrc`:

```bash
export BLOG_AUTHOR="your-name"
export BLOG_EMAIL="your-email@example.com"
export BLOG_URL="https://your-domain.com"
export MINIFY_ASSETS="false" # Set to "true" for production
```

### Workflow

1. Create new post: `SPC B n` (capital B)
2. Write your content in org-mode
3. Publish locally: `SPC B p` (capital B) or run `./build.sh`
4. Serve locally: `cd ~/blog/public && python -m http.server`
5. Deploy: Push to GitHub, automatic deployment via Actions

### Working with Drafts

To create draft posts that won't be published:

1. Add `#+DRAFT: true` to the post header
2. When ready to publish, change to `#+DRAFT: false` or remove the line
3. Draft posts are excluded from the sitemap and won't be built

Example draft post header:

```org
#+TITLE: My Draft Post
#+DATE: <2025-01-01>
#+AUTHOR: bytenoob
#+DRAFT: true
#+OPTIONS: toc:t num:nil
```

### Features

The blog includes:

- **Modern Design**: Clean, responsive design inspired by Claude Code docs
- **Automatic Features**:
  - Archive/index generation with newest-first sorting
  - Date extraction from filenames and metadata
  - Cache busting for CSS/JS assets
  - Sitemap.xml generation for SEO
  - 404 error page
- **Developer Experience**:
  - Colored build output with progress indicators
  - Production build with asset minification
  - GitHub Actions for CI/CD
  - Pull request preview builds
- **User Experience**:
  - Dark mode support
  - Mobile responsive design
  - Fast page loads with optimized assets
  - Comprehensive syntax highlighting

### Syntax Highlighting

The blog supports syntax highlighting for code blocks through a dual approach:

1. **Server-side highlighting** (via htmlize.el):
   - Emacs Lisp, Python, JavaScript, Shell, HTML/CSS, SQL

2. **Client-side fallback** (via JavaScript):
   - Go, Rust, JSON, YAML
   - Automatically applied for better accuracy

To add support for more languages:

1. Install the Emacs mode in `~/.config/doom/packages.el`
2. Run `doom sync` to install
3. Test with `./build.sh`
4. If needed, extend the JavaScript fallback in `static/js/blog.js`

### GitHub Actions

The blog includes three workflows:

1. **publish.yml**: Main deployment to GitHub Pages
   - Triggers on push to main branch
   - Builds site with production optimizations
   - Deploys to GitHub Pages

2. **pr-preview.yml**: Preview builds for pull requests
   - Generates preview artifacts
   - Comments on PR with build statistics

3. **ci.yml**: Continuous integration checks
   - Validates Org file syntax and metadata
   - Runs ShellCheck on scripts
   - Tests build process
   - Checks for broken internal links

### Deployment

#### GitHub Pages

1. Enable GitHub Pages in repository settings
2. Set source to "GitHub Actions"
3. Push to main branch to trigger deployment

#### Custom Domain

1. Add `CNAME` file to `static/` directory
2. Update `BLOG_URL` in `.blogrc` or GitHub Secrets
3. Configure DNS settings with your domain provider

### Troubleshooting

- **Build errors**: Check `build.sh` output for detailed error messages
- **Syntax highlighting issues**: Ensure required Emacs modes are installed
- **GitHub Actions failures**: Check workflow logs in Actions tab
- **Local preview issues**: Ensure Python 3 is installed for local server
