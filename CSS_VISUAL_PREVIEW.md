# Visual CSS Preview

## Event Cards (Home Page)

### Normal Event Card
```
┌─────────────────────────────────┐
│ [Concert Image]    🔒 Private   │ ← Yellow badge (if private)
│                                 │
│ 🎵 Concerts                     │
│ Summer Music Festival           │
│                                 │
│ 📅 Jun 15, 2026                 │
│ 🪑 50 / 100 seats               │
│ 💰 ₹500                         │
└─────────────────────────────────┘
  Hover: Lifts up with glow
```

### Sold Out Event Card
```
┌─────────────────────────────────┐
│ [Concert Image]   🎫 Sold Out   │ ← Orange gradient badge (pulsing)
│ [Orange overlay 8%]             │
│                                 │
│ 🎵 Concerts                     │
│ Summer Music Festival           │
│                                 │
│ 📅 Jun 15, 2026                 │
│ 🪑 0 / 100 seats                │
│ 💰 ₹500                         │
└─────────────────────────────────┘
  Hover: Still interactive
```

### Expired Event Card
```
┌─────────────────────────────────┐
│ [Concert Image]    ⏰ Expired   │ ← Red gradient badge (pulsing)
│ [Red overlay 10%]               │
│ [Dimmed to 65% opacity]         │
│                                 │
│ 🎵 Concerts                     │
│ Summer Music Festival           │
│                                 │
│ 📅 Jan 15, 2026                 │
│ 🪑 50 / 100 seats               │
│ 💰 ₹500                         │
└─────────────────────────────────┘
  Hover: Slightly less dimmed (80%)
```

## Event Details Page

### Sold Out Event
```
┌─────────────────────────────────────────────────────┐
│  ← Back to Events                                   │
│                                                     │
│  Summer Music Festival                              │
│  ┌──────────────────────┐                          │
│  │ 🎫  Sold Out         │ ← Orange badge (bouncing icon)
│  └──────────────────────┘                          │
│  A spectacular evening of live music...             │
│                                                     │
│  📅 Date: Jun 15, 2026, 7:00 PM                    │
│  🪑 Available Seats: 0 / 100                       │
│  💰 Price: ₹500 per ticket                         │
│                                                     │
│ ┌─────────────────────────────────────────────────┐│
│ │                                                 ││
│ │                    🎫                           ││ ← 80px emoji (rotating)
│ │                                                 ││
│ │          All Tickets Sold Out!                  ││ ← 32px heading
│ │                                                 ││
│ │  Unfortunately, all 100 tickets for this event  ││
│ │  have been booked. Check out other amazing      ││
│ │  events below.                                  ││
│ │                                                 ││
│ │     ┌──────────────────────────────┐           ││
│ │     │ ← Explore Other Events       │           ││ ← Blue gradient button
│ │     └──────────────────────────────┘           ││   (hover: lifts up)
│ │                                                 ││
│ └─────────────────────────────────────────────────┘│
│   ↑ Orange gradient background with blur          │
│   ↑ Orange border (30% opacity)                   │
└─────────────────────────────────────────────────────┘
```

### Expired Event
```
┌─────────────────────────────────────────────────────┐
│  ← Back to Events                                   │
│                                                     │
│  Summer Music Festival                              │
│  ┌──────────────────────┐                          │
│  │ ⏰  Event Expired     │ ← Red badge (bouncing icon)
│  └──────────────────────┘                          │
│  A spectacular evening of live music...             │
│                                                     │
│  📅 Date: Jan 15, 2026, 7:00 PM                    │
│  🪑 Available Seats: 50 / 100                      │
│  💰 Price: ₹500 per ticket                         │
│                                                     │
│ ┌─────────────────────────────────────────────────┐│
│ │                                                 ││
│ │                    ⏰                           ││ ← 80px emoji (pulsing)
│ │                                                 ││
│ │            Event Has Ended                      ││ ← 32px heading
│ │                                                 ││
│ │  This event took place on 15 January 2026,      ││
│ │  07:00 PM. Booking is no longer available.      ││
│ │                                                 ││
│ │     ┌──────────────────────────────┐           ││
│ │     │ ← Browse Upcoming Events     │           ││ ← Blue gradient button
│ │     └──────────────────────────────┘           ││
│ │                                                 ││
│ └─────────────────────────────────────────────────┘│
│   ↑ Red gradient background with blur             │
│   ↑ Red border (30% opacity)                      │
└─────────────────────────────────────────────────────┘
```

