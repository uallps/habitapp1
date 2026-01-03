# 🎨 Iconos de Gamificación - Prompts de Generación

> **Última actualización:** 03-01-2026  
> **Autor:** Lucas Barrientos

Este documento contiene los prompts para generar todos los iconos de logros y trofeos de la app HabitApp.

## 📁 Ubicación de los archivos

Los iconos deben colocarse en:
```
HabitApp/Assets.xcassets/Gamification/
├── Achievements/
│   ├── achievement_streak_3.imageset/
│   ├── achievement_streak_7.imageset/
│   └── ... (resto de logros)
└── Trophies/
    ├── trophy_bronze_beginner.imageset/
    ├── trophy_bronze_streak.imageset/
    └── ... (resto de trofeos)
```

### Formato requerido
- **Tamaño**: 512x512 píxeles (se escala automáticamente)
- **Formato**: PNG con fondo transparente
- **Variantes**: @1x, @2x, @3x (opcional, mínimo @2x)

### Estado actual
- ✅ Estructura de carpetas creada
- ✅ Imagesets configurados con Contents.json
- ⚠️ Usando SF Symbols como fallback hasta generar imágenes

---

## 🎯 Integración con el código

Los iconos se muestran automáticamente en:
- `AchievementsTabView` - Lista de logros
- `TrophyRoomView` - Sala de trofeos
- `GamificationHubView` - Hub principal
- `GamificationIconView` - Componente de icono con fallback

---

## 🏆 LOGROS (26 total)

### Categoría: Rachas 🔥

#### 1. achievement_streak_3.png
```
A circular badge icon with a friendly flame emoji design. Small flame with "3" number inside. Warm orange and yellow gradient background. Cute cartoon style, rounded edges, soft shadows. Clean vector art, mobile app icon style, centered composition, transparent background, 512x512px
```

#### 2. achievement_streak_7.png
```
A circular badge icon with a medium-sized flame emoji. The flame has "7" integrated into the design. Vibrant orange to red gradient. Motivational and energetic feel. Small sparkles around the flame. Cartoon style, clean vector art, mobile app achievement badge, transparent background, 512x512px
```

#### 3. achievement_streak_14.png
```
A circular badge icon featuring a larger, more intense flame with "14" displayed prominently. Fire colors with hints of blue at the base. Small stars orbiting around. Achievement medal style, polished look, clean edges, mobile app icon, transparent background, 512x512px
```

#### 4. achievement_streak_30.png
```
A circular epic badge with a majestic flame surrounded by a golden ring. Number "30" in bold metallic gold. Purple and orange gradient flames. Crown of small flames on top. Epic achievement style, glowing effect, premium look, mobile app icon, transparent background, 512x512px
```

#### 5. achievement_streak_100.png
```
A legendary circular badge with an inferno of flames. Roman numeral "C" (100) in platinum. Blue core flame transitioning to white-hot edges. Lightning bolts around. Legendary rarity, diamond-encrusted border, ethereal glow, mobile app icon, transparent background, 512x512px
```

#### 6. achievement_streak_365.png
```
An ultimate legendary circular badge representing a full year. A phoenix made of flames rising from the center. "365" in glowing golden numbers. Rainbow fire effects, cosmic background elements, ultimate achievement design, maximum epic style, transparent background, 512x512px
```

---

### Categoría: Completados ✅

#### 7. achievement_complete_1.png
```
A circular badge with a single green checkmark inside a circle. Fresh start feeling, mint green colors, simple and clean design. Small celebration sparkles. Beginner friendly, cute style, mobile app achievement icon, transparent background, 512x512px
```

#### 8. achievement_complete_10.png
```
A circular badge with a bold checkmark and "10" number. Green gradient with golden accents. Small medal ribbon at bottom. Progress celebration style, encouraging design, clean vector art, mobile app icon, transparent background, 512x512px
```

#### 9. achievement_complete_50.png
```
A circular badge featuring a checkmark inside a seal design. "50" displayed prominently. Emerald green with silver highlights. Official stamp aesthetic, achievement seal style, premium feel, mobile app icon, transparent background, 512x512px
```

#### 10. achievement_complete_100.png
```
A circular badge with a golden checkmark on a green shield. "100" in bold numbers. Laurel wreath decoration around. Century achievement celebration, Roman centurion inspired, heroic style, mobile app icon, transparent background, 512x512px
```

#### 11. achievement_complete_500.png
```
An epic circular badge with a checkmark on a mighty shield. "500" in metallic purple. Epic glow effects, gemstone accents, warrior achievement style, powerful design, mobile app icon, transparent background, 512x512px
```

