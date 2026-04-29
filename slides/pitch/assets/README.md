# Pitch deck mock assets

Drop real screen mocks here to replace the CSS-rendered iPhone content in the pitch deck.

## File naming convention

The deck integrates by filename. Use exactly these names:

| Filename | Slide | Feature |
|---|---|---|
| `home-celestial.png` | V | Home / Celestial Hero |
| `hybrid-archetype.png` | VI | Two Skies hybrid archetype builder |
| `living-mandala.png` | VII | Living Mandala daily ritual |
| `sacred-timing.png` | VIII | Sacred timing windows |
| `synastry-result.png` | IX | Vedic synastry (Ashtakoot) |
| `astrocartography.png` | X | Prescriptive astrocartography |

## Image spec

- **Format:** PNG (transparent or solid background — both work)
- **Dimensions:** ~600 × 1300 pixels (~2x retina for the deck's 320 × 660 frame inner area)
- **Content area only:** export the SCREEN content, not the iPhone hardware frame. The deck's CSS renders the device shell (rounded corners, notch, status bar) around your image.
- **Status bar:** optional. The deck has its own; if you include yours, it'll layer over.

## Where to design

**For shipped features** (Living Mandala, sacred timing, celestial hero):
- Run the existing app in Xcode → iPhone 15 Pro Max simulator
- Cmd+S for screenshot → saves to ~/Desktop
- Crop to screen content, resize to 600px wide, save here

**For unshipped features** (Two Skies, Synastry, Astrocartography):
- Figma → iPhone 15 Pro Max frame (393 × 852) → design with v2 brand tokens (below) → export selection as PNG @2x
- Or Pencil MCP for AI-assisted exploration → export PNG

## v2 brand tokens (paste into Figma styles)

```
Color
  bg.deep         #0a0805
  bg.elevated     #14110c
  bg.card         #1a160f
  border.subtle   #2a2218
  text.primary    #f5ede0
  text.secondary  #b8a98e
  text.tertiary   #7a6b54
  accent.gold     #c9a96e
  accent.bright   #e0c890

Type
  Display         Geist (Light 300, Regular 400, Medium 500)
  Body            Inter (Light 300, Regular 400, Medium 500)
  Accent (italic) Cormorant Garamond Italic (only)

Radius
  Card            10px
  Pill            3px
  Toggle          8px

Spacing baseline 4pt
```

## Hand back to the deck

When you've dropped one or more files here, the integration is mechanical — replace the CSS mock div in `slides/pitch/index.html` with:

```html
<div class="iphone">
  <div class="iphone-screen">
    <div class="iphone-status"><span>9:41</span><span class="dots">•••</span></div>
    <div class="iphone-content">
      <img src="assets/synastry-result.png" alt="Synastry result mock"
           style="width:100%; height:100%; object-fit:cover; display:block;">
    </div>
  </div>
</div>
```

Or just tell Claude "I dropped synastry-result.png" and it does the swap.

## Redeploy

After dropping a file or replacing a mock:

```bash
cd ../../  # to slides/
vercel --prod --yes
```

Same alias (`https://devi-decks.vercel.app`), fresh build, ~6 seconds.