## Animation Timeline

### Page Load (Event Details)
```
0.0s: Page loads
      ↓
0.1s: Status badge slides down from top
      ↓
0.3s: Large emoji icon scales from 0 to 1
      ↓
0.4s: Status section fades up from bottom
      ↓
0.5s: All animations complete
      ↓
Loop: Icon animation starts (bounce/rotate/pulse)
      Badge shadow pulses every 2s
```

### Hover Effects
```
Button Hover:
  - Lifts up 2px (transform: translateY(-2px))
  - Shadow increases (0 4px 16px → 0 6px 24px)
  - Gradient brightens slightly
  - Transition: 0.3s ease

Card Hover:
  - Lifts up 8px
  - Shadow increases
  - Glow effect intensifies
  - Transition: 0.3s ease
```

## Color Palette

### Expired (Red Theme)
```
Primary:    #dc2626 (rgb(220, 38, 38))
Secondary:  #b91c1c (rgb(185, 28, 28))
Light:      #fca5a5 (rgb(252, 165, 165))
Shadow:     rgba(220, 38, 38, 0.4)
Overlay:    rgba(220, 38, 38, 0.1)
Border:     rgba(220, 38, 38, 0.3)
```

### Sold Out (Orange Theme)
```
Primary:    #f97316 (rgb(249, 115, 22))
Secondary:  #ea580c (rgb(234, 88, 12))
Light:      #fdba74 (rgb(253, 186, 116))
Shadow:     rgba(249, 115, 22, 0.4)
Overlay:    rgba(249, 115, 22, 0.08)
Border:     rgba(249, 115, 22, 0.3)
```

### Base Theme (Unchanged)
```
Background: rgba(22, 33, 62, 0.6)
Text:       #e4e6eb (rgb(228, 230, 235))
Subtext:    #b8bcc8 (rgb(184, 188, 200))
Accent:     #0070f3 (rgb(0, 112, 243))
Border:     rgba(255, 255, 255, 0.05)
```

## Typography

### Status Section
```
Icon:        80px emoji
Heading:     32px, 700 weight, -0.5px letter-spacing
Description: 16px, 400 weight, 1.8 line-height
Button:      16px, 600 weight
```

### Status Badge (Small)
```
Icon:  18px emoji
Text:  14px, 700 weight, 0.5px letter-spacing
```

### Event Card Badge
```
Text: 12px, 600 weight
```

## Spacing & Layout

### Status Section
```
Padding:        60px 40px
Border Radius:  20px
Border Width:   2px
Icon Margin:    24px bottom
Text Max Width: 600px
Button Margin:  32px top
```

### Status Badge
```
Padding:        10px 20px
Border Radius:  12px
Border Width:   2px
Gap:            8px (between icon and text)
```

### Event Card Badge
```
Position:       absolute top 15px, right 15px
Padding:        8px 16px
Border Radius:  20px
```

## Performance Notes

All animations use GPU-accelerated properties:
- ✅ `transform` (translateY, scale, rotate)
- ✅ `opacity`
- ✅ `box-shadow`
- ❌ No `width`, `height`, `top`, `left` animations

Backdrop blur is hardware-accelerated on modern browsers.

## Browser Compatibility

- Chrome/Edge: Full support ✅
- Firefox: Full support ✅
- Safari: Full support ✅
- Mobile: Full support ✅

Fallbacks:
- `backdrop-filter` gracefully degrades
- Animations can be disabled with `prefers-reduced-motion`