#### 12. achievement_complete_1000.png
```
A legendary circular badge with a diamond checkmark. "1000" in platinum with rainbow reflections. Crown on top, legendary border, ultimate achievement design, celestial glow, maximum prestige, mobile app icon, transparent background, 512x512px
```

---

### Categoría: Consistencia 📅

#### 13. achievement_weekly_perfect.png
```
A circular badge with a calendar showing 7 golden checkmarks. Week visualization, all days marked complete. Blue and gold color scheme, "PERFECT" ribbon, celebratory confetti, achievement style, mobile app icon, transparent background, 512x512px
```

#### 14. achievement_monthly_80.png
```
A circular badge with a calendar page showing "80%" in large numbers. Progress bar nearly full. Purple and gold colors, monthly achievement style, pie chart element showing 80%, professional look, mobile app icon, transparent background, 512x512px
```

#### 15. achievement_early_bird.png
```
A circular badge featuring a cute cartoon bird with a sunrise behind it. Early morning colors: pink, orange, yellow sky. Small alarm clock element. Fresh morning vibes, cheerful design, mobile app achievement icon, transparent background, 512x512px
```

#### 16. achievement_night_owl.png
```
A circular badge featuring a cute cartoon owl with stars and a crescent moon. Night time colors: deep blue, purple, silver stars. Mystical nighttime atmosphere, wise owl design, mobile app achievement icon, transparent background, 512x512px
```

---

### Categoría: Explorador 🧭

#### 17. achievement_first_photo.png
```
A circular badge with a vintage-style camera icon. Polaroid photo coming out with a small heart. Soft purple and pink colors, photography theme, creative achievement, cute camera design, mobile app icon, transparent background, 512x512px
```

#### 18. achievement_first_3d.png
```
A circular badge featuring a 3D cube with glowing edges. Holographic effect, tech-futuristic style. Blue and cyan gradient, floating geometric shapes, innovation theme, modern tech aesthetic, mobile app icon, transparent background, 512x512px
```

#### 19. achievement_ai_habit.png
```
A circular badge with a stylized brain icon with circuit patterns. AI neural network visualization, glowing nodes. Purple and cyan cyberpunk colors, futuristic tech design, artificial intelligence theme, mobile app icon, transparent background, 512x512px
```

#### 20. achievement_five_habits.png
```
A circular badge with a 2x2 grid of different habit icons. Organized layout, variety represented. Rainbow of colors for diversity, organization theme, neat grid design, mobile app achievement icon, transparent background, 512x512px
```

#### 21. achievement_all_categories.png
```
A circular badge featuring a globe with different habit category icons orbiting around it. Explorer compass overlay, adventure theme. World traveler aesthetic, discovery achievement, colorful category representation, mobile app icon, transparent background, 512x512px
```

---

### Categoría: Especiales ⭐

#### 22. achievement_first_day.png
```
A circular badge with a friendly waving hand emoji. "Day 1" text, welcoming design. Warm yellow and orange sunset colors, new beginning theme, friendly and inviting, mobile app achievement icon, transparent background, 512x512px
```

#### 23. achievement_comeback.png
```
A circular badge with a phoenix rising or comeback arrow. "I'm back!" energy, triumphant return theme. Orange and red dramatic colors, circular arrow motif, second chance achievement, mobile app icon, transparent background, 512x512px
```

#### 24. achievement_new_year.png
```
A circular badge with fireworks and "2026" (or generic new year). Party popper, celebration confetti. Festive gold, red and blue colors, New Year celebration theme, party achievement, mobile app icon, transparent background, 512x512px
```

#### 25. achievement_level_5.png
```
A circular badge with an upward arrow and "LVL 5" text. Progress staircase design, leveling up theme. Blue to purple gradient, growth achievement, mid-level milestone, mobile app icon, transparent background, 512x512px
```

#### 26. achievement_level_10.png
```
A legendary circular badge with a golden crown and "MAX" or "LVL 10" text. Ultimate level achieved, royal design. Gold and platinum colors, gemstones, maximum prestige, legendary rarity, mobile app icon, transparent background, 512x512px
```

---

## 🏅 TROFEOS (10 total)

### Tier: Bronce 🥉

#### 1. trophy_bronze_beginner.png
```
A bronze trophy cup with "INICIADO" engraved. Starter trophy design, warm bronze metallic sheen. Simple elegant shape, first achievement trophy, motivational beginner design, 3D realistic style, mobile app icon, transparent background, 512x512px
```

#### 2. trophy_bronze_streak.png
```
A bronze trophy with a small flame emblem on front. "PERSISTENTE" engraved on base. Bronze metallic finish, determination theme, flame accent, 3D realistic trophy, mobile app icon, transparent background, 512x512px
```

---

### Tier: Plata 🥈

