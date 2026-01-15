# 🎮 Módulo de Modelado 3D e Imágenes (Media 3D Module)

**Autor:** Lucas  
**Versión:** 1.0.0  
**ID:** `com.habitapp.module.media3d`

---

## Descripción

El módulo de Modelado 3D permite a los usuarios capturar objetos en 3D usando fotogrametría y LiDAR, así como tomar y guardar imágenes al completar un hábito. Además soporta notas ampliadas asociadas a la finalización de un hábito. Al completar un hábito, el usuario puede escribir una nota y elegir tomar una imagen o capturar un modelo 3D (no ambos). Utiliza RealityKit y ARKit para la captura avanzada, pero la captura de imágenes está implementada dentro del mismo módulo para mantener la cohesión funcional.

## Archivos del Módulo

| Archivo | Descripción |
|---------|-------------|
| `HabitApp/Modules/Media3D/Media3DModuleImpl.swift` | Implementación del módulo |
| `HabitApp/Premium/Views/ObjectCaptureContainerView.swift` | Vista de captura 3D |
| `HabitApp/Premium/Views/ImageCaptureContainerView.swift` | Vista de captura de imágenes |
| `HabitApp/Views/Model3DViewer.swift` | Visor de modelos 3D |
| `HabitApp/Views/ImageViewer.swift` | Visor de imágenes guardadas |
| `.github/workflows/module-media3d.yml` | GitHub Action específica |

## Protocolo

```swift
protocol Media3DModuleProtocol: ModuleProtocol {
    // 3D capabilities
    var supports3DCapture: Bool { get }
    var hasLiDAR: Bool { get }

    // Image capabilities
    var supportsImageCapture: Bool { get }

    // Capture actions - return a URL to the stored resource (image or 3D model)
    func startCapture(completion: @escaping (Result<URL, Error>) -> Void)
    func startImageCapture(completion: @escaping (Result<URL, Error>) -> Void)
    func cancelCapture()

    // Views (type-erased) for integration in the core app
    @MainActor func captureView() -> AnyView
    @MainActor func viewerView(for modelURL: URL) -> AnyView
    @MainActor func viewerView(forImageURL imageURL: URL) -> AnyView

    // Optional: attach a note to a saved resource (module may persist relation or return combined result)
    func attachNote(_ note: String, toResourceAt url: URL)
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
    @State private var showingCapture = false
    @State private var selectedCaptureType: CaptureType = .none
    @State private var noteText: String = ""

    enum CaptureType { case none, image, model }

    var body: some View {
        VStack(spacing: 12) {
            TextEditor(text: $noteText)
                .frame(height: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary))

            HStack {
                if let media = ModuleRegistry.shared.media3DModule, media.supportsImageCapture {
                    Button("Tomar imagen") {
                        selectedCaptureType = .image
                        showingCapture = true
                    }
                }

                if let media = ModuleRegistry.shared.media3DModule, media.supports3DCapture {
                    Button("Capturar 3D") {
                        selectedCaptureType = .model
                        showingCapture = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingCapture) {
            guard let media = ModuleRegistry.shared.media3DModule else { return AnyView(EmptyView()) }

            switch selectedCaptureType {
            case .image:
                AnyView(media.captureView())
            case .model:
                AnyView(media.captureView())
            case .none:
                AnyView(EmptyView())
            }
        }
        .onDisappear {
            // Ejemplo de post-procesado: cuando la vista de captura devuelve una URL,
            // el flujo de guardado debe asociarla con la nota `noteText`.
            // El módulo puede ofrecer `attachNote(_:toResourceAt:)` para persistir la relación.
        }
    }
}

// Para visualizar un recurso guardado (imagen o modelo)
struct ModelViewer: View {
    let resourceURL: URL
    let isImage: Bool

    var body: some View {
        if isImage {
            ModuleRegistry.shared.media3DModule?.viewerView(forImageURL: resourceURL)
        } else {
            ModuleRegistry.shared.media3DModule?.viewerView(for: resourceURL)
        }
    }
}
```

## Diagrama de Arquitectura

```
┌──────────────────────────────────────────────────────────────────┐
│                         Núcleo de la App                         │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ HabitCompletionSheet                                       │  │
│  │ - Editor de nota (nota ampliada)                           │  │
│  │ - Botones: "Tomar imagen" / "Capturar 3D" (elige uno)      │  │
│  │ - Muestra vistas proporcionadas por el módulo (AnyView)    │  │
│  └───────────────┬────────────────────────────────────────────┘  │
└──────────────────┼───────────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│                  Media3DModuleProtocol (API)                     │
│ - supports3DCapture: Bool                                        │
│ - hasLiDAR: Bool                                                 │
│ - supportsImageCapture: Bool                                     │
│ - startCapture(...) / startImageCapture(...) -> URL              │
│ - captureView() -> AnyView                                       │
│ - viewerView(for:) -> AnyView                                    │
│ - viewerView(forImageURL:) -> AnyView                            │
│ - attachNote(_:toResourceAt:)                                    │
└─────────────────────────────┬────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                      Media3DModuleImpl (concreto)                │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ - import RealityKit / ARKit (solo aquí)                    │  │
│  │ - ObjectCaptureContainerView (3D capture flow)             │  │
│  │ - ImageCaptureContainerView (camera / photo flow)          │  │
│  │ - Model3DViewer                                            │  │
│  │ - ImageViewer                                              │  │
│  │ - PhotogrammetrySession / LiDAR helpers                    │  │
│  │ - Persistence: guarda recurso -> URL + opcional note link  │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘

Flujo (resumido):
- `HabitCompletionSheet` solicita la vista de captura (imagen o 3D) al módulo vía `ModuleRegistry`.
- El módulo presenta su propia UI (`AnyView`). Al finalizar, devuelve una `URL` al recurso guardado.
- La nota ampliada se asocia con la `URL` (por el módulo mediante `attachNote` o por el núcleo almacenando la relación).
```

