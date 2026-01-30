# Dobby Mac App — UI/UX Design Guide

**Goal:** Cool, clean, easy to use — Premium Mac app experience

**Inspiration:** Linear, Arc Browser, Things 3, Raycast, Apple Mail

---

## 1. Visual Design Principles

### A. Color Palette

**Dark Mode (Primary):**
```
Background Layers:
- App background: #0F0F0F (near black)
- Surface: #1A1A1A (panels, cards)
- Surface elevated: #242424 (hover, active)
- Borders: #2A2A2A (subtle dividers)

Text:
- Primary: #FFFFFF (main content)
- Secondary: #A0A0A0 (metadata, timestamps)
- Tertiary: #6B6B6B (placeholders, hints)

Accent (Dobby Blue):
- Primary: #3B82F6 (buttons, links, focus)
- Hover: #60A5FA
- Active: #2563EB

Semantic Colors:
- Success: #10B981 (green)
- Warning: #F59E0B (amber)
- Error: #EF4444 (red)
- Info: #3B82F6 (blue)

Priority Colors:
- High: #EF4444 (red)
- Medium: #F59E0B (orange)
- Low: #10B981 (green)
```

**Light Mode:**
```
Background Layers:
- App background: #FFFFFF
- Surface: #F5F5F5
- Surface elevated: #FFFFFF
- Borders: #E5E5E5

Text:
- Primary: #171717
- Secondary: #737373
- Tertiary: #A3A3A3
```

### B. Typography

**System Fonts (Native Mac):**
```
- Display: SF Pro Display (large headings)
- Text: SF Pro Text (body, UI)
- Mono: SF Mono (code blocks)

Hierarchy:
- H1: 28px, Semibold (page titles)
- H2: 20px, Semibold (section headers)
- H3: 16px, Medium (card titles)
- Body: 14px, Regular (main text)
- Caption: 12px, Regular (metadata)
- Code: 13px, SF Mono (code blocks)
```

### C. Spacing System

**8pt Grid (SwiftUI):**
```
- XXS: 4pt  (tight gaps)
- XS:  8pt  (compact spacing)
- S:   12pt (standard gap)
- M:   16pt (section spacing)
- L:   24pt (large gaps)
- XL:  32pt (major sections)
- XXL: 48pt (hero spacing)
```

### D. Iconography

**SF Symbols (Native):**
- Size: 14-16px (standard UI icons)
- Weight: Regular (default), Medium (emphasis)
- Rendering: Monochrome or hierarchical
- Examples:
  - Chat: `bubble.left.fill`
  - Tasks: `checklist`
  - Calendar: `calendar`
  - Search: `magnifyingglass`
  - Settings: `gearshape.fill`

---

## 2. Component Design

### A. Window & Layout

**Main Window:**
- Min size: 1000×700px
- Default: 1280×900px
- Resizable, remembers last size
- Titlebar: Unified (no separator)
- Traffic lights: Standard macOS position
- Vibrancy: Background blur (macOS native)

**Sidebar:**
- Width: 240px (fixed)
- Background: Surface color
- Separator: 1px subtle border
- Hover states: Surface elevated
- Active item: Accent color + bold

**Content Area:**
- Padding: 24px (top/sides), 16px (bottom)
- Max width: 800px for chat (readability)
- Centered for single-column views

### B. Chat Interface

**Message Bubbles:**

**User Messages (right-aligned):**
```
┌────────────────────────────────┐
│                    ┌─────────┐ │
│                    │ Message │ │ ← Blue accent background
│                    │ content │ │   White text
│                    │ here... │ │   16px padding
│                    └─────────┘ │   12px border radius
│                       10:24 AM │ ← Caption size, secondary color
└────────────────────────────────┘
```

**Dobby Messages (left-aligned):**
```
┌────────────────────────────────┐
│ 🤖                             │
│ ┌─────────┐                    │
│ │ Response│                    │ ← Surface elevated background
│ │ with    │                    │   Primary text color
│ │ content │                    │   16px padding
│ └─────────┘                    │   12px border radius
│ 10:24 AM                       │ ← Caption size, secondary color
└────────────────────────────────┘
```

**Code Blocks:**
- Background: #1E1E1E (darker than surface)
- Syntax highlighting: VS Code Dark+ theme
- Font: SF Mono 13px
- Padding: 16px
- Border radius: 8px
- Copy button on hover (top-right)

**Tables:**
- Zebra striping (subtle)
- Header row: Medium weight, secondary text
- Cell padding: 8px horizontal, 6px vertical
- Border: 1px subtle separator

### C. Task Cards (Kanban)

