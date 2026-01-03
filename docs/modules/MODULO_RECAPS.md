# 📊 Módulo de Recaps (Recaps Module)

**Autor:** Jorge  
**Versión:** 1.0.0  
**ID:** `com.habitapp.module.recaps`

---

## Descripción

El módulo de Recaps genera resúmenes visuales del progreso de hábitos en formato "stories" similar a Instagram/Snapchat. Incluye recaps diarios, semanales y mensuales con animaciones y estadísticas.

## Archivos del Módulo

| Archivo | Descripción |
|---------|-------------|
| `HabitApp/Modules/Recaps/RecapsModuleImpl.swift` | Implementación del módulo |
| `HabitApp/Premium/Views/RecapView.swift` | Vista de stories con animaciones |
| `.github/workflows/module-recaps.yml` | GitHub Action específica |

## Protocolo

```swift
protocol RecapsModuleProtocol: ModuleProtocol {
    var availablePeriods: [String] { get }
    
    func generateRecapData(for period: String) -> RecapData
    
    @MainActor func recapView(for period: String) -> AnyView
}

// DTO para datos del recap
struct RecapData {
    let period: String
    let totalHabits: Int
    let completedHabits: Int
    let completionRate: Double
    let bestStreak: Int
    let mostCompletedHabit: String?
}
```

## Pregunta Clave: ¿Cómo se inyecta tu código en la app principal sin aumentar el acoplamiento del núcleo?

### Patrones Utilizados: Protocol + DTO + View Factory

1. **Periodos como Strings Genéricos**
   
   Los tipos de periodo se manejan como strings para evitar exponer el enum interno:
   
   ```swift
   // En el módulo (interno)
   enum RecapPeriod: String {
       case daily, weekly, monthly
   }
   
   // En el protocolo (público)
   var availablePeriods: [String] {
       return ["daily", "weekly", "monthly"]
   }
   ```
   
   El núcleo puede iterar sin conocer el enum:
   ```swift
   ForEach(recapsModule.availablePeriods, id: \.self) { period in
       Button(period) {
           showRecap(for: period)
       }
   }
   ```

2. **Datos Estadísticos Desacoplados**
   
   `RecapData` contiene solo datos primitivos que el núcleo puede usar directamente:
   
   ```swift
   let data = recapsModule.generateRecapData(for: "weekly")
   
   // El núcleo puede mostrar estos datos sin conocer cómo se calculan
   Text("\(data.completedHabits)/\(data.totalHabits) completados")
   Text("Mejor racha: \(data.bestStreak) días")
   ```

3. **Vista como Caja Negra**
   
   El núcleo presenta la vista sin conocer su implementación interna:
   
   ```swift
   // En el módulo
   func recapView(for period: String) -> AnyView {
       let recapPeriod = RecapPeriod(rawValue: period) ?? .daily
       return AnyView(RecapViewWrapper(period: recapPeriod))
   }
   
   // En el núcleo
   .fullScreenCover(isPresented: $showingRecap) {
       recapsModule.recapView(for: selectedPeriod)
   }
   ```

4. **Cálculos Encapsulados**
   
   Toda la lógica de estadísticas está dentro del módulo:
   
   ```swift
   private func calculateBestStreak() -> Int {
       // Lógica interna, no expuesta
   }
   
   private var dateRange: DateInterval {
       // Cálculo interno del rango de fechas
   }
   ```

### Beneficios

- ✅ Las animaciones de stories están completamente encapsuladas
- ✅ Se pueden añadir nuevos periodos (yearly, custom) sin modificar el núcleo
- ✅ Los cálculos estadísticos son internos al módulo
- ✅ El diseño visual puede cambiar sin afectar al núcleo
- ✅ El núcleo solo maneja datos primitivos

## GitHub Action

```yaml
name: 📊 Recaps Module CI

on:
  push:
    paths:
      - 'HabitApp/Modules/Recaps/**'
      - 'HabitApp/Premium/Views/RecapView.swift'

jobs:
  lint:
    # SwiftLint en archivos del módulo
  build:
    # Compilación del proyecto
  test:
    # Tests específicos del módulo
  ui-check:
    # Verificación de SwiftUI Previews
  docs:
    # Verificación de documentación
```

## Uso desde el Núcleo

```swift
// En SettingsView - Sección de Recaps
struct SettingsView: View {
    @State private var showingRecap = false
    @State private var selectedPeriod = "daily"
    
    var body: some View {
        Section("Resúmenes") {
            if let recaps = ModuleRegistry.shared.recapsModule {
                ForEach(recaps.availablePeriods, id: \.self) { period in
                    Button {
                        selectedPeriod = period
                        showingRecap = true
                    } label: {
                        HStack {
                            Image(systemName: iconFor(period))
                            Text(titleFor(period))
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingRecap) {
            ModuleRegistry.shared.recapsModule?.recapView(for: selectedPeriod)
        }
    }
}

// Uso de datos del recap
func showRecapSummary() {
    guard let recaps = ModuleRegistry.shared.recapsModule else { return }
    
    let data = recaps.generateRecapData(for: "weekly")
    
    print("Esta semana:")
    print("- Completados: \(data.completedHabits)/\(data.totalHabits)")
    print("- Porcentaje: \(Int(data.completionRate * 100))%")
    print("- Mejor racha: \(data.bestStreak) días")
    if let top = data.mostCompletedHabit {
        print("- Más completado: \(top)")
    }
}
```

## Diagrama de Arquitectura

```
┌─────────────────────────────────────────┐
│           Núcleo de la App              │
│  ┌─────────────────────────────────┐    │
│  │   SettingsView                  │    │
│  │   - Lista periodos disponibles  │    │
│  │   - Muestra recap como sheet    │    │
│  │   - No conoce RecapView         │    │
│  └───────────────┬─────────────────┘    │
└──────────────────┼──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│         RecapsModuleProtocol            │
│  - availablePeriods: [String]           │
│  - generateRecapData(for:) -> RecapData │
│  - recapView(for:) -> AnyView           │
└───────────────────┬─────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│          RecapsModuleImpl               │
│  ┌─────────────────────────────────┐    │
│  │  enum RecapPeriod               │    │
│  │  RecapView (stories UI)         │    │
│  │  Animaciones TabView            │    │
│  │  Cálculos de estadísticas       │    │
│  │  Gradientes y efectos visuales  │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## Páginas del Recap

El RecapView incluye 4 páginas tipo story:

1. **Welcome Story**: Saludo con el periodo
2. **Stats Story**: Estadísticas principales
3. **Highlights Story**: Hábito destacado y logros
4. **Summary Story**: Resumen final con motivación

Cada página tiene:
- Barra de progreso animada (5 segundos por página)
- Navegación por tap (izquierda/derecha)
- Gradiente de fondo que cambia por página
- Animaciones de entrada/salida

Todo esto está encapsulado en el módulo.
