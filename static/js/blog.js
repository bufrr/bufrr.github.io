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
    observer: null,

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

      // Use IntersectionObserver for better performance
      if (features.intersectionObserver) {
        this.setupIntersectionObserver(headings);
      } else {
        // Fallback to scroll-based approach
        this.setupScrollTracking(headings);
      }
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

    setupIntersectionObserver(headings) {
      const options = {
        rootMargin: '-20% 0px -70% 0px',
        threshold: [0, 0.5, 1],
      };

      this.observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && entry.intersectionRatio > 0) {
            this.setActiveLink(entry.target.id);
          }
        });
      }, options);

      headings.forEach((heading) => {
        this.observer.observe(heading);
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
      if (this.observer) {
        this.observer.disconnect();
        this.observer = null;
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

  // Syntax highlighting configuration
  const SYNTAX_CONFIG = {
    keywords: {
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
    },
    types: {
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
      const code = pre.textContent || pre.innerText;

      const keywords = SYNTAX_CONFIG.keywords;
      const types = SYNTAX_CONFIG.types;

      // Apply syntax highlighting using a tokenizer approach
      const tokens = [];

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

      // Build DOM with safe manipulation
      const fragment = document.createDocumentFragment();
      let currentPos = 0;

      for (const match of cleanMatches) {
        // Add unhighlighted text before this match
        if (currentPos < match.start) {
          const unmatched = code.substring(currentPos, match.start);
          this.appendHighlightedKeywordsAndTypes(fragment, unmatched, lang);
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

        const span = document.createElement('span');
        span.className = className;
        span.textContent = match.text;
        fragment.appendChild(span);

        currentPos = match.end;
      }

      // Add remaining unhighlighted text
      if (currentPos < code.length) {
        this.appendHighlightedKeywordsAndTypes(fragment, code.substring(currentPos), lang);
      }

      // Replace pre content safely
      pre.textContent = ''; // Clear existing content
      pre.appendChild(fragment);
    },

    // Helper function to append highlighted keywords and types using DOM manipulation
    appendHighlightedKeywordsAndTypes(fragment, text, lang) {
      const keywords = SYNTAX_CONFIG.keywords;
      const types = SYNTAX_CONFIG.types;

      // For JSON and YAML, handle property names specially
      if (lang === 'json' || lang === 'yaml') {
        if (lang === 'json') {
          // JSON property names (before colon)
          const jsonParts = text.split(/(\w+)(?=\s*:)/g);
          for (let i = 0; i < jsonParts.length; i++) {
            if (i % 2 === 1) {
              const span = document.createElement('span');
              span.className = 'org-variable-name';
              span.textContent = jsonParts[i];
              fragment.appendChild(span);
            } else if (jsonParts[i]) {
              fragment.appendChild(document.createTextNode(jsonParts[i]));
            }
          }
        } else if (lang === 'yaml') {
          // YAML is more complex due to line-based structure
          const lines = text.split('\n');
          lines.forEach((line, index) => {
            if (index > 0) fragment.appendChild(document.createTextNode('\n'));

            // Check for property names at line start
            const propMatch = line.match(/^(\s*)(\w+)(\s*:.*)/);
            if (propMatch) {
              fragment.appendChild(document.createTextNode(propMatch[1])); // whitespace
              const span = document.createElement('span');
              span.className = 'org-variable-name';
              span.textContent = propMatch[2];
              fragment.appendChild(span);
              fragment.appendChild(document.createTextNode(propMatch[3])); // rest of line
            } else {
              // Check for list items
              const listMatch = line.match(/^(\s*)(-)(\s+.*)/);
              if (listMatch) {
                fragment.appendChild(document.createTextNode(listMatch[1])); // whitespace
                const span = document.createElement('span');
                span.className = 'org-keyword';
                span.textContent = listMatch[2];
                fragment.appendChild(span);
                fragment.appendChild(document.createTextNode(listMatch[3])); // rest of line
              } else {
                fragment.appendChild(document.createTextNode(line));
              }
            }
          });
        }
        return;
      }

      // Split text into words and non-words for other languages
      const parts = text.split(/(\b\w+\b)/g);

      for (let i = 0; i < parts.length; i++) {
        const part = parts[i];
        if (i % 2 === 1) {
          // Word parts
          let span = null;

          if (types[lang] && types[lang].includes(part)) {
            span = document.createElement('span');
            span.className = 'org-type';
            span.textContent = part;
          } else if (keywords[lang] && keywords[lang].includes(part)) {
            span = document.createElement('span');
            span.className = 'org-keyword';
            span.textContent = part;
          } else if (lang === 'go' && i > 0 && parts[i - 1].endsWith('func ')) {
            span = document.createElement('span');
            span.className = 'org-function-name';
            span.textContent = part;
          } else if (lang === 'rust' && i > 0 && parts[i - 1].endsWith('fn ')) {
            span = document.createElement('span');
            span.className = 'org-function-name';
            span.textContent = part;
          }

          if (span) {
            fragment.appendChild(span);
          } else {
            fragment.appendChild(document.createTextNode(part));
          }
        } else if (part) {
          fragment.appendChild(document.createTextNode(part));
        }
      }
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
      const currentFile = currentPath.split('/').pop() || 'index.html';

      // Special handling for index pages
      if (currentFile === 'index.html' || currentFile === 'index-cn.html' || currentPath === '/') {
        if (preferredLang === 'cn' && currentFile !== 'index-cn.html') {
          window.location.pathname = '/index-cn.html';
          return;
        } else if (preferredLang === 'en' && currentFile === 'index-cn.html') {
          window.location.pathname = '/index.html';
          return;
        }
      }

      // Check if we're on a post page
      if (
        currentFile &&
        currentFile.endsWith('.html') &&
        currentFile !== 'index.html' &&
        currentFile !== 'index-cn.html' &&
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
      const currentFile = currentPath.split('/').pop() || 'index.html';

      // Special handling for index pages
      if (currentFile === 'index.html' || currentFile === 'index-cn.html' || currentPath === '/') {
        if (lang === 'cn') {
          window.location.pathname = '/index-cn.html';
        } else {
          window.location.pathname = '/index.html';
        }
        return;
      }

      // Check if we're on a post page
      if (
        currentFile &&
        currentFile.endsWith('.html') &&
        currentFile !== 'index.html' &&
        currentFile !== 'index-cn.html' &&
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

    // Initialize syntax highlighting fallback lazily
    const initSyntaxHighlighting = () => {
      if (utils.$$('pre.src').length > 0) {
        initModule('SyntaxHighlighting', () => SyntaxHighlighting.init());
      }
    };

    // Use requestIdleCallback if available, otherwise immediate
    if ('requestIdleCallback' in window) {
      requestIdleCallback(initSyntaxHighlighting, { timeout: 2000 });
    } else {
      setTimeout(initSyntaxHighlighting, 100);
    }

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