**Card Design:**
```
┌────────────────────────────────┐
│ 🔴 Research IBM Turbonomic     │ ← Priority dot + title (Medium weight)
│                                │
│ 🤖 Created by Dobby            │ ← Caption, secondary color
│ 45 min ago                     │ ← Timestamp
│                                │
│ [View details →]               │ ← Hover-visible action
└────────────────────────────────┘

States:
- Default: Surface color, 1px border
- Hover: Surface elevated, shadow (subtle)
- Dragging: Larger shadow, slight scale (1.02)
- Drop target: Accent border (dashed)

Dimensions:
- Min height: 80px
- Padding: 16px
- Border radius: 12px
- Gap between cards: 12px
```

**Column Design:**
```
┌────────────────────────────────┐
│ 📝 BACKLOG (5)                 │ ← Header: H3, secondary color
├────────────────────────────────┤ ← 1px border separator
│                                │
│ [Task cards stacked here...]   │
│                                │
│ [+ Add task]                   │ ← Hover-visible, center-aligned
└────────────────────────────────┘

Column width: Flexible (equal thirds)
Min width: 280px
Background: Transparent (or subtle surface on hover)
```

### D. Input Fields

**Chat Input:**
```
┌────────────────────────────────┐
│ 🎤 Type or speak...            │ ← Placeholder: tertiary color
└────────────────────────────────┘

States:
- Default: Surface elevated, 1px border
- Focus: Accent border (2px), shadow
- With content: Primary text

Dimensions:
- Height: 44px (single line)
- Max height: 200px (auto-expand)
- Padding: 12px 16px
- Border radius: 12px
- Font: 14px regular
```

**Quick Command Palette (⌘K):**
```
┌────────────────────────────────────────┐
│  ⌘ Quick Command                       │ ← H2, center-aligned
├────────────────────────────────────────┤
│                                        │
│  > research turbonomic_                │ ← Input: 16px, accent color cursor
│                                        │
├────────────────────────────────────────┤
│  💡 Suggestions:                       │
│                                        │
│  📧 Check unread emails          ⌘E   │ ← Item: hover bg, shortcut hint
│  📅 What's on my calendar?       ⌘C   │
│  📊 Show dashboard               ⌘D   │
│  🔍 Search conversations         ⌘F   │
└────────────────────────────────────────┘

Window:
- Size: 600×500px
- Position: Center of screen
- Background: Vibrancy/blur (macOS)
- Shadow: Large, soft
- Border radius: 16px
- Backdrop: 30% black overlay (dismissible)
```

### E. Buttons & Controls

**Primary Button:**
```
Background: Accent blue
Text: White, Medium weight
Padding: 8px 16px
Border radius: 8px
Hover: Lighter blue
Active: Darker blue
Shadow: Subtle on hover
```

**Secondary Button:**
```
Background: Transparent
Text: Accent blue
Border: 1px accent blue
Padding: 8px 16px
Border radius: 8px
Hover: Surface elevated bg
```

**Icon Button:**
```
Size: 32×32px
Icon: 16px
Background: Transparent
Hover: Surface elevated
Active: Accent color (10% opacity)
Border radius: 6px
```

### F. Menu Bar Dropdown

**Design:**
```
┌─────────────────────────────┐
│ 🤖 Dobby                    │ ← Header: H3, padding 16px
├─────────────────────────────┤ ← Separator
│                             │
│ 🎤 Ask Dobby...             │ ← Input field (mini)
│                             │
├─────────────────────────────┤
│ 📧 3 unread emails          │ ← Info cards (subtle bg)
│ 📅 Next: 2pm - Meeting      │   Click to expand
│ ⏰ Reminder: Call John      │
│                             │
├─────────────────────────────┤
│ Open Main Window        ⌘D  │ ← Menu items
│ Quick Command          ⌘⇧D  │   Hover: accent bg
│ Voice Mode              ⌥D  │
├─────────────────────────────┤
│ Settings...                 │
│ Quit                        │
└─────────────────────────────┘

Window:
- Width: 340px
- Max height: 500px (scrollable)
- Position: Below menu bar icon
- Background: Vibrancy (macOS)
- Border radius: 12px
- Shadow: Medium, soft
- Padding: 8px
```

---

## 3. Animations & Transitions

### Principles:
- **Snappy, not slow:** 150-300ms duration
- **Smooth curves:** easeInOut (default), spring for physics
- **Purposeful:** Every animation has meaning
- **Native feel:** SwiftUI standard animations

### Key Animations:

**Window Appear:**
```swift
.transition(.scale(scale: 0.95).combined(with: .opacity))
.animation(.spring(response: 0.3, dampingFraction: 0.8))
```

**Task Card Drag:**
```swift
.scaleEffect(isDragging ? 1.02 : 1.0)
.shadow(radius: isDragging ? 12 : 2)
.animation(.spring(response: 0.3))
```