#### 3. trophy_silver_dedicated.png
```
A silver trophy cup with refined elegant design. "DEDICADO" engraved, silver metallic shine. More elaborate than bronze, dedication theme, polished silver finish, 3D realistic style, mobile app icon, transparent background, 512x512px
```

#### 4. trophy_silver_streak.png
```
A silver trophy with a calendar/streak emblem. "INQUEBRANTABLE" engraved. Unbreakable determination theme, silver with slight blue tint, 30-day streak symbol, 3D realistic trophy, mobile app icon, transparent background, 512x512px
```

---

### Tier: Oro 🥇

#### 5. trophy_gold_master.png
```
A golden trophy cup with ornate decorations. "MAESTRO" engraved with laurel wreath design. Rich gold metallic finish, mastery achievement, premium elegant design, 3D realistic style, mobile app icon, transparent background, 512x512px
```

#### 6. trophy_gold_streak.png
```
A golden trophy with a flame made of gold. "LEYENDA VIVIENTE" engraved. 100-day achievement, legendary flame design, pure gold finish with gem accents, 3D realistic trophy, mobile app icon, transparent background, 512x512px
```

---

### Tier: Platino 💎

#### 7. trophy_platinum_elite.png
```
A platinum trophy with sleek modern design. "ÉLITE" engraved, platinum white-silver finish. Elite status achievement, crystal accents, premium exclusive design, 3D realistic style, mobile app icon, transparent background, 512x512px
```

#### 8. trophy_platinum_achiever.png
```
A platinum trophy with multiple small medals attached. "COLECCIONISTA" engraved. Achievement collector theme, platinum with rainbow iridescent accents, 3D realistic trophy, mobile app icon, transparent background, 512x512px
```

---

### Tier: Diamante 💠

#### 9. trophy_diamond_legend.png
```
An ultimate diamond-encrusted trophy with a crown on top. "INMORTAL" engraved in diamonds. Celestial glow, floating diamond particles, ultimate prestige, maximum achievement, ethereal design, 3D realistic style, mobile app icon, transparent background, 512x512px
```

#### 10. trophy_diamond_perfect.png
```
The ultimate trophy made entirely of crystal/diamond. "PERFECCIÓN" engraved, 365-day achievement. Perfect clear diamond with rainbow light refraction, star burst behind, cosmic perfection theme, 3D realistic style, mobile app icon, transparent background, 512x512px
```

---

## 📋 Lista de archivos necesarios

### Logros (26 archivos)
1. `achievement_streak_3.png`
2. `achievement_streak_7.png`
3. `achievement_streak_14.png`
4. `achievement_streak_30.png`
5. `achievement_streak_100.png`
6. `achievement_streak_365.png`
7. `achievement_complete_1.png`
8. `achievement_complete_10.png`
9. `achievement_complete_50.png`
10. `achievement_complete_100.png`
11. `achievement_complete_500.png`
12. `achievement_complete_1000.png`
13. `achievement_weekly_perfect.png`
14. `achievement_monthly_80.png`
15. `achievement_early_bird.png`
16. `achievement_night_owl.png`
17. `achievement_first_photo.png`
18. `achievement_first_3d.png`
19. `achievement_ai_habit.png`
20. `achievement_five_habits.png`
21. `achievement_all_categories.png`
22. `achievement_first_day.png`
23. `achievement_comeback.png`
24. `achievement_new_year.png`
25. `achievement_level_5.png`
26. `achievement_level_10.png`

### Trofeos (10 archivos)
1. `trophy_bronze_beginner.png`
2. `trophy_bronze_streak.png`
3. `trophy_silver_dedicated.png`
4. `trophy_silver_streak.png`
5. `trophy_gold_master.png`
6. `trophy_gold_streak.png`
7. `trophy_platinum_elite.png`
8. `trophy_platinum_achiever.png`
9. `trophy_diamond_legend.png`
10. `trophy_diamond_perfect.png`

---

## 🔧 Instrucciones de instalación

1. Genera cada imagen usando los prompts con tu generador de imágenes AI favorito (DALL-E, Midjourney, etc.)
2. Exporta cada imagen como PNG 512x512 con fondo transparente
3. En Xcode, abre `Assets.xcassets`
4. Crea la carpeta `Gamification` si no existe
5. Dentro crea las carpetas `Achievements` y `Trophies`
6. Para cada imagen:
   - Click derecho → New Image Set
   - Nombrar con el nombre exacto del archivo (sin extensión)
   - Arrastrar la imagen al slot @2x
7. El código detectará automáticamente las imágenes y las mostrará

## ⚠️ Notas importantes

- Si una imagen no existe, se mostrará el icono SF Symbol como fallback
- Los iconos bloqueados aparecerán automáticamente atenuados con un candado
- Asegúrate de que los nombres coincidan EXACTAMENTE con los listados
