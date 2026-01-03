# 🌐 Módulo de Multilengüaje (Language Module)

**Autor:** Nieto  
**Versión:** 1.0.0  
**ID:** `com.habitapp.module.language`

---

## Descripción

El módulo de Multilengüaje gestiona la internacionalización de HabitApp con soporte para español e inglés. Permite cambiar el idioma en tiempo de ejecución y persiste la preferencia del usuario.

## Archivos del Módulo

| Archivo | Descripción |
|---------|-------------|
| `HabitApp/Modules/Language/LanguageModuleImpl.swift` | Implementación del módulo |
| `HabitApp/Data/LanguageManager.swift` | Manager original (referencia) |
| `.github/workflows/module-language.yml` | GitHub Action específica |

## Protocolo

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

## Pregunta Clave: ¿Cómo se inyecta tu código en la app principal sin aumentar el acoplamiento del núcleo?

### Patrones Utilizados: Protocol + Publisher + String Keys

1. **Claves de Traducción como Strings**
   
   Las vistas usan claves genéricas sin conocer el diccionario de traducciones:
   
   ```swift
   // En cualquier vista del núcleo
   Text(languageModule.localized("habits"))
   Text(languageModule.localized("settings"))
   
   // El módulo resuelve internamente
   func localized(_ key: String) -> String {
       return translations[currentLanguage]?[key] 
           ?? translations["es"]?[key] 
           ?? key
   }
   ```

2. **Reactive Updates con Combine**
   
   Los cambios de idioma se propagan via Publisher:
   
   ```swift
   // En el módulo
   private let languageSubject = PassthroughSubject<String, Never>()
   var languagePublisher: AnyPublisher<String, Never> {
       languageSubject.eraseToAnyPublisher()
   }
   
   // En el núcleo
   languageModule.languagePublisher
       .sink { newLanguage in
           // Actualizar UI automáticamente
       }
       .store(in: &cancellables)
   ```

3. **Locale Desacoplado**
   
   El módulo proporciona un `Locale` que se puede inyectar en el environment:
   
   ```swift
   // En HabitAppApp
   ContentView()
       .environment(\.locale, languageModule.currentLocale)
   ```

4. **Diccionario Autocontenido**
   
   Las traducciones están dentro del módulo, no en recursos externos:
   
   ```swift
   private let translations: [String: [String: String]] = [
       "es": [
           "habits": "Hábitos",
           "settings": "Ajustes",
           // ...
       ],
       "en": [
           "habits": "Habits",
           "settings": "Settings",
           // ...
       ]
   ]
   ```

### Beneficios

- ✅ Se pueden añadir idiomas sin modificar el núcleo
- ✅ Las traducciones pueden cargarse de archivos externos
- ✅ El formato de fechas/números sigue el locale automáticamente
- ✅ Cambio de idioma en tiempo real sin reiniciar
- ✅ Persistencia automática en UserDefaults

## GitHub Action

```yaml
name: 🌐 Language Module CI

on:
  push:
    paths:
      - 'HabitApp/Modules/Language/**'
      - 'HabitApp/Data/LanguageManager.swift'

jobs:
  lint:
    # SwiftLint en archivos del módulo
  translations:
    # Validación de claves de traducción
    # Verificar que ES y EN tienen las mismas claves
  build:
    # Compilación del proyecto
  test:
    # Tests específicos (LanguageTests)
  docs:
    # Verificación de documentación
```

## Uso desde el Núcleo

```swift
// En cualquier vista
struct HabitCardView: View {
    var body: some View {
        VStack {
            if let lang = ModuleRegistry.shared.languageModule {
                Text(lang.localized("streak"))
                Text(lang.localized("days"))
            }
        }
    }
}

// En SettingsView - Selector de idioma
struct LanguageSelector: View {
    var body: some View {
        if let lang = ModuleRegistry.shared.languageModule {
            Picker(lang.localized("language"), selection: Binding(
                get: { lang.currentLanguage },
                set: { lang.setLanguage($0) }
            )) {
                ForEach(lang.supportedLanguages, id: \.self) { code in
                    Text(languageName(for: code)).tag(code)
                }
            }
        }
    }
}

// En HabitAppApp - Inyección de locale
@main
struct HabitAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, 
                    ModuleRegistry.shared.languageModule?.currentLocale ?? .current)
        }
    }
}
```

## Diagrama de Arquitectura

```
┌─────────────────────────────────────────┐
│           Núcleo de la App              │
│  ┌─────────────────────────────────┐    │
│  │   Vistas                        │    │
│  │   - Text(lang.localized("key")) │    │
│  │   - No conocen las traducciones │    │
│  └───────────────┬─────────────────┘    │
└──────────────────┼──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│        LanguageModuleProtocol           │
│  - localized(_ key: String) -> String   │
│  - currentLanguage: String              │
│  - setLanguage(_ language: String)      │
│  - languagePublisher                    │
└───────────────────┬─────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│         LanguageModuleImpl              │
│  ┌─────────────────────────────────┐    │
│  │  Diccionario de traducciones    │    │
│  │  ["es": [...], "en": [...]]     │    │
│  │                                 │    │
│  │  Persistencia UserDefaults      │    │
│  │  Detección idioma del sistema   │    │
│  │  Publisher para cambios         │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## Idiomas Soportados

| Código | Idioma | Traducciones |
|--------|--------|--------------|
| `es` | Español | ✅ Completo |
| `en` | English | ✅ Completo |

## Añadir un Nuevo Idioma

Para añadir un nuevo idioma (ej: francés), solo se modifica el módulo:

```swift
// En LanguageModuleImpl.swift
var supportedLanguages: [String] {
    return ["es", "en", "fr"]  // Añadir "fr"
}

private static func loadTranslations() -> [String: [String: String]] {
    return [
        "es": [...],
        "en": [...],
        "fr": [  // Añadir diccionario francés
            "habits": "Habitudes",
            "settings": "Paramètres",
            // ...
        ]
    ]
}
```

El núcleo de la app no necesita ningún cambio.

## Validación de Traducciones

La GitHub Action incluye validación de claves:

```yaml
translations:
  steps:
    - name: 🔤 Check Translation Keys
      run: |
        # Verificar que ES y EN tienen las mismas claves
        echo "Validating translation keys..."
```

Esto asegura que no falten traducciones en ningún idioma.
