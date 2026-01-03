# 🏗️ Arquitectura Modular de HabitApp

## Índice

1. [Visión General](#visión-general)
2. [Patrones de Diseño Utilizados](#patrones-de-diseño-utilizados)
3. [Módulos Implementados](#módulos-implementados)
   - [Módulo de Anuncios (Avilés)](#1-módulo-de-anuncios-avilés)
   - [Módulo de Modelado 3D (Lucas)](#2-módulo-de-modelado-3d-lucas)
   - [Módulo de IA para Hábitos (Diego)](#3-módulo-de-ia-para-hábitos-diego)
   - [Módulo de Recaps (Jorge)](#4-módulo-de-recaps-jorge)
   - [Módulo de Multilengüaje (Nieto)](#5-módulo-de-multilengüaje-nieto)
   - [Módulo de Apariencia (Avilés)](#6-módulo-de-apariencia-avilés)
   - [Módulo de Gamificación (Lucas)](#7-módulo-de-gamificación-lucas)
4. [Sistema de Inyección de Dependencias](#sistema-de-inyección-de-dependencias)
5. [GitHub Actions por Módulo](#github-actions-por-módulo)

---

## Visión General

HabitApp implementa una **arquitectura modular** basada en el **Plugin Pattern** que permite añadir funcionalidades sin modificar el núcleo de la aplicación. Cada módulo:

- ✅ Es **independiente** y **autocontenido**
- ✅ Se comunica con el núcleo mediante **protocolos**
- ✅ Se registra mediante **inyección de dependencias**
- ✅ Tiene su propia **GitHub Action** para CI/CD
- ✅ Puede ser **habilitado/deshabilitado** sin afectar otros módulos

### Estructura de Directorios

```
HabitApp/
├── Modules/
│   ├── Core/
│   │   ├── ModuleProtocols.swift    # Protocolos base
│   │   └── ModuleRegistry.swift     # Contenedor DI
│   ├── Ads/
│   │   └── AdsModuleImpl.swift      # Módulo Anuncios
│   ├── Media3D/
│   │   └── Media3DModuleImpl.swift  # Módulo 3D
│   ├── AIHabit/
│   │   └── AIHabitModuleImpl.swift  # Módulo IA
│   ├── Recaps/
│   │   └── RecapsModuleImpl.swift   # Módulo Recaps
│   ├── Language/
│   │   └── LanguageModuleImpl.swift # Módulo Idioma
│   ├── Appearance/
│   │   └── AppearanceModuleImpl.swift # Módulo Apariencia
│   └── Gamification/
│       └── GamificationModuleImpl.swift # Módulo Gamificación
├── Premium/
│   └── Gamification/
│       ├── Models/
│       │   └── GamificationModels.swift  # Modelos: XP, Niveles, Logros, Trofeos
│       ├── Store/
│       │   └── GamificationStore.swift   # Store: Lógica de gamificación
│       └── Views/
│           ├── GamificationHubView.swift    # Hub principal
│           ├── AchievementsTabView.swift    # Vista de logros
│           ├── TrophyRoomView.swift         # Sala de trofeos
│           ├── DailyRewardsView.swift       # Recompensas diarias
│           └── GamificationIconView.swift   # Iconos de logros/trofeos
```

---

## Patrones de Diseño Utilizados

### 1. Protocol-Oriented Programming (POP)

Cada módulo implementa un **protocolo** que define su contrato con el núcleo:

```swift
protocol ModuleProtocol: AnyObject {
    static var moduleId: String { get }
    static var moduleName: String { get }
    static var moduleAuthor: String { get }
    var isEnabled: Bool { get }
    func initialize()
    func cleanup()
}
```

### 2. Dependency Injection Container

El `ModuleRegistry` actúa como **contenedor de inyección de dependencias**:

```swift
@MainActor
final class ModuleRegistry: ObservableObject {
    static let shared = ModuleRegistry()
    
    func register<T: ModuleProtocol>(_ module: T)
    func getModule<T: ModuleProtocol>(_ type: T.Type) -> T?
}
```

### 3. Factory Pattern

Cada módulo tiene una **factory** para su creación:

```swift
struct AdsModuleFactory: ModuleFactoryProtocol {
    typealias ModuleType = AdsModuleImpl
    static func create() -> AdsModuleImpl
}
```

### 4. Service Locator Pattern

El registro permite localizar servicios sin acoplamiento directo:

```swift
// En lugar de:
let adsManager = AdManager.shared  // ❌ Acoplamiento directo

// Usamos:
let adsModule = ModuleRegistry.shared.adsModule  // ✅ Desacoplado
```

---

## Módulos Implementados

---

## 1. Módulo de Anuncios (Avilés)

### 📋 Información del Módulo

| Propiedad | Valor |
|-----------|-------|
| **ID** | `com.habitapp.module.ads` |
| **Autor** | Avilés |
| **Versión** | 1.0.0 |
| **Archivo** | `HabitApp/Modules/Ads/AdsModuleImpl.swift` |
| **GitHub Action** | `.github/workflows/module-ads.yml` |

### 🎯 Responsabilidad

Gestiona la visualización de anuncios intersticiales de Google AdMob en la versión gratuita de la app.

### 🔌 Protocolo

```swift
protocol AdsModuleProtocol: ModuleProtocol {
    var isAdMobConfigured: Bool { get }
    var isAdLoaded: Bool { get }
    var shouldShowAds: Bool { get }
    
    func loadInterstitialAd()
    func showInterstitialAd(from rootViewController: Any?, completion: (() -> Void)?)
}
```

### ❓ ¿Cómo se inyecta sin aumentar el acoplamiento?

1. **Definición del protocolo**: El núcleo solo conoce `AdsModuleProtocol`, no la implementación concreta.

2. **Registro en el bootstrap**:
   ```swift
   // En ModuleBootstrapper.bootstrap()
   let adsModule = AdsModuleImpl()
   ModuleRegistry.shared.registerAdsModule(adsModule)
   ```

3. **Uso desacoplado**:
   ```swift
   // En cualquier vista
   if let ads = ModuleRegistry.shared.adsModule {
       if ads.shouldShowAds {
           ads.showInterstitialAd(from: viewController) {
               // Continuar después del anuncio
           }
       }
   }
   ```

4. **Beneficios**:
   - El núcleo no importa `GoogleMobileAds`
   - Se puede reemplazar por otra red de anuncios sin modificar el núcleo
   - En tests, se puede inyectar un mock

---

## 2. Módulo de Modelado 3D (Lucas)

### 📋 Información del Módulo

| Propiedad | Valor |
|-----------|-------|
| **ID** | `com.habitapp.module.media3d` |
| **Autor** | Lucas |
| **Versión** | 1.0.0 |
| **Archivo** | `HabitApp/Modules/Media3D/Media3DModuleImpl.swift` |
| **GitHub Action** | `.github/workflows/module-media3d.yml` |

### 🎯 Responsabilidad

Permite capturar objetos en 3D usando fotogrametría y LiDAR, y guardar imágenes al completar hábitos.

### 🔌 Protocolo

```swift
protocol Media3DModuleProtocol: ModuleProtocol {
    var supports3DCapture: Bool { get }
    var hasLiDAR: Bool { get }
    
    func startCapture(completion: @escaping (Result<URL, Error>) -> Void)
    func cancelCapture()
    
    @MainActor func captureView() -> AnyView
    @MainActor func viewerView(for modelURL: URL) -> AnyView
}
```

### ❓ ¿Cómo se inyecta sin aumentar el acoplamiento?

1. **Type Erasure con AnyView**: Las vistas se devuelven como `AnyView` para ocultar tipos concretos:
   ```swift
   func captureView() -> AnyView {
       return AnyView(ObjectCaptureContainerViewWrapper(module: self))
   }
   ```

2. **Detección de capacidades desacoplada**:
   ```swift
   // El núcleo pregunta si el feature está disponible
   if ModuleRegistry.shared.media3DModule?.supports3DCapture == true {
       // Mostrar opción de captura 3D
   }
   ```

3. **Compilación condicional encapsulada**: Los `#if os(iOS)` están dentro del módulo, no en el núcleo.

4. **Beneficios**:
   - RealityKit y ARKit solo se importan en el módulo
   - Dispositivos sin LiDAR reciben graceful degradation
   - El modelo 3D se comunica solo mediante URLs

---

## 3. Módulo de IA para Hábitos (Diego)

### 📋 Información del Módulo

| Propiedad | Valor |
|-----------|-------|
| **ID** | `com.habitapp.module.aihabit` |
| **Autor** | Diego |
| **Versión** | 1.0.0 |
| **Archivo** | `HabitApp/Modules/AIHabit/AIHabitModuleImpl.swift` |
| **GitHub Action** | `.github/workflows/module-aihabit.yml` |

### 🎯 Responsabilidad

Analiza imágenes con OpenAI GPT-4 Vision para sugerir hábitos basados en objetos detectados.

### 🔌 Protocolo

```swift
protocol AIHabitModuleProtocol: ModuleProtocol {
    var isConfigured: Bool { get }
    var isProcessing: Bool { get }
    
    func analyzeImage(_ imageData: Data, completion: @escaping (Result<HabitSuggestionData, Error>) -> Void)
    
    @MainActor func cameraView() -> AnyView
}

// Estructura desacoplada para datos
struct HabitSuggestionData {
    let name: String
    let description: String
    let category: String
    let iconName: String
    let frequency: [String]
    let confidence: Double
    let detectedObject: String
}
```

### ❓ ¿Cómo se inyecta sin aumentar el acoplamiento?

1. **Data Transfer Object (DTO)**: `HabitSuggestionData` es una estructura simple sin dependencias del módulo:
   ```swift
   // El núcleo recibe datos planos, no objetos del módulo
   let suggestionData = HabitSuggestionData(
       name: suggestion.name,
       description: suggestion.description,
       // ...
   )
   ```

2. **API Key segura**: La configuración de OpenAI está encapsulada:
   ```swift
   var isConfigured: Bool {
       return openAIService.hasAPIKey
   }
   ```

3. **Callbacks genéricos**:
   ```swift
   // El núcleo no conoce los tipos internos de OpenAI
   aiModule.analyzeImage(imageData) { result in
       switch result {
       case .success(let suggestion):
           // Crear hábito desde datos genéricos
       case .failure(let error):
           // Manejar error
       }
   }
   ```

4. **Beneficios**:
   - Las credenciales de API nunca salen del módulo
   - Se puede cambiar de OpenAI a otro proveedor
   - El análisis de imagen es asíncrono y no bloquea el núcleo

---

## 4. Módulo de Recaps (Jorge)

### 📋 Información del Módulo

| Propiedad | Valor |
|-----------|-------|
| **ID** | `com.habitapp.module.recaps` |
| **Autor** | Jorge |
| **Versión** | 1.0.0 |
| **Archivo** | `HabitApp/Modules/Recaps/RecapsModuleImpl.swift` |
| **GitHub Action** | `.github/workflows/module-recaps.yml` |

### 🎯 Responsabilidad

Genera resúmenes visuales del progreso de hábitos en formato "stories" (diario, semanal, mensual).

### 🔌 Protocolo

```swift
protocol RecapsModuleProtocol: ModuleProtocol {
    var availablePeriods: [String] { get }
    
    func generateRecapData(for period: String) -> RecapData
    
    @MainActor func recapView(for period: String) -> AnyView
}

struct RecapData {
    let period: String
    let totalHabits: Int
    let completedHabits: Int
    let completionRate: Double
    let bestStreak: Int
    let mostCompletedHabit: String?
}
```

### ❓ ¿Cómo se inyecta sin aumentar el acoplamiento?

1. **Periodos como strings**: Los periodos se manejan como strings genéricos:
   ```swift
   // En lugar de un enum interno
   var availablePeriods: [String] { 
       return ["daily", "weekly", "monthly"] 
   }
   ```

2. **Datos estadísticos desacoplados**: `RecapData` contiene solo datos primitivos:
   ```swift
   // El núcleo puede mostrar estos datos sin conocer cómo se calculan
   let data = recapsModule.generateRecapData(for: "weekly")
   print("Completados: \(data.completedHabits)/\(data.totalHabits)")
   ```

3. **Vista como caja negra**:
   ```swift
   // El núcleo solo presenta la vista, no conoce su implementación
   NavigationLink {
       recapsModule.recapView(for: "weekly")
   } label: {
       Text("Ver resumen semanal")
   }
   ```

4. **Beneficios**:
   - Las animaciones y diseño de stories están encapsulados
   - Se pueden añadir nuevos periodos sin modificar el núcleo
   - Los cálculos estadísticos son internos al módulo

---

## 5. Módulo de Multilengüaje (Nieto)

### 📋 Información del Módulo

| Propiedad | Valor |
|-----------|-------|
| **ID** | `com.habitapp.module.language` |
| **Autor** | Nieto |
| **Versión** | 1.0.0 |
| **Archivo** | `HabitApp/Modules/Language/LanguageModuleImpl.swift` |
| **GitHub Action** | `.github/workflows/module-language.yml` |

### 🎯 Responsabilidad

Gestiona la internacionalización de la app con soporte para español e inglés.

### 🔌 Protocolo

```swift
protocol LanguageModuleProtocol: ModuleProtocol {
    var currentLanguage: String { get set }
    var currentLocale: Locale { get }
    var supportedLanguages: [String] { get }
    
    func localized(_ key: String) -> String
    func setLanguage(_ language: String)
    
    var languagePublisher: AnyPublisher<String, Never> { get }
}
```

### ❓ ¿Cómo se inyecta sin aumentar el acoplamiento?

1. **Claves de traducción como strings**: Las vistas usan claves genéricas:
   ```swift
   // La vista no conoce el diccionario de traducciones
   Text(languageModule.localized("habits"))
   ```

2. **Publisher para reactividad**: Los cambios de idioma se propagan via Combine:
   ```swift
   languageModule.languagePublisher
       .sink { newLanguage in
           // Actualizar UI
       }
       .store(in: &cancellables)
   ```

3. **Locale desacoplado**:
   ```swift
   .environment(\.locale, languageModule.currentLocale)
   ```

4. **Traducciones autocontenidas**: El diccionario está dentro del módulo, no en recursos externos.

5. **Beneficios**:
   - Se pueden añadir idiomas sin modificar el núcleo
   - Las traducciones se pueden cargar de archivos externos
   - El formato de fechas/números sigue el locale automáticamente

---

## 6. Módulo de Apariencia (Avilés)

### 📋 Información del Módulo

| Propiedad | Valor |
|-----------|-------|
| **ID** | `com.habitapp.module.appearance` |
| **Autor** | Avilés |
| **Versión** | 1.0.0 |
| **Archivo** | `HabitApp/Modules/Appearance/AppearanceModuleImpl.swift` |
| **GitHub Action** | `.github/workflows/module-appearance.yml` |

### 🎯 Responsabilidad

Gestiona el modo de apariencia (claro, oscuro, automático) de la aplicación.

### 🔌 Protocolo

```swift
protocol AppearanceModuleProtocol: ModuleProtocol {
    var currentMode: AppearanceModeType { get set }
    var colorScheme: ColorScheme? { get }
    var availableModes: [AppearanceModeType] { get }
    
    func setMode(_ mode: AppearanceModeType)
    
    var appearancePublisher: AnyPublisher<AppearanceModeType, Never> { get }
}

enum AppearanceModeType: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
}
```

### ❓ ¿Cómo se inyecta sin aumentar el acoplamiento?

1. **Enum genérico**: `AppearanceModeType` está definido en los protocolos, no en el módulo
2. **ViewModifier desacoplado**: Modificador que aplica el tema
3. **Colores centralizados**: Los colores se obtienen mediante funciones helper
4. **Beneficios**:
   - Los colores están centralizados en `Color+SystemBackground.swift`
   - Se puede añadir modo "sepia" u otros sin modificar vistas
   - La persistencia en UserDefaults es interna al módulo

---

## 7. Módulo de Gamificación (Lucas)

### 📋 Información del Módulo

| Propiedad | Valor |
|-----------|-------|
| **ID** | `com.habitapp.module.gamification` |
| **Autor** | Lucas |
| **Versión** | 1.0.0 |
| **Archivo** | `HabitApp/Modules/Gamification/GamificationModuleImpl.swift` |
| **GitHub Action** | `.github/workflows/module-gamification.yml` |

### 🎯 Responsabilidad

Sistema completo de gamificación que incluye:
- **Sistema de XP y Niveles**: 10 niveles desde Novato hasta Inmortal
- **Logros (Achievements)**: 26 logros en 6 categorías (Rachas, Completados, Consistencia, Explorador, Social, Especiales)
- **Trofeos**: 10 trofeos en 5 tiers (Bronce, Plata, Oro, Platino, Diamante)
- **Recompensas Diarias**: Sistema de login consecutivo con multiplicadores
- **Historial de XP**: Registro de todos los eventos de puntos

### 🔌 Protocolo

```swift
protocol GamificationModuleProtocol: ModuleProtocol {
    // Estado del usuario
    var totalXP: Int { get }
    var currentLevel: Int { get }
    var levelName: String { get }
    var xpToNextLevel: Int { get }
    var xpProgress: Double { get }
    
    // Estadísticas
    var totalAchievementsUnlocked: Int { get }
    var totalTrophiesUnlocked: Int { get }
    var loginStreak: Int { get }
    
    // Datos de logros y trofeos
    var achievements: [Achievement] { get }
    var trophies: [Trophy] { get }
    var unlockedAchievements: [Achievement] { get }
    var unlockedTrophies: [Trophy] { get }
    
    // Recompensas diarias
    var dailyRewards: [DailyReward] { get }
    var canClaimDailyReward: Bool { get }
    
    // Acciones
    func recordHabitCompletion(streak: Int, category: String)
    func recordPhotoAdded()
    func recordModel3DCreated()
    func recordAIHabitCreated()
    func claimDailyReward() -> Int
    
    // Vistas
    @MainActor func gamificationHubView() -> AnyView
    @MainActor func achievementsView() -> AnyView
    @MainActor func trophyRoomView() -> AnyView
    @MainActor func dailyRewardsView() -> AnyView
    
    // Datos para otras vistas
    func getProfileData() -> GamificationProfileData
}
```

### 📊 Sistema de XP y Niveles

| Nivel | Nombre | XP Mínimo | XP Máximo |
|-------|--------|-----------|-----------|
| 1 | Novato | 0 | 100 |
| 2 | Aprendiz | 100 | 300 |
| 3 | Dedicado | 300 | 600 |
| 4 | Constante | 600 | 1,000 |
| 5 | Experto | 1,000 | 1,500 |
| 6 | Maestro | 1,500 | 2,200 |
| 7 | Leyenda | 2,200 | 3,000 |
| 8 | Héroe | 3,000 | 4,000 |
| 9 | Campeón | 4,000 | 5,500 |
| 10 | Inmortal | 5,500 | ∞ |

### 🏆 Categorías de Logros

| Categoría | Icono | Ejemplos |
|-----------|-------|----------|
| Rachas | 🔥 | 3, 7, 14, 30, 100, 365 días |
| Completados | ✅ | 1, 10, 50, 100, 500, 1000 hábitos |
| Consistencia | 📅 | Semana perfecta, 80% mensual |
| Explorador | 🧭 | Primera foto, primer 3D, IA |
| Social | 👥 | Compartir, comunidad |
| Especiales | ⭐ | Primer día, comeback, Año Nuevo |

### 🏅 Tiers de Trofeos

| Tier | Color | XP Bonus |
|------|-------|----------|
| Bronce | 🥉 | +50 XP |
| Plata | 🥈 | +100 XP |
| Oro | 🥇 | +200 XP |
| Platino | 💎 | +400 XP |
| Diamante | 💠 | +1000 XP |

### ❓ ¿Cómo se integra con el núcleo?

1. **Llamada directa al Store**: El `HabitStore` llama directamente a `GamificationStore.shared`:
   ```swift
   // En HabitStore.toggleHabitCompletion()
   GamificationStore.shared.habitCompleted(streak: streak, category: habit.iconName)
   ```

2. **Singleton compartido**: `GamificationStore.shared` mantiene el estado global

3. **Persistencia en UserDefaults**: Todos los datos se guardan automáticamente

4. **Vistas desacopladas con AnyView**:
   ```swift
   func gamificationHubView() -> AnyView {
       AnyView(GamificationHubView())
   }
   ```

5. **Beneficios**:
   - El sistema funciona para todos los usuarios (no solo Premium)
   - Los logros se desbloquean automáticamente al cumplir requisitos
   - Las recompensas diarias incluyen multiplicadores por racha
   - Debug logging extenso para troubleshooting
| **GitHub Action** | `.github/workflows/module-appearance.yml` |

### 🎯 Responsabilidad

Gestiona el modo de apariencia (claro, oscuro, automático) de la aplicación.

### 🔌 Protocolo

```swift
protocol AppearanceModuleProtocol: ModuleProtocol {
    var currentMode: AppearanceModeType { get set }
    var colorScheme: ColorScheme? { get }
    var availableModes: [AppearanceModeType] { get }
    
    func setMode(_ mode: AppearanceModeType)
    
    var appearancePublisher: AnyPublisher<AppearanceModeType, Never> { get }
}

enum AppearanceModeType: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
}
```

### ❓ ¿Cómo se inyecta sin aumentar el acoplamiento?

1. **Enum genérico**: `AppearanceModeType` está definido en los protocolos, no en el módulo:
   ```swift
   // Cualquier módulo puede usar estos modos
   appearanceModule.setMode(.dark)
   ```

2. **ViewModifier desacoplado**:
   ```swift
   // Modificador que aplica el tema
   struct AppearanceModifier: ViewModifier {
       @ObservedObject var module: AppearanceModuleImpl
       
       func body(content: Content) -> some View {
           content.preferredColorScheme(module.colorScheme)
       }
   }
   
   // Uso
   ContentView()
       .withAppearance(appearanceModule)
   ```

3. **Colores centralizados**: Los colores se obtienen mediante funciones helper:
   ```swift
   Color.appBackground(for: colorScheme)  // Retorna color apropiado
   ```

4. **Beneficios**:
   - Los colores están centralizados en `Color+SystemBackground.swift`
   - Se puede añadir modo "sepia" u otros sin modificar vistas
   - La persistencia en UserDefaults es interna al módulo

---

## Sistema de Inyección de Dependencias

### Bootstrap de Módulos

Al iniciar la app, se registran todos los módulos:

```swift
// En HabitAppApp.swift
@main
struct HabitAppApp: App {
    init() {
        ModuleBootstrapper.bootstrap()
    }
}

// En ModuleRegistry.swift
struct ModuleBootstrapper {
    @MainActor
    static func bootstrap() {
        let registry = ModuleRegistry.shared
        
        // Registrar módulos
        registry.registerAdsModule(AdsModuleImpl())
        registry.registerMedia3DModule(Media3DModuleImpl())
        registry.registerAIHabitModule(AIHabitModuleImpl())
        registry.registerRecapsModule(RecapsModuleImpl())
        registry.registerLanguageModule(LanguageModuleImpl())
        registry.registerAppearanceModule(AppearanceModuleImpl())
    }
}
```

### Acceso a Módulos

```swift
// Verificar disponibilidad
if ModuleRegistry.shared.hasAdsModule {
    // Módulo disponible
}

// Acceso tipado
if let adsModule = ModuleRegistry.shared.adsModule {
    adsModule.loadInterstitialAd()
}

// Acceso genérico
if let module = ModuleRegistry.shared.getModule(byId: "com.habitapp.module.ads") {
    module.initialize()
}
```

---

## GitHub Actions por Módulo

| Módulo | Workflow | Trigger |
|--------|----------|---------|
| Ads | `module-ads.yml` | Cambios en `HabitApp/Modules/Ads/**` |
| Media 3D | `module-media3d.yml` | Cambios en `HabitApp/Modules/Media3D/**` |
| AI Habit | `module-aihabit.yml` | Cambios en `HabitApp/Modules/AIHabit/**` |
| Recaps | `module-recaps.yml` | Cambios en `HabitApp/Modules/Recaps/**` |
| Language | `module-language.yml` | Cambios en `HabitApp/Modules/Language/**` |
| Appearance | `module-appearance.yml` | Cambios en `HabitApp/Modules/Appearance/**` |
| Gamification | `module-gamification.yml` | Cambios en `HabitApp/Modules/Gamification/**` y `HabitApp/Premium/Gamification/**` |

Cada workflow incluye:
- ✅ **Lint**: Análisis estático con SwiftLint
- ✅ **Build**: Compilación del proyecto
- ✅ **Test**: Ejecución de tests unitarios
- ✅ **Validaciones específicas**: Seguridad, accesibilidad, etc.
- ✅ **Documentación**: Verificación de docs

---

## Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                      HabitApp (Núcleo)                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ ContentView │  │ HabitStore  │  │  AppConfig  │          │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘          │
│         │                │                │                  │
│         └────────────────┼────────────────┘                  │
│                          │                                   │
│              ┌───────────▼───────────┐                       │
│              │    ModuleRegistry     │ ◄── Dependency        │
│              │   (Service Locator)   │     Injection         │
│              └───────────┬───────────┘     Container         │
│                          │                                   │
└──────────────────────────┼───────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
│ AdsModuleProtocol│ │Media3DProto- │ │ AIHabitProtocol  │
│        ▲         │ │    col ▲     │ │        ▲         │
└────────┼─────────┘ └───────┼──────┘ └────────┼─────────┘
         │                   │                 │
┌────────┴─────────┐ ┌───────┴──────┐ ┌────────┴─────────┐
│  AdsModuleImpl   │ │ Media3DImpl  │ │ AIHabitModuleImpl│
│   (Avilés)       │ │   (Lucas)    │ │    (Diego)       │
└──────────────────┘ └──────────────┘ └──────────────────┘

┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
│RecapsModuleProto-│ │LanguageProto-│ │AppearanceProtocol│
│    col ▲         │ │    col ▲     │ │        ▲         │
└────────┼─────────┘ └───────┼──────┘ └────────┼─────────┘
         │                   │                 │
┌────────┴─────────┐ ┌───────┴──────┐ ┌────────┴─────────┐
│ RecapsModuleImpl │ │ LanguageImpl │ │AppearanceModuleIm│
│    (Jorge)       │ │   (Nieto)    │ │    (Avilés)      │
└──────────────────┘ └──────────────┘ └──────────────────┘

┌──────────────────────────────────────────────────────────┐
│                GamificationModuleProtocol                 │
│                          ▲                                │
└──────────────────────────┼────────────────────────────────┘
                           │
┌──────────────────────────┴────────────────────────────────┐
│              GamificationModuleImpl (Lucas)               │
│  ┌─────────────────┐  ┌─────────────┐  ┌────────────────┐ │
│  │ GamificationStore│ │ Achievements│  │    Trophies    │ │
│  │   (Singleton)    │ │  (26 total) │  │   (10 total)   │ │
│  └─────────────────┘  └─────────────┘  └────────────────┘ │
│  ┌─────────────────┐  ┌─────────────┐  ┌────────────────┐ │
│  │ XP & Levels     │  │Daily Rewards│  │  XP History    │ │
│  │  (10 levels)    │  │ (7-day cycle)│ │   (Events)     │ │
│  └─────────────────┘  └─────────────┘  └────────────────┘ │
└───────────────────────────────────────────────────────────┘
```

---

## Conclusión

La arquitectura modular de HabitApp permite:

1. **Desarrollo independiente**: Cada alumno puede trabajar en su módulo sin conflictos
2. **Testing aislado**: Los módulos se pueden probar de forma unitaria
3. **Despliegue gradual**: Se pueden habilitar/deshabilitar features por configuración
4. **Mantenibilidad**: Los cambios en un módulo no afectan a otros
5. **Extensibilidad**: Añadir nuevos módulos solo requiere implementar el protocolo

La clave del desacoplamiento está en:
- **Protocolos** como contratos
- **Inyección de dependencias** para registrar implementaciones
- **DTOs** para transferir datos sin exponer tipos internos
- **Type erasure** (`AnyView`) para ocultar implementaciones de vistas