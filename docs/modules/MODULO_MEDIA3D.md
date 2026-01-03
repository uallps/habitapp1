# 🎮 Módulo de Modelado 3D e Imágenes (Media 3D Module)

**Autor:** Lucas  
**Versión:** 1.0.0  
**ID:** `com.habitapp.module.media3d`

---

## Descripción

El módulo de Modelado 3D permite a los usuarios capturar objetos en 3D usando fotogrametría y LiDAR, así como guardar imágenes al completar un hábito. Utiliza RealityKit y ARKit para la captura avanzada.

## Archivos del Módulo

| Archivo | Descripción |
|---------|-------------|
| `HabitApp/Modules/Media3D/Media3DModuleImpl.swift` | Implementación del módulo |
| `HabitApp/Premium/Views/ObjectCaptureContainerView.swift` | Vista de captura 3D |
| `HabitApp/Views/Model3DViewer.swift` | Visor de modelos 3D |
| `.github/workflows/module-media3d.yml` | GitHub Action específica |

## Protocolo

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

## Pregunta Clave: ¿Cómo se inyecta tu código en la app principal sin aumentar el acoplamiento del núcleo?

### Patrones Utilizados: Protocol + Type Erasure + Factory

1. **Type Erasure con AnyView**
   
   Las vistas se devuelven como `AnyView` para ocultar la implementación concreta:
   
   ```swift
   // En el módulo
   func captureView() -> AnyView {
       return AnyView(ObjectCaptureContainerViewWrapper(module: self))
   }
   
   // En el núcleo - no conoce ObjectCaptureContainerView
   NavigationLink {
       media3DModule.captureView()
   } label: {
       Text("Capturar 3D")
   }
   ```

2. **Detección de Capacidades Encapsulada**
   
   La lógica de detección de hardware está dentro del módulo:
   
   ```swift
   var hasLiDAR: Bool {
       #if os(iOS)
       return ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
       #else
       return false
       #endif
   }
   ```
   
   El núcleo solo pregunta:
   ```swift
   if media3DModule.supports3DCapture {
       // Mostrar opción de captura
   }
   ```

3. **Comunicación por URLs**
   
   Los modelos 3D se comunican mediante URLs, no objetos internos:
   
   ```swift
   func startCapture(completion: @escaping (Result<URL, Error>) -> Void) {
       // El resultado es solo una URL
       completion(.success(modelURL))
   }
   ```

4. **Compilación Condicional Encapsulada**
   
   Los `#if os(iOS)` y `#if !targetEnvironment(simulator)` están dentro del módulo:
   
   ```swift
   var supportsPhotogrammetry: Bool {
       if #available(iOS 17.0, *) {
           #if !targetEnvironment(simulator)
           return PhotogrammetrySession.isSupported
           #else
           return false
           #endif
       }
       return false
   }
   ```

### Beneficios

- ✅ RealityKit y ARKit solo se importan en el módulo
- ✅ Dispositivos sin LiDAR reciben graceful degradation
- ✅ El núcleo no conoce `ObjectCaptureContainerView`
- ✅ Los modelos 3D se manejan como archivos (URLs)
- ✅ Funciona en macOS con fallback apropiado

## GitHub Action

```yaml
name: 🎮 Media 3D Module CI

on:
  push:
    paths:
      - 'HabitApp/Modules/Media3D/**'
      - 'HabitApp/Premium/Views/ObjectCaptureContainerView.swift'

jobs:
  lint:
    # SwiftLint en archivos del módulo
  build:
    # Compilación del proyecto
  test:
    # Tests específicos del módulo
  arkit-check:
    # Verificación de APIs de ARKit
  docs:
    # Verificación de documentación
```

## Uso desde el Núcleo

```swift
// En HabitCompletionSheet
struct HabitCompletionSheet: View {
    @State private var showing3DCapture = false
    
    var body: some View {
        VStack {
            // Verificar si la captura 3D está disponible
            if let media3D = ModuleRegistry.shared.media3DModule,
               media3D.supports3DCapture {
                Button("Capturar objeto 3D") {
                    showing3DCapture = true
                }
            }
        }
        .sheet(isPresented: $showing3DCapture) {
            // Vista proporcionada por el módulo
            ModuleRegistry.shared.media3DModule?.captureView()
        }
    }
}

// Para visualizar un modelo guardado
struct ModelViewer: View {
    let modelURL: URL
    
    var body: some View {
        ModuleRegistry.shared.media3DModule?.viewerView(for: modelURL)
    }
}
```

## Diagrama de Arquitectura

```
┌─────────────────────────────────────────┐
│           Núcleo de la App              │
│  ┌─────────────────────────────────┐    │
│  │   HabitCompletionSheet          │    │
│  │   - No conoce ARKit             │    │
│  │   - No conoce RealityKit        │    │
│  │   - Solo usa protocolos         │    │
│  └───────────────┬─────────────────┘    │
└──────────────────┼──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│         Media3DModuleProtocol           │
│  - supports3DCapture: Bool              │
│  - hasLiDAR: Bool                       │
│  - captureView() -> AnyView             │
│  - viewerView(for:) -> AnyView          │
└───────────────────┬─────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│          Media3DModuleImpl              │
│  ┌─────────────────────────────────┐    │
│  │  import RealityKit              │    │
│  │  import ARKit                   │    │
│  │                                 │    │
│  │  ObjectCaptureContainerView     │    │
│  │  Model3DViewer                  │    │
│  │  PhotogrammetrySession          │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## Niveles de Calidad de Captura

El módulo detecta automáticamente las capacidades del dispositivo:

| Nivel | Requisitos | Fotos | Intervalo |
|-------|------------|-------|-----------|
| Premium | LiDAR + Depth | 30 | 0.2s |
| Enhanced | Solo LiDAR | 35 | 0.3s |
| Basic | Cámara estándar | 45 | 0.5s |

Esta lógica está completamente encapsulada en el módulo.
