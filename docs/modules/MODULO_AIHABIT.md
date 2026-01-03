# 🤖 Módulo de Generación de Hábitos con IA (AI Habit Module)

**Autor:** Diego  
**Versión:** 1.0.0  
**ID:** `com.habitapp.module.aihabit`

---

## Descripción

El módulo de IA para Hábitos utiliza OpenAI GPT-4 Vision para analizar imágenes y sugerir hábitos relacionados con los objetos detectados. Por ejemplo, una foto de una guitarra sugiere "Practicar guitarra 15 minutos diarios".

## Archivos del Módulo

| Archivo | Descripción |
|---------|-------------|
| `HabitApp/Modules/AIHabit/AIHabitModuleImpl.swift` | Implementación del módulo |
| `HabitApp/Premium/Views/CameraHabitView.swift` | Vista de cámara para captura |
| `HabitApp/Premium/Views/HabitSuggestionSheet.swift` | Sheet con sugerencia de hábito |
| `HabitApp/Premium/Services/OpenAIService.swift` | Servicio de comunicación con OpenAI |
| `.github/workflows/module-aihabit.yml` | GitHub Action específica |

## Protocolo

```swift
protocol AIHabitModuleProtocol: ModuleProtocol {
    var isConfigured: Bool { get }
    var isProcessing: Bool { get }
    
    func analyzeImage(_ imageData: Data, 
                      completion: @escaping (Result<HabitSuggestionData, Error>) -> Void)
    
    @MainActor func cameraView() -> AnyView
}

// DTO - Data Transfer Object
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

## Pregunta Clave: ¿Cómo se inyecta tu código en la app principal sin aumentar el acoplamiento del núcleo?

### Patrones Utilizados: Protocol + DTO + Async Callbacks

1. **Data Transfer Object (DTO)**
   
   Los datos de sugerencia se transfieren mediante una estructura simple sin dependencias:
   
   ```swift
   // El módulo convierte su modelo interno a DTO
   let suggestionData = HabitSuggestionData(
       name: suggestion.name,
       description: suggestion.description,
       category: suggestion.category.rawValue,  // String, no enum interno
       iconName: suggestion.iconName,
       frequency: suggestion.frequency,
       confidence: suggestion.confidence,
       detectedObject: suggestion.detectedObject
   )
   ```
   
   El núcleo recibe datos planos:
   ```swift
   aiModule.analyzeImage(imageData) { result in
       switch result {
       case .success(let suggestion):
           // suggestion es HabitSuggestionData, no HabitSuggestion interno
           let habit = Habit(
               name: suggestion.name,
               icon: suggestion.iconName,
               frequency: suggestion.frequency
           )
       case .failure(let error):
           // Manejar error
       }
   }
   ```

2. **Encapsulación de API Keys**
   
   Las credenciales de OpenAI nunca salen del módulo:
   
   ```swift
   // En OpenAIService (interno)
   private func loadAPIKey() -> String? {
       // Lee de Secrets.plist
   }
   
   // En el protocolo (público)
   var isConfigured: Bool { get }  // Solo expone si está configurado
   ```

3. **Callbacks Asíncronos Genéricos**
   
   La comunicación con OpenAI es asíncrona pero el callback usa tipos genéricos:
   
   ```swift
   // El núcleo no conoce URLSession ni los modelos de OpenAI
   func analyzeImage(_ imageData: Data, 
                     completion: @escaping (Result<HabitSuggestionData, Error>) -> Void)
   ```

4. **Vista como Caja Negra**
   
   ```swift
   func cameraView() -> AnyView {
       return AnyView(CameraHabitViewWrapper())
   }
   ```

### Beneficios

- ✅ Las credenciales de API nunca salen del módulo
- ✅ Se puede cambiar de OpenAI a otro proveedor (Claude, Gemini)
- ✅ El análisis de imagen es asíncrono y no bloquea el núcleo
- ✅ Los tipos internos (`HabitSuggestion`, `OpenAIResponse`) están ocultos
- ✅ Los tests pueden usar mocks sin llamar a la API real

## GitHub Action

```yaml
name: 🤖 AI Habit Module CI

on:
  push:
    paths:
      - 'HabitApp/Modules/AIHabit/**'
      - 'HabitApp/Premium/Views/CameraHabitView.swift'
      - 'HabitApp/Premium/Services/OpenAIService.swift'

jobs:
  lint:
    # SwiftLint en archivos del módulo
  security:
    # Verificación de API key leaks
    # Verificar que no hay keys hardcodeadas
  build:
    # Compilación del proyecto
  test:
    # Tests específicos del módulo
  docs:
    # Verificación de documentación
```

## Uso desde el Núcleo

```swift
// En ContentView - Tab de cámara IA
struct ContentView: View {
    var body: some View {
        TabView {
            // ... otras tabs
            
            // Tab de IA solo si el módulo está disponible
            if ModuleRegistry.shared.hasAIHabitModule {
                ModuleRegistry.shared.aiHabitModule?.cameraView()
                    .tabItem {
                        Image(systemName: "camera.fill")
                        Text("AI Camera")
                    }
            }
        }
    }
}

// Uso programático
func analyzePhoto(_ image: UIImage) {
    guard let imageData = image.jpegData(compressionQuality: 0.8),
          let aiModule = ModuleRegistry.shared.aiHabitModule else { return }
    
    aiModule.analyzeImage(imageData) { result in
        switch result {
        case .success(let suggestion):
            // Crear hábito desde la sugerencia
            createHabit(from: suggestion)
        case .failure(let error):
            showError(error)
        }
    }
}
```

## Diagrama de Flujo

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Usuario    │     │    Núcleo    │     │  AI Module   │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       │ Toma foto          │                    │
       ├───────────────────>│                    │
       │                    │                    │
       │                    │ analyzeImage(data) │
       │                    ├───────────────────>│
       │                    │                    │
       │                    │                    │ ┌─────────────┐
       │                    │                    │ │ OpenAI API  │
       │                    │                    │ │ (GPT-4V)    │
       │                    │                    │ └──────┬──────┘
       │                    │                    │        │
       │                    │                    │<───────┘
       │                    │                    │
       │                    │ HabitSuggestionData│
       │                    │<───────────────────┤
       │                    │                    │
       │ Muestra sugerencia │                    │
       │<───────────────────┤                    │
       │                    │                    │
       │ Acepta hábito      │                    │
       ├───────────────────>│                    │
       │                    │                    │
       │                    │ Crea Habit (núcleo)│
       │                    ├────────────────────┤
       │                    │                    │
```

## Seguridad

El módulo incluye verificaciones de seguridad en su GitHub Action:

```yaml
security:
  steps:
    - name: 🔐 Check for API Key Leaks
      run: |
        if grep -r "sk-" HabitApp/Modules/AIHabit/ | grep -v "Secrets.plist"; then
          echo "⚠️ Possible API key leak detected!"
          exit 1
        fi
```

### Configuración de API Key

```xml
<!-- HabitApp/Config/Secrets.plist (NO en git) -->
<dict>
    <key>OPENAI_API_KEY</key>
    <string>sk-...</string>
</dict>
```

```xml
<!-- HabitApp/Config/Secrets.plist.example (en git) -->
<dict>
    <key>OPENAI_API_KEY</key>
    <string>YOUR_API_KEY_HERE</string>
</dict>
```
