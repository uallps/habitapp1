# HabitApp - Estructura de Targets

## Targets Disponibles

### 1. HabitApp (Target Free)
- **Bundle Identifier:** `ual.HabitApp`
- **Características:** Versión gratuita con límites
- **Compilation Condition:** Sin flags especiales
- **Incluye anuncios:** Sí (GoogleMobileAds)

### 2. HabitAppPremium (Target Premium)
- **Bundle Identifier:** `ual.HabitAppPremium`
- **Características:** Todas las funcionalidades desbloqueadas
- **Compilation Condition:** `PREMIUM`
- **Incluye anuncios:** No

## Estructura de Carpetas

```
HabitApp/
├── Config/           # Configuración de la app
├── Data/             # Stores y persistencia
├── Models/           # Modelos de datos
├── Views/            # Vistas compartidas (base)
├── Utils/            # Utilidades
├── Ads/              # Sistema de anuncios (solo Free)
├── Premium/          # Funcionalidades Premium
│   ├── Views/        # Vistas premium
│   │   ├── CameraHabitView.swift
│   │   ├── HabitSuggestionSheet.swift
│   │   ├── ObjectCaptureContainerView.swift
│   │   └── RecapView.swift
│   ├── Services/     # Servicios premium
│   │   └── OpenAIService.swift
│   └── PremiumFeatures.swift  # Manager de features
└── Services/         # Servicios compartidos
```

## Cómo Funciona

### En el Target Free (HabitApp):
- Las funcionalidades premium se habilitan vía `AppConfig.isPremiumUser`
- El usuario puede cambiar de plan en Settings → Planes
- Se muestra publicidad

### En el Target Premium (HabitAppPremium):
- El flag `PREMIUM` está definido en Build Settings
- Todas las funcionalidades premium están habilitadas siempre
- No hay opción de cambiar de plan (siempre premium)
- No hay publicidad

## Compilation Conditions

Para verificar el target en código:

```swift
#if PREMIUM
// Código solo para HabitAppPremium
#else
// Código solo para HabitApp (Free)
#endif
```

## Uso de PremiumFeatures

```swift
// Verificar si es target Premium
PremiumFeatures.isCompiled

// Verificar si premium está habilitado (target o runtime)
PremiumFeatures.isEnabled

// Verificar feature específica
PremiumFeatures.hasCameraAI
PremiumFeatures.hasRecaps
PremiumFeatures.canAddNotes
```

## Build Settings Relevantes

### HabitApp (Free)
```
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG $(inherited)
PRODUCT_BUNDLE_IDENTIFIER = ual.HabitApp
```

### HabitAppPremium
```
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG PREMIUM $(inherited)
PRODUCT_BUNDLE_IDENTIFIER = ual.HabitAppPremium
```
