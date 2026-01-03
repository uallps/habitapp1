# 📺 Módulo de Anuncios (Ads Module)

**Autor:** Avilés  
**Versión:** 1.0.0  
**ID:** `com.habitapp.module.ads`

---

## Descripción

El módulo de Anuncios gestiona la visualización de anuncios intersticiales de Google AdMob en la versión gratuita de HabitApp. Los anuncios se desactivan automáticamente para usuarios Premium.

## Archivos del Módulo

| Archivo | Descripción |
|---------|-------------|
| `HabitApp/Modules/Ads/AdsModuleImpl.swift` | Implementación del módulo |
| `HabitApp/Modules/Core/ModuleProtocols.swift` | Protocolo `AdsModuleProtocol` |
| `.github/workflows/module-ads.yml` | GitHub Action específica |

## Protocolo

```swift
protocol AdsModuleProtocol: ModuleProtocol {
    var isAdMobConfigured: Bool { get }
    var isAdLoaded: Bool { get }
    var shouldShowAds: Bool { get }
    
    func loadInterstitialAd()
    func showInterstitialAd(from rootViewController: Any?, completion: (() -> Void)?)
}
```

## Pregunta Clave: ¿Cómo se inyecta tu código en la app principal sin aumentar el acoplamiento del núcleo?

### Patrón Utilizado: Protocol + Dependency Injection

1. **Abstracción mediante Protocolo**
   
   El núcleo de la app solo conoce el protocolo `AdsModuleProtocol`, nunca la implementación `AdsModuleImpl`:
   
   ```swift
   // ❌ MAL - Acoplamiento directo
   let ads = AdManager.shared
   ads.showAd()
   
   // ✅ BIEN - Desacoplado via protocolo
   if let ads = ModuleRegistry.shared.adsModule {
       ads.showInterstitialAd(from: vc, completion: nil)
   }
   ```

2. **Registro en el Contenedor DI**
   
   El módulo se registra al iniciar la app sin que el núcleo conozca la implementación:
   
   ```swift
   // En ModuleBootstrapper.bootstrap()
   let adsModule = AdsModuleImpl()
   ModuleRegistry.shared.registerAdsModule(adsModule)
   ```

3. **Encapsulación de Dependencias Externas**
   
   La dependencia de `GoogleMobileAds` está completamente encapsulada:
   
   ```swift
   #if os(iOS)
   import GoogleMobileAds  // Solo en el módulo
   #endif
   ```

4. **Verificación de Disponibilidad**
   
   ```swift
   if ModuleRegistry.shared.hasAdsModule {
       // El módulo está disponible
   }
   ```

### Beneficios

- ✅ El núcleo no importa `GoogleMobileAds`
- ✅ Se puede reemplazar por otra red de anuncios (Facebook Ads, Unity Ads)
- ✅ En tests, se puede inyectar un mock
- ✅ La lógica de Premium/Free está encapsulada

## GitHub Action

```yaml
name: 📺 Ads Module CI

on:
  push:
    paths:
      - 'HabitApp/Modules/Ads/**'
      - 'HabitApp/Ads/**'

jobs:
  lint:
    # SwiftLint en archivos del módulo
  build:
    # Compilación del proyecto
  test:
    # Tests específicos del módulo
  docs:
    # Verificación de documentación
```

## Uso desde el Núcleo

```swift
// En ContentView o donde se necesite mostrar un anuncio
struct HabitCompletionSheet: View {
    var body: some View {
        Button("Completar") {
            completeHabit()
            
            // Mostrar anuncio si corresponde
            if let ads = ModuleRegistry.shared.adsModule,
               ads.shouldShowAds {
                ads.showInterstitialAd(from: getRootVC()) {
                    dismiss()
                }
            } else {
                dismiss()
            }
        }
    }
}
```

## Diagrama de Inyección

```
┌──────────────────┐
│   ContentView    │
│   (Núcleo)       │
└────────┬─────────┘
         │ Solicita módulo
         ▼
┌──────────────────┐
│  ModuleRegistry  │ ◄── Contenedor DI
└────────┬─────────┘
         │ Retorna protocolo
         ▼
┌──────────────────┐
│ AdsModuleProtocol│ ◄── Abstracción
└────────┬─────────┘
         │ Implementa
         ▼
┌──────────────────┐
│  AdsModuleImpl   │ ◄── Implementación
│  (GoogleAdMob)   │     concreta
└──────────────────┘
```