**Message Bubble Entry:**
```swift
.transition(.move(edge: .bottom).combined(with: .opacity))
.animation(.easeOut(duration: 0.2))
```

**Tab Switch:**
```swift
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
.animation(.easeInOut(duration: 0.2))
```

**Hover States:**
```swift
.animation(.easeInOut(duration: 0.15))
```

---

## 4. Micro-interactions

### A. Feedback

**Hover:**
- Cursor changes (pointer for clickable)
- Background color shift (subtle)
- Scale up slightly (1.02x for cards)

**Click:**
- Scale down briefly (0.98x, 100ms)
- Color shift (active state)
- Haptic feedback (optional, macOS 10.14+)

**Success:**
- Checkmark animation (green)
- Brief scale pulse
- Optional success sound

**Error:**
- Shake animation (horizontal, 3px)
- Red color flash
- Error message (toast/inline)

### B. Loading States

**Spinner:**
- System progress indicator (native)
- Size: 20px (inline), 40px (full-screen)
- Color: Accent blue
- Position: Centered or inline

**Skeleton Screens:**
- For task cards while loading
- Animated shimmer (left to right)
- Same size/shape as real content
- Background: Surface elevated + gradient

**Progress Bar:**
- For long operations (file upload, etc.)
- Height: 4px
- Color: Accent blue
- Background: Surface elevated
- Smooth animation (linear)

---

## 5. Responsive Behavior

### Window Sizes:

**Large (>1200px):**
- Sidebar: 240px
- Chat max-width: 800px
- Task columns: 3 equal (280px min each)

**Medium (900-1200px):**
- Sidebar: 200px
- Chat max-width: 700px
- Task columns: 3 flexible (240px min each)

**Small (<900px):**
- Sidebar: Collapsible (48px icons only)
- Chat max-width: 100%
- Task columns: 2 visible (scroll horizontal)

### Adaptive UI:

**Menu Bar Dropdown:**
- Always same size (340px)
- Scrollable content if needed

**Command Palette:**
- Always centered
- Max height: 80% of screen
- Scrollable suggestions

---

## 6. Accessibility

### Standards:
- WCAG 2.1 AA compliance
- VoiceOver support (native SwiftUI)
- Keyboard navigation (all features)
- Reduced motion support (system preference)
- High contrast mode (system preference)

### Implementation:

**Focus States:**
- Visible focus ring (accent color, 2px)
- Tab order: logical flow
- Escape key: Close modals/palettes

**Text:**
- Min contrast ratio: 4.5:1 (body), 3:1 (large text)
- Resizable (respect system text size)
- Selectable (all content)

**Screen Reader:**
- Descriptive labels for all controls
- Status announcements (task created, etc.)
- Live regions for dynamic content

---

## 7. Polish Details

### Subtle Touches:

1. **Glassmorphism:**
   - Blurred backgrounds (macOS vibrancy)
   - Translucent panels
   - Depth through blur

2. **Shadows:**
   - Layered (multiple shadows for depth)
   - Soft, natural
   - Elevation-based (higher = larger shadow)

3. **Borders:**
   - 1px subtle (not harsh)
   - Semi-transparent
   - Inner shadows for depth

4. **Gradients:**
   - Subtle, not gaudy
   - Accent colors (buttons, backgrounds)
   - Mesh gradients (hero sections, future)

5. **Typography:**
   - Line height: 1.5x (readability)
   - Letter spacing: Tight for headings, default for body
   - Text balance (wrap nicely)

6. **Empty States:**
   - Friendly illustration or icon
   - Helpful message
   - Clear action (button)
   - Example: "No tasks yet. Click + to create one."

---

## 8. Reference Apps

**Study these for inspiration:**

1. **Linear** — Clean task management, keyboard-first
2. **Arc Browser** — Tabs, command palette, sidebar
3. **Things 3** — Beautiful task UI, animations
4. **Raycast** — Command palette, fast, polished
5. **Apple Mail** — Native Mac feel, layout
6. **Notion** — Sidebar navigation, content editing
7. **Superhuman** — Speed, keyboard shortcuts, premium feel

---

## 9. SwiftUI Implementation Notes

### Best Practices:

**Colors:**
```swift
extension Color {
    static let appBackground = Color("AppBackground")
    static let surface = Color("Surface")
    static let accentBlue = Color("AccentBlue")
    // ... etc
}
```

**Spacing:**
```swift
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

**Reusable Components:**
```swift
struct DobbyButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentBlue)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }
}
```

---

**Bottom line:** This should feel **premium**, **fast**, and **delightful** — like a tool you *want* to use daily.
