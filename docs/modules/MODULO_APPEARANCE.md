# 🎨 Módulo de Apariencia (Appearance Module)

**Autor:** Avilés  
**Versión:** 1.0.0  
**ID:** `com.habitapp.module.appearance`

---

## Descripción

El módulo de Apariencia gestiona el modo visual de la aplicación (claro, oscuro, automático). Incluye colores personalizados para cada modo y persistencia de la preferencia del usuario.

## Archivos del Módulo

| Archivo | Descripción |
|---------|-------------|
| `HabitApp/Modules/Appearance/AppearanceModuleImpl.swift` | Implementación del módulo |
| `HabitApp/Utils/Color+SystemBackground.swift` | Extensiones de colores |
| `HabitApp/Config/AppConfig.swift` | Configuración de apariencia (referencia) |
| `.github/workflows/module-appearance.yml` | GitHub Action específica |

## Protocolo

```swift
protocol AppearanceModuleProtocol: ModuleProtocol {
    var currentMode: AppearanceModeType { get set }
    var colorScheme: ColorScheme? { get }
    var availableModes: [AppearanceModeType] { get }
    
    func setMode(_ mode: AppearanceModeType)
    
    var appearancePublisher: AnyPublisher<AppearanceModeType, Never> { get }
}

// Enum definido en ModuleProtocols.swift (público)
enum AppearanceModeType: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
}
```

## Pregunta Clave: ¿Cómo se inyecta tu código en la app principal sin aumentar el acoplamiento del núcleo?

### Patrones Utilizados: Protocol + ViewModifier + Publisher

1. **Enum Genérico en Protocolos**
   
   `AppearanceModeType` está definido en `ModuleProtocols.swift`, no en el módulo:
   
   ```swift
   // En ModuleProtocols.swift (compartido)
   enum AppearanceModeType: String, CaseIterable {
       case light, dark, auto
   }
   
   // Cualquier parte del código puede usarlo
   appearanceModule.setMode(.dark)
   ```

2. **ViewModifier Desacoplado**
   
   El módulo proporciona un modificador que las vistas pueden usar:
   
   ```swift
   // En el módulo
   struct AppearanceModifier: ViewModifier {
       @ObservedObject var module: AppearanceModuleImpl
       
       func body(content: Content) -> some View {
           content.preferredColorScheme(module.colorScheme)
       }
   }
   
   extension View {
       func withAppearance(_ module: AppearanceModuleImpl) -> some View {
           self.modifier(AppearanceModifier(module: module))
       }
   }
   ```
   
   Uso en el núcleo:
   ```swift
   ContentView()
       .preferredColorScheme(appearanceModule.colorScheme)
   ```

3. **Colores Centralizados**
   
   Los colores están en una extensión compartida:
   
   ```swift
   // En Color+SystemBackground.swift
   extension Color {
       static func appBackground(for colorScheme: ColorScheme) -> Color {
           if colorScheme == .dark {
               return Color(red: 0.11, green: 0.11, blue: 0.12)
           } else {
               return Color(red: 0.95, green: 0.95, blue: 0.97)
           }
       }
   }
   ```
   
   Las vistas usan estos colores sin conocer la lógica:
   ```swift
   ZStack {
       Color.appBackground(for: colorScheme)
           .ignoresSafeArea()
       // contenido
   }
   ```

4. **Reactive Updates con Combine**
   
   ```swift
   appearanceModule.appearancePublisher
       .sink { newMode in
           // Reaccionar a cambios de apariencia
       }
       .store(in: &cancellables)
   ```

### Beneficios

- ✅ Los colores están centralizados en `Color+SystemBackground.swift`
- ✅ Se puede añadir modo "sepia" u otros sin modificar vistas
- ✅ La persistencia en UserDefaults es interna al módulo
- ✅ El cambio de modo es inmediato sin reiniciar
- ✅ Compatible con la preferencia del sistema (modo auto)

## GitHub Action

```yaml
name: 🎨 Appearance Module CI

on:
  push:
    paths:
      - 'HabitApp/Modules/Appearance/**'
      - 'HabitApp/Utils/Color+SystemBackground.swift'
      - 'HabitApp/Config/AppConfig.swift'

jobs:
  lint:
    # SwiftLint en archivos del módulo
  accessibility:
    # Verificación de contraste de colores
  build:
    # Compilación del proyecto
  test:
    # Tests específicos del módulo
  theme-preview:
    # Verificación de modos disponibles
  docs:
    # Verificación de documentación
```

