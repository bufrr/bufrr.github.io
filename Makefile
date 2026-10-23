# Makefile for blog operations

.PHONY: all build clean serve server dev install-deps new-post publish help kb-lint kb-absorb kb-breakdown

# Default target
all: build

# Build the blog
build:
	@echo "Building blog..."
	@bash build.sh

# Build for production (with minification)
build-prod: build
	@echo "Building for production..."
	@bash minify.sh

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf public/
	@rm -f ~/.org-timestamps/blog-*.cache

# Serve the blog locally
serve: build
	@[ -d public ] || { echo "Build output not found: public/"; exit 1; }
	@echo "Serving blog at http://localhost:8000"
	@python3 -m http.server 8000 --directory "$(CURDIR)/public"

# Alias for serve
server: serve

# Development mode with auto-rebuild
dev:
	@echo "Starting development mode..."
	@command -v inotifywait >/dev/null 2>&1 || { echo "inotifywait is required (install inotify-tools)"; exit 1; }
	@echo "Watching for changes in posts/ and static/"
	@while true; do \
		inotifywait -r -e modify,create,delete posts/ static/ 2>/dev/null; \
		make build; \
	done

# Install dependencies
install-deps:
	@echo "Installing dependencies..."
	@echo "Checking for required tools..."
	@command -v emacs >/dev/null 2>&1 || { echo "Emacs is required but not installed."; exit 1; }
	@command -v python3 >/dev/null 2>&1 || echo "Warning: Python 3 not found (needed for local server)"
	@command -v inotifywait >/dev/null 2>&1 || echo "Warning: inotify-tools not found (needed for dev mode)"
	@echo "Installing Node.js tooling (formatting and minification)..."
	@npm ci || echo "Warning: npm ci failed, skipping JS/CSS tooling"

# Create a new draft post from the template: make new-post TITLE="My post" [SLUG=my-post]
new-post:
	@[ -n "$(TITLE)" ] || { echo 'Usage: make new-post TITLE="Post title" [SLUG=post-slug]'; exit 1; }
	@today=$$(date +%Y-%m-%d); \
	slug="$(SLUG)"; \
	[ -n "$$slug" ] || slug=$$(printf '%s' "$(TITLE)" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$$//'); \
	[ -n "$$slug" ] || { echo 'Could not derive a slug from TITLE; pass SLUG=...'; exit 1; }; \
	file="posts/$$today-$$slug.org"; \
	[ ! -e "$$file" ] || { echo "$$file already exists"; exit 1; }; \
	sed -e "s|^#+TITLE: *$$|#+TITLE: $(TITLE)|" \
	    -e "s|^#+DATE: *$$|#+DATE: $$today|" \
	    -e "s|^#+LASTMOD: *$$|#+LASTMOD: $$today|" \
	    -e "s|^#+AUTHOR: *$$|#+AUTHOR: $${BLOG_AUTHOR:-bytenoob}|" \
	    templates/post-template.org > "$$file"; \
	echo "Created $$file (#+DRAFT: true)"

# Publish to GitHub Pages or other hosting
publish: build
	@echo "Publishing blog..."
	@if [ -d ".git" ]; then \
		git add -A; \
		git commit -m "Update blog - $$(date)"; \
		git push origin main; \
	else \
		echo "No git repository found. Initialize with 'git init' first."; \
	fi

# Knowledge base operations
kb-lint:
	@echo "Running KB health check..."
	@claude -p "Read kb/skills/lint.md. Run a health check on the knowledge base."

kb-absorb:
	@echo "Absorbing new raw files..."
	@claude -p "Read kb/skills/absorb.md. Check kb/raw/ for files not yet in kb/wiki/log.org and absorb them."

kb-breakdown:
	@echo "Finding missing articles..."
	@claude -p "Read kb/skills/breakdown.md. Analyze the wiki for missing articles."

# Help target
help:
	@echo "Blog Makefile - Available targets:"
	@echo "  make build          - Build the blog"
	@echo "  make build-prod     - Build for production (with minification)"
	@echo "  make clean          - Remove build artifacts"
	@echo "  make serve          - Serve blog locally on port 8000"
	@echo "  make dev            - Development mode with auto-rebuild"
	@echo "  make install-deps   - Install required dependencies"
	@echo "  make new-post TITLE=\"...\" - Create a new draft post"
	@echo "  make publish        - Build and publish to git"
	@echo "  make kb-lint        - Run KB health check"
	@echo "  make kb-absorb      - Absorb new raw files into wiki"
	@echo "  make kb-breakdown   - Find missing articles in wiki"
	@echo "  make help           - Show this help message"
