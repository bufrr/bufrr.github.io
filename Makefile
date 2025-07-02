# Makefile for blog operations

.PHONY: all build clean serve dev install-deps new-post publish help

# Default target
all: build

# Load configuration
-include .blogrc

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
	@echo "Serving blog at http://localhost:8000"
	@cd public && python3 -m http.server 8000

# Development mode with auto-rebuild
dev:
	@echo "Starting development mode..."
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
	@echo "Installing optional Node.js tools for minification..."
	@npm install -g terser cssnano-cli 2>/dev/null || echo "Warning: npm not available, skipping JS/CSS minification tools"

# Create a new blog post
new-post:
	@echo "To create a new blog post, use Doom Emacs:"
	@echo "  SPC B n - Create new post"
	@echo "  SPC B p - Publish blog"
	@echo ""
	@echo "Or run: emacs --eval '(blog/new-post)'"

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

# Help target
help:
	@echo "Blog Makefile - Available targets:"
	@echo "  make build          - Build the blog"
	@echo "  make build-prod     - Build for production (with minification)"
	@echo "  make clean          - Remove build artifacts"
	@echo "  make serve          - Serve blog locally on port 8000"
	@echo "  make dev            - Development mode with auto-rebuild"
	@echo "  make install-deps   - Install required dependencies"
	@echo "  make new-post       - Create a new blog post"
	@echo "  make publish        - Build and publish to git"
	@echo "  make help           - Show this help message"