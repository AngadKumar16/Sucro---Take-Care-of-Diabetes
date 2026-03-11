# Home Page Implementation Plan

Transform the current basic Home page into your comprehensive dashboard design with hero section, quick actions, mini timeline, and smart insights.

## Current State Analysis
The existing Home page has basic glucose display and simple summary cards, but lacks the rich dashboard features from your plan.

## Implementation Steps

### 1. **Hero Section Enhancement**
- Add large glucose reading with trend arrow and timestamp ("Now • 104 mg/dL ↑")
- Include secondary line: Insulin on Board (IOB), battery status, last sensor sync
- Make glucose tile tappable to open full CGM graph
- Add critical low/high banner support

### 2. **Mini CGM Timeline Component**
- Create horizontal scrollable 6-12 hour glucose strip
- Add tappable points with event tooltips (meal, bolus, site change)
- Implement pinch-to-expand gesture to Monitor page
- Use Swift Charts for smooth rendering

### 3. **Primary Quick-Action Row**
- Create 3 prominent pill buttons: Log Meal (camera), Quick Bolus, Change Site
- Add long-press functionality for presets
- Implement haptic feedback on interactions

### 4. **Recent Timeline Cards**
- Design compact chronological event cards
- Add swipe gestures (left: delete/edit, right: add note)
- Include icons, timestamps, and brief notes
- Support glucose blips, meals, boluses, activity, site changes

### 5. **Site Snapshot Component**
- Create small body map with last infusion site marked
- Show days/hours since placement
- Add "Mark new site" CTA button

### 6. **Reminders & Smart Suggestions**
- Add upcoming reminders section with snooze
- Implement smart suggestions ("Consider changing site...")
- Connect to automation logic for pattern detection

### 7. **ViewModel Enhancements**
- Add trend calculation for glucose readings
- Implement IOB (Insulin on Board) calculation
- Add device status monitoring
- Create reminder and suggestion logic

### 8. **Accessibility & Polish**
- Ensure large numerals and colorblind-friendly palette
- Add VoiceOver labels and haptic feedback
- Implement empty states with clear CTAs
- Add micro-animations for real-time updates

## Technical Approach
- Create reusable components in Views/Components/
- Extend HomeViewModel with new computed properties
- Use Swift Charts for timeline visualization
- Implement gesture recognizers for interactions
- Add Core Data queries for IOB calculations
