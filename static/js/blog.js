/**
 * Unified blog functionality
 * Combines sidebar, TOC, and metadata features with improved error handling and performance
 */

(function () {
  'use strict';

  // Feature detection
  const features = {
    intersectionObserver: 'IntersectionObserver' in window,
    scrollBehavior: 'scrollBehavior' in document.documentElement.style,
    history: window.history && 'pushState' in window.history,
  };

  // Utility functions
  const utils = {
    // Safe querySelector with fallback
    $(selector, context = document) {
      try {
        return context.querySelector(selector);
      } catch (e) {
        console.warn('Invalid selector:', selector);
        return null;
      }
    },

    // Safe querySelectorAll
    $$(selector, context = document) {
      try {
        return Array.from(context.querySelectorAll(selector));
      } catch (e) {
        console.warn('Invalid selector:', selector);
        return [];
      }
    },

    // Debounce function for performance
    debounce(func, wait) {
      let timeout;
      return function executedFunction(...args) {
        const later = () => {
          clearTimeout(timeout);
          func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
      };
    },

    // Safe date parsing
    parseDate(dateStr) {
      try {
        const date = new Date(dateStr);
        return isNaN(date.getTime()) ? null : date;
      } catch (e) {
        return null;
      }
    },

    // Format date consistently
    formatDate(date) {
      if (!date) return '';
      try {
        return date.toLocaleDateString('en-US', {
          year: 'numeric',
          month: 'long',
          day: 'numeric',
        });
      } catch (e) {
        return date.toDateString();
      }
    },
  };

  // Module: Table of Contents functionality
  const TOC = {
    linkMap: new Map(),
    activeId: null,
    scrollHandler: null,

    init() {
      const toc = utils.$('#table-of-contents');
      if (!toc) {
        return;
      }

      // Collect TOC links and headings
      const tocLinks = utils.$$('a', toc);
      const headings = utils.$$('h2[id], h3[id], h4[id]');

      if (!tocLinks.length || !headings.length) return;

      // Build link map
      tocLinks.forEach((link) => {
        const href = link.getAttribute('href');
        if (href && href.startsWith('#')) {
          this.linkMap.set(href.substring(1), link);
        }
      });

      // Set up smooth scrolling
      this.setupSmoothScrolling(tocLinks);

      // Use scroll-based approach as it's more reliable
      this.setupScrollTracking(headings);
    },

    setupSmoothScrolling(links) {
      links.forEach((link) => {
        link.addEventListener('click', (e) => {
          e.preventDefault();
          const targetId = link.getAttribute('href').substring(1);
          const targetElement = utils.$(`#${targetId}`);

          if (targetElement) {
            // Calculate scroll position with offset
            const offset = 80; // Offset from top to account for any fixed headers
            const elementPosition = targetElement.getBoundingClientRect().top;
            const offsetPosition = elementPosition + window.pageYOffset - offset;

            // Immediately set this link as active
            this.setActiveLink(targetId);

            // Smooth scroll to position
            if (features.scrollBehavior) {
              window.scrollTo({
                top: offsetPosition,
                behavior: 'smooth',
              });
            } else {
              window.scrollTo(0, offsetPosition);
            }

            // Update URL without jumping
            if (features.history) {
              history.pushState(null, '', '#' + targetId);
            }
          }
        });
      });
    },

    setupScrollTracking(headings) {
      let ticking = false;
      const scrollOffset = 85; // Match the offset used in smooth scrolling

      const findActiveHeading = () => {
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        let activeId = null;
        let closestDistance = Infinity;

        // Find the heading that's closest to our scroll offset position
        for (let i = 0; i < headings.length; i++) {
          const heading = headings[i];
          const rect = heading.getBoundingClientRect();
          const absoluteTop = rect.top + scrollTop;
          const distance = Math.abs(scrollTop + scrollOffset - absoluteTop);

          // Check if this heading has passed our scroll offset point
          if (absoluteTop <= scrollTop + scrollOffset) {
            // This heading is above our target line
            if (distance < closestDistance) {
              closestDistance = distance;
              activeId = heading.id;
            }
          }
        }

        // If no heading is found and we're near the top, activate the first one
        if (!activeId && scrollTop < scrollOffset && headings.length > 0) {
          activeId = headings[0].id;
        }

        if (activeId && activeId !== this.activeId) {
          this.setActiveLink(activeId);
        }

        ticking = false;
      };

      const onScroll = () => {
        if (!ticking) {
          window.requestAnimationFrame(findActiveHeading);
          ticking = true;
        }
      };

      // Store handler reference for cleanup
      this.scrollHandler = onScroll;

      window.addEventListener('scroll', onScroll, { passive: true });

      // Run once on init after a small delay to ensure DOM is settled
      setTimeout(findActiveHeading, 100);
    },

    setActiveLink(id) {
      // Skip if already active
      if (this.activeId === id) return;

      // Remove previous active class
      if (this.activeId) {
        const prevLink = this.linkMap.get(this.activeId);
        if (prevLink) {
          prevLink.classList.remove('active');
          prevLink.removeAttribute('aria-current');
        }
      }

      // Add active class to current link
      this.activeId = id;
      const currentLink = this.linkMap.get(id);
      if (currentLink) {
        currentLink.classList.add('active');
        currentLink.setAttribute('aria-current', 'location');

        // Ensure active link is visible in TOC
        const toc = utils.$('#table-of-contents');
        if (toc) {
          const tocRect = toc.getBoundingClientRect();
          const linkRect = currentLink.getBoundingClientRect();

          if (linkRect.top < tocRect.top || linkRect.bottom > tocRect.bottom) {
            currentLink.scrollIntoView({ behavior: 'smooth', block: 'center' });
          }
        }
      }
    },

    destroy() {
      if (this.scrollHandler) {
        window.removeEventListener('scroll', this.scrollHandler);
        this.scrollHandler = null;
      }
      this.linkMap.clear();
      this.activeId = null;
    },
  };

  // Module: Sidebar layout
  const Sidebar = {
    init() {
      const toc = utils.$('#table-of-contents');
      const content = utils.$('#content');

      if (!toc || !content) return;

      try {
        // Create wrapper structure using DocumentFragment for performance
        const fragment = document.createDocumentFragment();
        const wrapper = document.createElement('div');
        wrapper.className = 'page-wrapper';

        const sidebar = document.createElement('aside');
        sidebar.className = 'sidebar-left';
        sidebar.setAttribute('role', 'navigation');
        sidebar.setAttribute('aria-label', 'Table of contents');

        const mainContent = document.createElement('div');
        mainContent.className = 'main-content';
        mainContent.setAttribute('role', 'main');

        // Move TOC to sidebar
        sidebar.appendChild(toc);

        // Move remaining content to main area
        while (content.firstChild) {
          if (content.firstChild !== toc) {
            mainContent.appendChild(content.firstChild);
          } else {
            content.removeChild(content.firstChild);
          }
        }

        // Build the new structure
        wrapper.appendChild(sidebar);
        wrapper.appendChild(mainContent);
        fragment.appendChild(wrapper);
        content.appendChild(fragment);

        // Initialize TOC functionality after DOM restructure with a small delay
        // This ensures the DOM has fully settled
        setTimeout(() => {
          TOC.init();
        }, 100);
      } catch (error) {
        console.error('Error creating sidebar layout:', error);
      }
    },
  };

  // Module: Code Copy Button
  const CodeCopy = {
    init() {
      const codeBlocks = utils.$$('.org-src-container pre, pre.src');

      if (!codeBlocks.length) return;

      codeBlocks.forEach((pre) => {
        // Create wrapper div
        const wrapper = document.createElement('div');
        wrapper.className = 'code-block-wrapper';
        pre.parentNode.insertBefore(wrapper, pre);
        wrapper.appendChild(pre);

        // Create copy button
        const button = document.createElement('button');
        button.className = 'code-copy-button';
        button.setAttribute('aria-label', 'Copy code');
        button.innerHTML = 'Copy';

        // Add click handler
        button.addEventListener('click', async () => {
          const code = pre.textContent || pre.innerText;

          try {
            await navigator.clipboard.writeText(code);
            button.innerHTML = '✓ Copied!';
            button.classList.add('copied');

            setTimeout(() => {
              button.innerHTML = 'Copy';
              button.classList.remove('copied');
            }, 2000);
          } catch (err) {
            // Fallback for older browsers
            const textArea = document.createElement('textarea');
            textArea.value = code;
            textArea.style.position = 'fixed';
            textArea.style.opacity = '0';
            document.body.appendChild(textArea);
            textArea.select();

            try {
              document.execCommand('copy');
              button.innerHTML = '✓ Copied!';
              button.classList.add('copied');

              setTimeout(() => {
                button.innerHTML = 'Copy';
                button.classList.remove('copied');
              }, 2000);
            } catch (fallbackErr) {
              button.innerHTML = '✗ Failed';
              setTimeout(() => {
                button.innerHTML = 'Copy';
              }, 2000);
            }

            document.body.removeChild(textArea);
          }
        });

        wrapper.appendChild(button);
      });
    },
  };

  // Module: Metadata display
  const Metadata = {
    init() {
      const title = utils.$('h1.title');
      if (!title) return;

      try {
        const metadata = this.extractMetadata();
        if (Object.keys(metadata).length > 0) {
          const metaElement = this.createMetadataElement(metadata);
          if (metaElement) {
            title.insertAdjacentElement('afterend', metaElement);
          }
        }
      } catch (error) {
        console.error('Error displaying metadata:', error);
      }
    },

    extractMetadata() {
      const metadata = {};

      // Extract from meta tags
      const metaTags = utils.$$('meta[name]');
      metaTags.forEach((meta) => {
        const name = meta.getAttribute('name');
        const content = meta.getAttribute('content');
        if (content) {
          switch (name) {
            case 'author':
              metadata.author = content;
              break;
            case 'keywords':
              metadata.keywords = content;
              break;
            case 'description':
              metadata.description = content;
              break;
          }
        }
      });

      // Extract dates more efficiently
      // Published date from URL
      const urlPath = window.location.pathname;
      const dateMatch = urlPath.match(/(\d{4}-\d{2}-\d{2})/);
      if (dateMatch) {
        const date = utils.parseDate(dateMatch[1]);
        if (date) {
          metadata.publishDate = utils.formatDate(date);
        }
      }

      // Last modified from comment in head section only
      const headElement = document.head;
      if (headElement) {
        // Get the HTML of just the head element
        const headHTML = headElement.innerHTML;
        const dateComment = headHTML.match(/<!-- (\d{4}-\d{2}-\d{2} \w{3}) -->/);
        if (dateComment) {
          const date = utils.parseDate(dateComment[1]);
          if (date) {
            metadata.lastModDate = utils.formatDate(date);
          }
        }
      }

      return metadata;
    },

    createMetadataElement(metadata) {
      const metaDiv = document.createElement('div');
      metaDiv.className = 'article-meta';

      // Author
      if (metadata.author) {
        const authorSpan = document.createElement('span');
        authorSpan.className = 'author';
        authorSpan.setAttribute('data-icon', '👤');
        authorSpan.textContent = `By ${metadata.author}`;
        metaDiv.appendChild(authorSpan);
      }

      // Published date
      if (metadata.publishDate) {
        const dateSpan = document.createElement('span');
        dateSpan.className = 'date';
        dateSpan.setAttribute('data-icon', '📅');
        dateSpan.textContent = metadata.publishDate;
        metaDiv.appendChild(dateSpan);
      }

      // Last modified (only if different from publish date)
      if (metadata.lastModDate && metadata.lastModDate !== metadata.publishDate) {
        const updatedSpan = document.createElement('span');
        updatedSpan.className = 'updated';
        updatedSpan.setAttribute('data-icon', '🔄');
        updatedSpan.textContent = `Updated: ${metadata.lastModDate}`;
        metaDiv.appendChild(updatedSpan);
      }

      // Tags
      if (metadata.keywords) {
        const tagsDiv = document.createElement('div');
        tagsDiv.className = 'tags';
        metadata.keywords.split(',').forEach((tag) => {
          const tagSpan = document.createElement('span');
          tagSpan.className = 'tag';
          tagSpan.textContent = tag.trim();
          tagsDiv.appendChild(tagSpan);
        });
        metaDiv.appendChild(tagsDiv);
      }

      return metaDiv.children.length > 0 ? metaDiv : null;
    },
  };

  // Module: Syntax Highlighting Fallback
  const SyntaxHighlighting = {
    init() {
      // Apply syntax highlighting for code blocks that don't have it
      // This is a fallback for languages where htmlize doesn't work in batch mode
      const codeBlocks = utils.$$('pre.src');

      codeBlocks.forEach((pre) => {
        // Check if the pre element already has syntax highlighting (contains span elements with org- classes)
        const hasHighlighting = pre.querySelector(
          'span.org-keyword, span.org-string, span.org-comment'
        );
        if (!hasHighlighting) {
          // Get the language from the class name
          const classes = pre.className.split(' ');
          const langClass = classes.find((c) => c.startsWith('src-'));
          if (langClass) {
            const lang = langClass.replace('src-', '');

            // Apply basic syntax highlighting for languages that don't work well in batch mode
            if (['go', 'rust', 'json', 'yaml'].includes(lang)) {
              this.applySyntaxHighlighting(pre, lang);
            }
          }
        }
      });
    },

    applySyntaxHighlighting(pre, lang) {
      let code = pre.textContent || pre.innerText;

      // Common patterns for both Go and Rust
      const keywords = {
        go: [
          'package',
          'import',
          'func',
          'type',
          'struct',
          'interface',
          'var',
          'const',
          'if',
          'else',
          'for',
          'range',
          'switch',
          'case',
          'default',
          'return',
          'break',
          'continue',
          'defer',
          'go',
          'chan',
          'make',
          'new',
          'nil',
          'true',
          'false',
        ],
        rust: [
          'use',
          'pub',
          'fn',
          'let',
          'mut',
          'struct',
          'impl',
          'trait',
          'enum',
          'match',
          'if',
          'else',
          'for',
          'while',
          'loop',
          'return',
          'break',
          'continue',
          'self',
          'Self',
          'super',
          'crate',
          'mod',
          'true',
          'false',
          'Some',
          'None',
          'Ok',
          'Err',
          'async',
          'await',
          'move',
          'ref',
          'where',
          'type',
          'const',
          'static',
          'unsafe',
          'extern',
        ],
      };

      const types = {
        go: [
          'string',
          'int',
          'int8',
          'int16',
          'int32',
          'int64',
          'uint',
          'uint8',
          'uint16',
          'uint32',
          'uint64',
          'float32',
          'float64',
          'bool',
          'error',
          'byte',
          'rune',
          'interface{}',
          'any',
        ],
        rust: [
          'String',
          'str',
          'i8',
          'i16',
          'i32',
          'i64',
          'i128',
          'u8',
          'u16',
          'u32',
          'u64',
          'u128',
          'f32',
          'f64',
          'bool',
          'char',
          'Vec',
          'HashMap',
          'Option',
          'Result',
          'Box',
          'Rc',
          'Arc',
          'Cell',
          'RefCell',
          'Mutex',
          'RwLock',
        ],
      };

      // Escape HTML special characters
      const escapeHtml = (str) => {
        const div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
      };

      // Start with escaped HTML
      code = escapeHtml(code);

      // Apply syntax highlighting using a tokenizer approach
      const tokens = [];
      let remaining = code;
      let position = 0;

      // Helper to add a token
      const addToken = (type, text, start, end) => {
        tokens.push({ type, text, start, end });
      };

      // First pass: identify all tokens
      const patterns = [
        // Comments must be first
        ...(lang === 'go' || lang === 'rust'
          ? [
              { regex: /\/\*[\s\S]*?\*\//g, type: 'comment' },
              { regex: /\/\/.*?(?=\n|$)/g, type: 'comment' },
            ]
          : []),
        // YAML comments
        ...(lang === 'yaml' ? [{ regex: /#.*?(?=\n|$)/g, type: 'comment' }] : []),
        // Strings
        { regex: /"(?:[^"\\]|\\.)*"/g, type: 'string' },
        { regex: /'(?:[^'\\]|\\.)*'/g, type: 'string' },
        // Numbers
        { regex: /\b(?:0x[0-9a-fA-F]+|0b[01]+|\d+\.?\d*(?:[eE][+-]?\d+)?)\b/g, type: 'number' },
        // Booleans for JSON/YAML
        ...(lang === 'json' || lang === 'yaml'
          ? [{ regex: /\b(?:true|false|null|True|False|None|yes|no|on|off)\b/g, type: 'boolean' }]
          : []),
        // Rust macros
        ...(lang === 'rust' ? [{ regex: /\b\w+!/g, type: 'macro' }] : []),
        // Rust attributes
        ...(lang === 'rust' ? [{ regex: /#\[[^\]]+\]/g, type: 'attribute' }] : []),
      ];

      // Collect all matches
      const matches = [];
      for (const pattern of patterns) {
        pattern.regex.lastIndex = 0;
        let match;
        while ((match = pattern.regex.exec(code)) !== null) {
          matches.push({
            type: pattern.type,
            text: match[0],
            start: match.index,
            end: match.index + match[0].length,
          });
        }
      }

      // Sort matches by position
      matches.sort((a, b) => a.start - b.start);

      // Remove overlapping matches (keep first)
      const cleanMatches = [];
      let lastEnd = 0;
      for (const match of matches) {
        if (match.start >= lastEnd) {
          cleanMatches.push(match);
          lastEnd = match.end;
        }
      }

      // Build result with highlighting
      let result = '';
      let currentPos = 0;

      for (const match of cleanMatches) {
        // Add unhighlighted text before this match
        if (currentPos < match.start) {
          const unmatched = code.substring(currentPos, match.start);
          result += this.highlightKeywordsAndTypes(unmatched, lang);
        }

        // Add highlighted match
        const className = {
          comment: 'org-comment',
          string: 'org-string',
          number: 'org-constant',
          boolean: 'org-constant',
          macro: 'org-preprocessor',
          attribute: 'org-preprocessor',
        }[match.type];

        result += `<span class="${className}">${match.text}</span>`;
        currentPos = match.end;
      }

      // Add remaining unhighlighted text
      if (currentPos < code.length) {
        result += this.highlightKeywordsAndTypes(code.substring(currentPos), lang);
      }

      // Update the pre element
      pre.innerHTML = result;
    },

    // Helper function to highlight keywords and types in unhighlighted text
    highlightKeywordsAndTypes(text, lang) {
      const keywords = {
        go: [
          'package',
          'import',
          'func',
          'type',
          'struct',
          'interface',
          'var',
          'const',
          'if',
          'else',
          'for',
          'range',
          'switch',
          'case',
          'default',
          'return',
          'break',
          'continue',
          'defer',
          'go',
          'chan',
          'make',
          'new',
          'nil',
          'true',
          'false',
        ],
        rust: [
          'use',
          'pub',
          'fn',
          'let',
          'mut',
          'struct',
          'impl',
          'trait',
          'enum',
          'match',
          'if',
          'else',
          'for',
          'while',
          'loop',
          'return',
          'break',
          'continue',
          'self',
          'Self',
          'super',
          'crate',
          'mod',
          'true',
          'false',
          'Some',
          'None',
          'Ok',
          'Err',
          'async',
          'await',
          'move',
          'ref',
          'where',
          'type',
          'const',
          'static',
          'unsafe',
          'extern',
        ],
        json: [],
        yaml: [],
      };

      const types = {
        go: [
          'string',
          'int',
          'int8',
          'int16',
          'int32',
          'int64',
          'uint',
          'uint8',
          'uint16',
          'uint32',
          'uint64',
          'float32',
          'float64',
          'bool',
          'error',
          'byte',
          'rune',
          'interface{}',
          'any',
        ],
        rust: [
          'String',
          'str',
          'i8',
          'i16',
          'i32',
          'i64',
          'i128',
          'u8',
          'u16',
          'u32',
          'u64',
          'u128',
          'f32',
          'f64',
          'bool',
          'char',
          'Vec',
          'HashMap',
          'Option',
          'Result',
          'Box',
          'Rc',
          'Arc',
          'Cell',
          'RefCell',
          'Mutex',
          'RwLock',
        ],
        json: [],
        yaml: [],
      };

      // For JSON and YAML, highlight property names
      if (lang === 'json' || lang === 'yaml') {
        // Property names in JSON (before colon)
        if (lang === 'json') {
          text = text.replace(/(\w+)(?=\s*:)/g, '<span class="org-variable-name">$1</span>');
        }
        // Property names in YAML (at line start or after whitespace, before colon)
        if (lang === 'yaml') {
          text = text.replace(
            /^(\s*)(\w+)(?=\s*:)/gm,
            '$1<span class="org-variable-name">$2</span>'
          );
          // List items with dash
          text = text.replace(/^(\s*)(-)(\s+)/gm, '$1<span class="org-keyword">$2</span>$3');
        }
        return text;
      }

      // Split text into words and non-words for other languages
      const parts = text.split(/(\b\w+\b)/g);
      let result = '';

      for (let i = 0; i < parts.length; i++) {
        const part = parts[i];
        if (i % 2 === 1) {
          // Word parts
          if (types[lang] && types[lang].includes(part)) {
            result += `<span class="org-type">${part}</span>`;
          } else if (keywords[lang] && keywords[lang].includes(part)) {
            result += `<span class="org-keyword">${part}</span>`;
          } else if (lang === 'go' && i > 0 && parts[i - 1].endsWith('func ')) {
            result += `<span class="org-function-name">${part}</span>`;
          } else if (lang === 'rust' && i > 0 && parts[i - 1].endsWith('fn ')) {
            result += `<span class="org-function-name">${part}</span>`;
          } else {
            result += part;
          }
        } else {
          result += part;
        }
      }

      return result;
    },
  };

  // Language Switcher Module - Define before init()
  const LanguageSwitcher = {
    init() {
      const langButtons = utils.$$('.lang-btn');
      if (!langButtons.length) return;

      // Get current language from localStorage or default to 'en'
      const currentLang = localStorage.getItem('blog-language') || 'en';
      this.setLanguage(currentLang);

      // Check if we should redirect based on language preference
      this.checkAndRedirect(currentLang);

      // Add click handlers to language buttons
      langButtons.forEach((btn) => {
        btn.addEventListener('click', (e) => {
          e.preventDefault();
          e.stopPropagation();
          const lang = btn.getAttribute('data-lang');
          if (lang) {
            this.switchLanguage(lang);
          }
        });
      });
    },

    checkAndRedirect(preferredLang) {
      const currentPath = window.location.pathname;
      const currentFile = currentPath.split('/').pop();

      // Check if we're on a post page
      if (
        currentFile &&
        currentFile.endsWith('.html') &&
        currentFile !== 'index.html' &&
        currentFile !== 'about.html' &&
        currentFile !== '404.html'
      ) {
        // Check if we're on the wrong language version
        const isOnEnglishPage = !currentFile.includes('-cn.html');
        const wantsChineseVersion = preferredLang === 'cn';

        if (isOnEnglishPage && wantsChineseVersion) {
          // User prefers Chinese but is on English page
          const chinesePath = currentPath.replace('.html', '-cn.html');
          // Check if Chinese version exists
          fetch(chinesePath, { method: 'HEAD' })
            .then((response) => {
              if (response.ok) {
                window.location.pathname = chinesePath;
              }
            })
            .catch(() => {
              // Chinese version not available
            });
        } else if (!isOnEnglishPage && preferredLang === 'en') {
          // User prefers English but is on Chinese page
          const englishPath = currentPath.replace('-cn.html', '.html');
          window.location.pathname = englishPath;
        }
      }
    },

    setLanguage(lang) {
      // Update active button state
      const langButtons = utils.$$('.lang-btn');
      langButtons.forEach((btn) => {
        if (btn.getAttribute('data-lang') === lang) {
          btn.classList.add('active');
        } else {
          btn.classList.remove('active');
        }
      });

      // Store language preference
      localStorage.setItem('blog-language', lang);

      // Update page language attribute
      document.documentElement.setAttribute('lang', lang === 'cn' ? 'zh-CN' : 'en');
    },

    switchLanguage(lang) {
      this.setLanguage(lang);

      // Handle page redirects for language switching
      const currentPath = window.location.pathname;
      const currentFile = currentPath.split('/').pop();

      // Check if we're on a post page
      if (
        currentFile &&
        currentFile.endsWith('.html') &&
        currentFile !== 'index.html' &&
        currentFile !== 'about.html' &&
        currentFile !== '404.html'
      ) {
        let newPath;
        if (lang === 'cn') {
          // Switch to Chinese version
          if (!currentFile.includes('-cn.html')) {
            newPath = currentPath.replace('.html', '-cn.html');
          }
        } else {
          // Switch to English version
          if (currentFile.includes('-cn.html')) {
            newPath = currentPath.replace('-cn.html', '.html');
          }
        }

        // Check if the translated version exists by trying to navigate
        if (newPath && newPath !== currentPath) {
          // Try to fetch the page to see if it exists
          fetch(newPath, { method: 'HEAD' })
            .then((response) => {
              if (response.ok) {
                // Redirect to the translated version
                window.location.pathname = newPath;
              }
            })
            .catch(() => {
              // Error checking for translated version
            });
        }
      }
    },
  };

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  function init() {
    // Initialize each module with error boundaries
    const initModule = (name, fn) => {
      try {
        fn();
      } catch (error) {
        console.error(`Error initializing ${name} module:`, error);
      }
    };

    // Initialize sidebar first (it restructures DOM)
    initModule('Sidebar', () => Sidebar.init());

    // Then initialize metadata
    initModule('Metadata', () => Metadata.init());

    // Initialize code copy buttons
    initModule('CodeCopy', () => CodeCopy.init());

    // Initialize syntax highlighting fallback
    initModule('SyntaxHighlighting', () => SyntaxHighlighting.init());

    // TOC is initialized by Sidebar if applicable
    // If no sidebar, initialize TOC directly
    if (!utils.$('#table-of-contents')) {
      initModule('TOC', () => TOC.init());
    }

    // Initialize Language Switcher
    initModule('LanguageSwitcher', () => LanguageSwitcher.init());
  }

  // Cleanup on page unload
  window.addEventListener('beforeunload', () => {
    TOC.destroy();
  });
})();
