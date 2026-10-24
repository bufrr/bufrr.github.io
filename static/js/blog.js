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
  };

  // Module: Table of Contents functionality
  const TOC = {
    linkMap: new Map(),
    activeId: null,
    scrollHandler: null,
    observer: null,
    clickLockUntil: 0,
    clickLockTimer: null,

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

      // Scroll-based tracking is more stable for nested headings and click-to-scroll behavior.
      this.setupScrollTracking(headings);
    },

    setupSmoothScrolling(links) {
      links.forEach((link) => {
        link.addEventListener('click', (e) => {
          e.preventDefault();
          const targetId = link.getAttribute('href').substring(1);
          const targetElement = utils.$(`#${targetId}`);

          if (targetElement) {
            // Immediately set this link as active
            this.setActiveLink(targetId);
            this.lockActiveState(1200);

            // scrollIntoView honours the headings' CSS scroll-margin-top,
            // which clears the sticky nav at every viewport width
            targetElement.scrollIntoView(
              features.scrollBehavior ? { behavior: 'smooth', block: 'start' } : true
            );

            // Update URL without jumping
            if (features.history) {
              history.pushState(null, '', '#' + targetId);
            }
          }
        });
      });
    },

    lockActiveState(durationMs = 1200) {
      this.clickLockUntil = Date.now() + durationMs;

      if (this.clickLockTimer) {
        clearTimeout(this.clickLockTimer);
      }

      this.clickLockTimer = setTimeout(() => {
        this.clickLockUntil = 0;
        this.clickLockTimer = null;
      }, durationMs);
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
      // Headings land at their CSS scroll-margin-top after a jump; count a
      // heading as reached a little below that line
      const scrollOffset = (parseFloat(getComputedStyle(headings[0]).scrollMarginTop) || 80) + 12;

      const findActiveHeading = () => {
        if (this.clickLockUntil && Date.now() < this.clickLockUntil) {
          ticking = false;
          return;
        }

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

        // At the bottom of the page the last headings can never reach the
        // offset line, so activate the last one
        const atBottom =
          window.innerHeight + scrollTop >= document.documentElement.scrollHeight - 2;
        if (atBottom && scrollTop > 0 && headings.length > 0) {
          activeId = headings[headings.length - 1].id;
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

        // Keep the active link visible inside the rail, which is the scroll
        // container on wide screens. Scroll only the rail, never the window.
        const rail = currentLink.closest('.rail');
        if (rail && rail.scrollHeight > rail.clientHeight) {
          const railRect = rail.getBoundingClientRect();
          const linkRect = currentLink.getBoundingClientRect();

          if (linkRect.top < railRect.top || linkRect.bottom > railRect.bottom) {
            rail.scrollTo({
              top: rail.scrollTop + linkRect.top - railRect.top - rail.clientHeight / 2,
              behavior: features.scrollBehavior ? 'smooth' : 'auto',
            });
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
      if (this.clickLockTimer) {
        clearTimeout(this.clickLockTimer);
        this.clickLockTimer = null;
      }
      this.linkMap.clear();
      this.activeId = null;
      this.clickLockUntil = 0;
    },
  };

  // Build a YYYY-MM-DD string into a local date (avoids UTC off-by-one)
  const dateFromSlug = (str) => {
    const m = str && str.match(/(\d{4})-(\d{2})-(\d{2})/);
    if (!m) return null;
    const date = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
    return isNaN(date.getTime()) ? null : date;
  };

  const shortDate = (date) =>
    date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });

  const el = (tag, className, text) => {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;
    return node;
  };

  // Module: Page layout (hero header, left rail, prose column)
  const Layout = {
    init() {
      const content = utils.$('#content');
      const title = content && utils.$('h1.title', content);
      if (!content || !title) return;

      const isIndex =
        Boolean(utils.$(':scope > .org-ul', content)) &&
        !utils.$(':scope > [class^="outline-"]', content);
      document.documentElement.setAttribute('data-pg', isIndex ? 'index' : 'article');

      const toc = utils.$('#table-of-contents', content);
      const fragment = document.createDocumentFragment();

      // Hero (posts and pages only). The index starts at the post list; its
      // title stays in the prose for screen readers and search engines.
      let hero = null;
      if (isIndex) {
        title.classList.add('sr-only');
      } else {
        hero = el('header', 'hero');
        const hd = el('div', 'hd');
        hd.appendChild(title);
        const description = utils.$('meta[name="description"]');
        if (description && description.content.trim()) {
          hd.appendChild(el('p', 'standfirst', description.content.trim()));
        }
        const meta = Metadata.build(isIndex);
        if (meta) hd.appendChild(meta);
        hero.appendChild(hd);
      }

      // Body grid
      const grid = el('div', 'body-grid');
      const rail = el('aside', 'rail');
      const prose = el('div', 'prose');
      prose.setAttribute('role', 'main');

      if (toc) {
        rail.setAttribute('aria-label', 'Table of contents');
        const heading = utils.$('h2', toc);
        if (heading) heading.remove();
        rail.appendChild(el('div', 'rail-title', title.textContent));
        // Plain label on wide screens; a collapse toggle on narrow screens,
        // where the rail sits above the prose (CSS shows one or the other)
        rail.appendChild(el('div', 'th rail-label', 'TREE'));
        const toggle = el('button', 'th rail-toggle', 'TREE');
        toggle.type = 'button';
        toggle.setAttribute('aria-expanded', 'false');
        toggle.setAttribute('aria-controls', 'table-of-contents');
        toggle.addEventListener('click', () => {
          const open = rail.classList.toggle('open');
          toggle.setAttribute('aria-expanded', String(open));
        });
        rail.appendChild(toggle);
        rail.appendChild(toc);
        utils.$$('a', toc).forEach((a) => a.setAttribute('title', a.textContent));
      }

      while (content.firstChild) {
        prose.appendChild(content.firstChild);
      }

      if (isIndex) PostList.init(prose, rail);

      // Wrap tables so wide ones scroll instead of overflowing the column
      utils.$$('table', prose).forEach((table) => {
        const wrap = el('div', 'table-wrap');
        table.parentNode.insertBefore(wrap, table);
        wrap.appendChild(table);
      });

      grid.appendChild(rail);
      grid.appendChild(prose);
      if (hero) fragment.appendChild(hero);
      fragment.appendChild(grid);
      content.appendChild(fragment);

      if (toc) {
        setTimeout(() => TOC.init(), 100);
        ReadProgress.init();
      }
    },
  };

  // Module: Metadata grid under the title (AUTHOR / TAGS / PUBLISHED / READING TIME)
  const Metadata = {
    build(isIndex) {
      if (isIndex) return null;

      const fields = [];
      const author = utils.$('meta[name="author"]');
      if (author && author.content.trim()) fields.push(['AUTHOR', author.content.trim()]);

      const keywords = utils.$('meta[name="keywords"]');
      if (keywords && keywords.content.trim()) {
        const tags = keywords.content
          .split(',')
          .map((t) => t.trim())
          .filter(Boolean);
        fields.push(['TAGS', tags.join(' · ')]);
      }

      const published = dateFromSlug(window.location.pathname);
      if (published) {
        fields.push(['PUBLISHED', shortDate(published)]);
        fields.push(['READING TIME', `${this.readingMinutes()} min`]);
      }

      if (!fields.length) return null;

      const metaDiv = el('div', 'meta');
      fields.forEach(([label, value]) => {
        const cell = el('div');
        cell.appendChild(el('div', 'lb', label));
        cell.appendChild(el('div', 'vv', value));
        metaDiv.appendChild(cell);
      });
      return metaDiv;
    },

    readingMinutes() {
      const content = utils.$('#content');
      const text = content ? content.textContent : '';
      const cjk = (text.match(/[㐀-鿿]/g) || []).length;
      const words = (text.replace(/[㐀-鿿]/g, ' ').match(/\S+/g) || []).length;
      return Math.max(1, Math.round(cjk / 400 + words / 230));
    },
  };

  // Module: Index page post list (date column + title)
  const PostList = {
    init(prose, rail) {
      const list = utils.$(':scope > .org-ul', prose);
      if (!list) return;

      list.classList.add('post-list');
      const items = utils.$$(':scope > li', list);
      items.forEach((li) => {
        const link = utils.$('a', li);
        const date = link && dateFromSlug(link.getAttribute('href'));
        if (date) li.insertBefore(el('span', 'd', shortDate(date)), li.firstChild);
      });

      rail.appendChild(el('div', 'th', 'ARCHIVE'));
      rail.appendChild(el('div', 'count', `${items.length} posts`));
    },
  };

  // Module: 1px reading progress bar pinned to the top of the viewport
  const ReadProgress = {
    init() {
      const bar = el('div');
      bar.id = 'topProg';
      bar.setAttribute('aria-hidden', 'true');
      document.body.appendChild(bar);

      let ticking = false;
      const update = () => {
        const max = document.documentElement.scrollHeight - window.innerHeight;
        const pct = max > 0 ? Math.min(1, window.pageYOffset / max) : 0;
        bar.style.width = `${pct * 100}%`;
        ticking = false;
      };
      window.addEventListener(
        'scroll',
        () => {
          if (!ticking) {
            window.requestAnimationFrame(update);
            ticking = true;
          }
        },
        { passive: true }
      );
      update();
    },
  };

  // Module: Single-key navigation matching the [K] labels in the nav
  const KeyNav = {
    init() {
      const links = new Map();
      utils.$$('.nav-links a[data-key]').forEach((a) => {
        links.set(a.getAttribute('data-key').toLowerCase(), a);
      });
      if (!links.size) return;

      const path = window.location.pathname.replace(/index(-cn)?\.html$/, '');
      links.forEach((a) => {
        if (a.host === window.location.host && a.pathname === path) {
          a.setAttribute('aria-current', 'page');
        }
      });

      document.addEventListener('keydown', (e) => {
        if (e.metaKey || e.ctrlKey || e.altKey || e.shiftKey || e.isComposing) return;
        const target = e.target;
        if (
          target &&
          (target.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(target.tagName))
        ) {
          return;
        }
        const link = links.get(e.key.toLowerCase());
        if (link) {
          e.preventDefault();
          link.click();
        }
      });
    },
  };

  // Module: Code block header with language label and copy button
  const CodeCopy = {
    init() {
      const codeBlocks = utils.$$('.org-src-container pre, pre.src');

      if (!codeBlocks.length) return;

      codeBlocks.forEach((pre) => {
        const wrapper = el('div', 'code-block-wrapper');
        pre.parentNode.insertBefore(wrapper, pre);

        const header = el('div', 'ch');
        const label = el('span', null, 'CODE');
        const langClass = pre.className.split(' ').find((c) => c.startsWith('src-'));
        if (langClass) label.appendChild(el('span', 'lang', langClass.replace('src-', '')));
        header.appendChild(label);

        const button = el('button', 'code-copy-button', 'COPY');
        button.type = 'button';
        button.setAttribute('aria-label', 'Copy code');
        header.appendChild(button);

        wrapper.appendChild(header);
        wrapper.appendChild(pre);

        const flash = (text, copied) => {
          button.textContent = text;
          button.classList.toggle('copied', copied);
          setTimeout(() => {
            button.textContent = 'COPY';
            button.classList.remove('copied');
          }, 2000);
        };

        button.addEventListener('click', async () => {
          const code = pre.textContent || pre.innerText;

          try {
            await navigator.clipboard.writeText(code);
            flash('COPIED', true);
          } catch (err) {
            // Fallback for older browsers
            const textArea = document.createElement('textarea');
            textArea.value = code;
            textArea.style.position = 'fixed';
            textArea.style.opacity = '0';
            document.body.appendChild(textArea);
            textArea.select();

            try {
              if (!document.execCommand('copy')) throw new Error('copy rejected');
              flash('COPIED', true);
            } catch (fallbackErr) {
              flash('FAILED', false);
            }
            document.body.removeChild(textArea);
          }
        });
      });
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
        { regex: /"(?:[^"\\\n]|\\.)*"/g, type: 'string' },
        // Rust single quotes are char literals only, so lifetimes ('a) stay plain
        lang === 'rust'
          ? { regex: /'(?:[^'\\\n]|\\.)'/g, type: 'string' }
          : { regex: /'(?:[^'\\\n]|\\.)*'/g, type: 'string' },
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
  // A page's language comes from its URL (-cn.html is Chinese). Visitors are
  // only auto-redirected after they explicitly pick a language.
  const LanguageSwitcher = {
    storageKey: 'blog-language',
    memoryPref: null,

    // localStorage can throw (private mode, blocked storage)
    getPreference() {
      try {
        return localStorage.getItem(this.storageKey) || this.memoryPref;
      } catch (e) {
        return this.memoryPref;
      }
    },

    savePreference(lang) {
      this.memoryPref = lang;
      try {
        localStorage.setItem(this.storageKey, lang);
      } catch (e) {
        // Preference lasts for this page only
      }
    },

    pageFile() {
      return window.location.pathname.split('/').pop() || 'index.html';
    },

    pageLang() {
      return this.pageFile().endsWith('-cn.html') ? 'cn' : 'en';
    },

    // Path of this page in the other language, or null for pages that are
    // only published in one language
    translationPath(lang) {
      const file = this.pageFile();
      if (file === 'index.html' || file === 'index-cn.html') {
        return lang === 'cn' ? '/index-cn.html' : '/index.html';
      }
      if (!file.endsWith('.html') || file === 'about.html' || file === '404.html') {
        return null;
      }
      const dir = window.location.pathname.slice(0, -file.length);
      const base = file.replace(/(-cn)?\.html$/, '');
      return dir + base + (lang === 'cn' ? '-cn.html' : '.html');
    },

    isNotFoundPage() {
      return Boolean(utils.$('meta[name="blog-page"][content="404"]'));
    },

    init() {
      const langButtons = utils.$$('.lang-btn');
      if (!langButtons.length) return;

      langButtons.forEach((btn) => {
        btn.addEventListener('click', (e) => {
          e.preventDefault();
          const lang = btn.getAttribute('data-lang');
          if (lang) {
            this.switchLanguage(lang);
          }
        });
      });

      const pageLang = this.pageLang();
      this.markActive(pageLang);
      document.documentElement.setAttribute('lang', pageLang === 'cn' ? 'zh-CN' : 'en');

      const preferred = this.getPreference();
      if (preferred && preferred !== pageLang && !this.isNotFoundPage()) {
        // Automatic redirect: replace, so Back skips the bounced page
        this.goTo(this.translationPath(preferred), null, true);
      }
    },

    markActive(lang) {
      utils.$$('.lang-btn').forEach((btn) => {
        const active = btn.getAttribute('data-lang') === lang;
        btn.classList.toggle('active', active);
        btn.setAttribute('aria-pressed', String(active));
      });
    },

    switchLanguage(lang) {
      this.savePreference(lang);
      if (lang === this.pageLang()) return;

      const home = lang === 'cn' ? '/index-cn.html' : '/index.html';
      this.goTo(this.translationPath(lang), home, false);
    },

    // Navigate to path if it exists, otherwise to fallback (if any)
    goTo(path, fallback, replace) {
      const navigate = (target) => {
        if (target && target !== window.location.pathname) {
          if (replace) {
            window.location.replace(target);
          } else {
            window.location.assign(target);
          }
        }
      };

      if (!path) {
        navigate(fallback);
        return;
      }

      fetch(path, { method: 'HEAD' })
        .then((response) => navigate(response.ok ? path : fallback))
        .catch(() => navigate(fallback));
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

    // Initialize layout first (it restructures DOM)
    initModule('Layout', () => Layout.init());

    // Single-key shortcuts for the nav
    initModule('KeyNav', () => KeyNav.init());

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

    // TOC is initialized by Layout if applicable
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