## Niveles de Calidad de Captura

El módulo detecta automáticamente las capacidades del dispositivo:

| Nivel | Requisitos | Fotos | Intervalo |
|-------|------------|-------|-----------|
| Premium | LiDAR + Depth | 30 | 0.2s |
| Enhanced | Solo LiDAR | 35 | 0.3s |
| Basic | Cámara estándar | 45 | 0.5s |

Esta lógica está completamente encapsulada en el módulo.

## Para la presentación

- **Resumen del flujo:** `HabitCompletionSheet` muestra un editor de nota (nota ampliada) y permite elegir `Tomar imagen` o `Capturar 3D`. Pide la vista de captura al módulo (`captureView()` / `startImageCapture()`), el módulo guarda el recurso (devuelve `URL`) y la nota se asocia mediante `attachNote(_:toResourceAt:)` o por el `HabitStore`.

- **Patrones de diseño utilizados:**
    - **Protocol-oriented design:** el módulo expone `Media3DModuleProtocol` para desacoplar implementación y núcleo.
    - **Type erasure:** vistas retornadas como `AnyView` para ocultar detalles de implementación.
    - **Registry / Factory:** `ModuleRegistry` actúa como fábrica/registro central para inyectar módulos al arranque.
    - **Dependency injection (light):** el núcleo consulta `ModuleRegistry` en lugar de depender de implementaciones concretas.
    - **Encapsulación y degradado elegante:** detección de capacidades (LiDAR, Photogrammetry) y compilación condicional quedan dentro del módulo.

- **Tecnologías / APIs clave:**
    - `RealityKit`, `ARKit` (captura 3D, LiDAR, `ARWorldTrackingConfiguration`)
    - `PhotogrammetrySession` (iOS 17+; fotogrametría cuando esté disponible)
    - `SwiftUI` (`AnyView`, `TextEditor`, `.sheet`) para las UIs integradas
    - `PhotosUI` / `AVFoundation` (flujo de captura de imagen — integración con cámara/galería)
    - `FileManager` / sistema de ficheros (persistencia local de modelos e imágenes, comunicación por `URL`)
    - `UserDefaults` / `HabitStore` (persistencia ligera de metadatos y asociación nota→recurso)
    - `#if` condicionales y `@MainActor` para aislar APIs y seguridad de hilos

- **Plataformas y permisos:**
    - Soporte principal en iOS; macOS con fallback cuando proceda.
    - Requiere permisos de Cámara y Biblioteca de Fotos; ARKit/WorldTracking solo en dispositivos compatibles.

- **Beneficios para la arquitectura:**
    - Mantiene el núcleo libre de dependencias AR/RealityKit.
    - Módulo autocontenido facilita pruebas y despliegue progresivo (feature flags / premium).
    - Comunicación por `URL` simplifica boundaries y serialización.

- **Slides sugeridas:**
    - Diagrama: `HabitCompletionSheet` → `ModuleRegistry` → `Media3DModuleImpl` (captureView) → devuelve `URL` → `HabitStore`.
    - Lista rápida: Patrones (Protocol, AnyView, Registry), Tecnologías (ARKit, RealityKit, Photogrammetry, SwiftUI), Requisitos (LiDAR, iOS 17+, permisos).

## Desacoplamiento e inyección de dependencias

- **Separación clara de responsabilidades:** el núcleo (views, `HabitStore`, `HabitCompletionSheet`) no importa ni referencia `ARKit`/`RealityKit`. Todo código específico de captura y procesamiento 3D/imagen vive en `Media3DModuleImpl`.
- **API a través de protocolos:** `Media3DModuleProtocol` define la interfaz pública (capacidades, acciones y vistas). El núcleo opera sobre el protocolo, no sobre la implementación concreta.
- **Registro / inyección ligera:** `ModuleRegistry` actúa como un registro central que expone `media3DModule`. Esto permite sustituir la implementación por mocks/stubs en tests o por una implementación premium en runtime.
- **Type erasure para UI:** las vistas del módulo se devuelven como `AnyView`, ocultando dependencias de SwiftUI/RealityKit y evitando que el núcleo conozca tipos concretos.
- **Comunicación por fronteras sencillas:** los recursos (imágenes y modelos) se pasan como `URL`, evitando pasar objetos complejos entre capas y facilitando serialización y persistencia.
- **Encapsulación de platform APIs y condiciones de compilación:** detección de capacidades (`hasLiDAR`, `supportsPhotogrammetry`) y `#if` se mantienen dentro del módulo para que el núcleo no gestione variantes por plataforma.
- **Seguridad de hilos y UI:** métodos y vistas expuestos con `@MainActor` garantizan llamadas en el hilo principal; el módulo es responsable de migrar trabajo pesado a hilos de fondo.
- **Testabilidad:** para tests se puede asignar un `MockMedia3DModule` a `ModuleRegistry.shared.media3DModule` o inyectar la dependencia durante el bootstrap, permitiendo validar flujos sin AR/Camera.
- **Feature gating y despliegue progresivo:** el módulo puede exponer flags (`supports3DCapture`, `supportsImageCapture`) y habilitar/deshabilitar opciones desde configuración o producto (premium).


