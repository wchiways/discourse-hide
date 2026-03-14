# discourse-hide

A Discourse plugin that adds `[hide]...[/hide]` BBCode support for **reply-to-view** content hiding. Wrapped content becomes visible only after a user replies to the topic.

---

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│  User writes a post with [hide]...[/hide]               │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  [hide]                                           │  │
│  │  Here is the hidden download link:                │  │
│  │  https://example.com/secret-file.zip              │  │
│  │  [/hide]                                          │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
          ┌───────────────────────────────┐
          │   Discourse Cook Pipeline     │
          │                               │
          │  1. Markdown → HTML (cooked)  │
          │  2. Extract [hide] blocks     │
          │  3. Replace with placeholder  │
          │  4. Store blocks in DB        │
          └───────────────────────────────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
    ┌──────────────────┐   ┌──────────────────┐
    │  Not Replied Yet │   │  Already Replied  │
    │                  │   │                   │
    │  ┌────────────┐  │   │  ┌────────────┐   │
    │  │ 🔒         │  │   │  │ Download:  │   │
    │  │ Reply to   │  │   │  │ https://.. │   │
    │  │ view this  │  │   │  │            │   │
    │  │ content    │  │   │  └────────────┘   │
    │  └────────────┘  │   │                   │
    └──────────────────┘   └──────────────────┘
```

## Features

- **Reply-to-view** — Hidden content is only revealed after the user posts a reply in the same topic
- **Server-side security** — Hidden content is **never** stored in `post.cooked`; it's kept separately in `PostCustomField` and injected only for authorized users at serialization time
- **Multi-block support** — Use multiple `[hide]...[/hide]` blocks in a single post
- **Staff bypass** — Admins and moderators always see hidden content
- **Author bypass** — The post author always sees their own hidden content
- **Search protection** — Hidden content is stripped from the search index
- **Mobile friendly** — Responsive placeholder UI with 44px minimum touch targets
- **Accessible** — Proper ARIA attributes on placeholder elements
- **Theme compatible** — Uses Discourse CSS custom properties for seamless theme integration
- **XSS protection** — Content is sanitized via `PrettyText.sanitize` before injection

## Installation

### Standard Discourse Plugin Install

```bash
cd /var/discourse
./launcher enter app
cd /var/www/discourse/plugins
git clone https://github.com/wchiways/discourse-hide.git
cd /var/discourse
./launcher rebuild app
```

### Development

```bash
# Clone into Discourse plugins directory
cd discourse/plugins
git clone https://github.com/wchiways/discourse-hide.git

# Restart Discourse
bundle exec rails s
```

After installation, enable the plugin in **Admin > Settings**:

```
discourse_hide_enabled: true
```

## Usage

Wrap any content in `[hide]...[/hide]` tags inside a post:

```
Hey everyone, I have a great resource to share!

[hide]
Here is the secret download link:
https://example.com/my-resource.zip

And the password is: s3cretP@ss
[/hide]

Reply to this topic to reveal the hidden content above!
```

### Visibility Rules

| User Type | Can See Hidden Content? |
|-----------|----------------------|
| Admin / Moderator | Always |
| Post Author | Always |
| Logged-in user who replied | Yes |
| Logged-in user (no reply) | No — sees placeholder |
| Anonymous visitor | No — sees placeholder |

> **Note:** Only *visible* replies count — deleted, hidden, or user-deleted replies do not unlock the content.

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        Data Flow                             │
│                                                              │
│  post.raw          ──────►  cook  ──────►  post.cooked       │
│  (contains [hide])          │              (placeholder only) │
│                             │                                │
│                             ▼                                │
│                    ┌─────────────────┐                       │
│                    │   Extractor     │                       │
│                    │                 │                       │
│                    │ • Parse [hide]  │                       │
│                    │ • Store blocks  │──► PostCustomField    │
│                    │ • Insert        │    "hide_blocks"      │
│                    │   placeholder   │    (JSON array)       │
│                    └─────────────────┘                       │
│                                                              │
│  PostSerializer#cooked                                       │
│         │                                                    │
│         ▼                                                    │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────────┐  │
│  │  Guardian    │───►│   Renderer   │───►│  Final HTML    │  │
│  │             │    │              │    │                │  │
│  │ can_see_    │    │ • Inject or  │    │ • Placeholder  │  │
│  │ hide?(post) │    │   keep       │    │   (no access)  │  │
│  │             │    │   placeholder│    │ • Revealed     │  │
│  └─────────────┘    └──────────────┘    │   (has access) │  │
│                                         └────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### File Structure

```
discourse-hide/
├── plugin.rb                          # Plugin entry point, hooks & serializer
├── about.json                         # Plugin metadata
├── config/
│   └── settings.yml                   # Site settings (enable/disable)
├── lib/hide/
│   ├── extractor.rb                   # Extract [hide] blocks from cooked HTML
│   ├── guardian_extension.rb          # Permission logic (reply-to-view)
│   └── renderer.rb                    # Inject revealed content for authorized users
└── assets/
    ├── javascripts/discourse/
    │   └── api-initializers/
    │       └── hide-bbcode.js         # Frontend placeholder UI & auto-refresh
    └── stylesheets/
        └── hide-bbcode.scss           # Styles for placeholder & revealed blocks
```

### Security Model

```
                    ┌─────────────────────────────┐
                    │      Security Layers         │
                    └─────────────────────────────┘

 Layer 1: Storage         post.cooked = placeholder ONLY
                          (hidden content NEVER in cooked)
                                    │
 Layer 2: Search          register_modifier(:search_index_text)
                          strips [hide] from search index
                                    │
 Layer 3: Serializer      PostSerializer#cooked checks
                          Guardian before injecting content
                                    │
 Layer 4: Sanitization    PrettyText.sanitize() on inject
                          prevents stored XSS
                                    │
 Layer 5: Guardian        Memoized per-topic permission check
                          excludes deleted/hidden replies
```

**What's protected:**
- Email notifications & digests (use `post.cooked` → placeholder only)
- Topic list excerpts (use `post.cooked` → placeholder only)
- Search index (explicitly filtered)
- RSS feeds (use serializer → Guardian-checked)
- API output (use serializer → Guardian-checked)

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `discourse_hide_enabled` | `true` | Enable/disable the [hide] BBCode feature |

## Requirements

- Discourse **3.1.0** or later

## License

MIT