## Uso desde el Núcleo

```swift
// En HabitAppApp - Aplicar el esquema de color
@main
struct HabitAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(
                    ModuleRegistry.shared.appearanceModule?.colorScheme
                )
        }
    }
}

// En SettingsView - Selector de modo
struct AppearanceSelector: View {
    var body: some View {
        if let appearance = ModuleRegistry.shared.appearanceModule {
            Picker("Modo", selection: Binding(
                get: { appearance.currentMode },
                set: { appearance.setMode($0) }
            )) {
                ForEach(appearance.availableModes, id: \.self) { mode in
                    Text(modeName(mode)).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    func modeName(_ mode: AppearanceModeType) -> String {
        switch mode {
        case .light: return "☀️ Claro"
        case .dark: return "🌙 Oscuro"
        case .auto: return "🔄 Auto"
        }
    }
}

// En cualquier vista - Usar colores del tema
struct HabitCardView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            // ...
        }
        .background(Color.appCardBackground(for: colorScheme))
    }
}
```

## Diagrama de Arquitectura

```
┌─────────────────────────────────────────┐
│           Núcleo de la App              │
│  ┌─────────────────────────────────┐    │
│  │   Vistas                        │    │
│  │   - preferredColorScheme(...)   │    │
│  │   - Color.appBackground(for:)   │    │
│  └───────────────┬─────────────────┘    │
└──────────────────┼──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│       AppearanceModuleProtocol          │
│  - currentMode: AppearanceModeType      │
│  - colorScheme: ColorScheme?            │
│  - setMode(_ mode)                      │
│  - appearancePublisher                  │
└───────────────────┬─────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│        AppearanceModuleImpl             │
│  ┌─────────────────────────────────┐    │
│  │  Persistencia UserDefaults      │    │
│  │  Conversión a ColorScheme       │    │
│  │  Publisher para cambios         │    │
│  │  ViewModifier helper            │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│      Color+SystemBackground.swift       │
│  - appBackground(for:)                  │
│  - appCardBackground(for:)              │
│  - appTertiaryBackground(for:)          │
└─────────────────────────────────────────┘
```

## Colores Definidos

### Modo Claro

| Uso | Color | Hex |
|-----|-------|-----|
| Fondo principal | Gris claro | `#F2F2F7` |
| Fondo de tarjeta | Blanco | `#FFFFFF` |
| Fondo terciario | Gris claro | `#F2F2F7` |

### Modo Oscuro

| Uso | Color | Hex |
|-----|-------|-----|
| Fondo principal | Gris oscuro | `#1C1C1E` |
| Fondo de tarjeta | Gris medio | `#2C2C2E` |
| Fondo terciario | Gris claro | `#3A3A3C` |

## Añadir un Nuevo Modo

Para añadir un nuevo modo (ej: "sepia"), solo se modifica el módulo:

```swift
// 1. Añadir al enum en ModuleProtocols.swift
enum AppearanceModeType: String, CaseIterable {
    case light, dark, auto, sepia  // Añadir sepia
}

// 2. Manejar en AppearanceModuleImpl
var colorScheme: ColorScheme? {
    switch currentMode {
    case .light: return .light
    case .dark: return .dark
    case .sepia: return .light  // Base clara para sepia
    case .auto: return nil
    }
}

// 3. Añadir colores sepia en Color+SystemBackground.swift
static func appBackground(for colorScheme: ColorScheme, mode: AppearanceModeType? = nil) -> Color {
    if mode == .sepia {
        return Color(red: 0.96, green: 0.94, blue: 0.89)  // Tono sepia
    }
    // ... resto de la lógica
}
```

El núcleo de la app no necesita ningún cambio significativo.

## Accesibilidad

La GitHub Action incluye verificación de contraste:

```yaml
accessibility:
  steps:
    - name: ♿ Check Color Contrast
      run: |
        # Verificar que hay colores para ambos modos
        grep -A2 "colorScheme == .light" HabitApp/Utils/Color+SystemBackground.swift
        grep -A2 "colorScheme == .dark" HabitApp/Utils/Color+SystemBackground.swift
```

Esto asegura que todos los modos tienen colores definidos con buen contraste.
