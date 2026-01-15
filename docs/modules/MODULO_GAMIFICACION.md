# 🎮 Módulo de Gamificación

## Información del Módulo

| Propiedad | Valor |
|-----------|-------|
| **ID** | `com.habitapp.module.gamification` |
| **Autor** | Lucas Barrientos |
| **Versión** | 1.0.0 |
| **Última actualización** | 03-01-2026 |

---

## 📋 Índice

1. [Descripción General](#descripción-general)
2. [Arquitectura](#arquitectura)
3. [Sistema de XP y Niveles](#sistema-de-xp-y-niveles)
4. [Sistema de Logros](#sistema-de-logros)
5. [Sistema de Trofeos](#sistema-de-trofeos)
6. [Recompensas Diarias](#recompensas-diarias)
7. [Integración con el Núcleo](#integración-con-el-núcleo)
8. [Vistas Disponibles](#vistas-disponibles)
9. [Testing](#testing)
10. [GitHub Actions](#github-actions)

---

## Descripción General

El módulo de gamificación añade elementos de juego a HabitApp para aumentar la motivación y retención de usuarios. Incluye:

- **Sistema de XP**: Puntos de experiencia por completar hábitos
- **10 Niveles de Usuario**: Desde "Novato" hasta "Inmortal"
- **26 Logros (Achievements)**: En 6 categorías diferentes
- **10 Trofeos**: En 5 tiers de rareza
- **Recompensas Diarias**: Con multiplicadores por racha de login

---

## Arquitectura

### Estructura de Archivos

```
HabitApp/
├── Modules/
│   └── Gamification/
│       └── GamificationModuleImpl.swift    # Implementación del módulo
└── Premium/
    └── Gamification/
        ├── Models/
        │   └── GamificationModels.swift    # UserLevel, Achievement, Trophy, etc.
        ├── Store/
        │   └── GamificationStore.swift     # Lógica de negocio y persistencia
        └── Views/
            ├── GamificationHubView.swift   # Vista principal del hub
            ├── AchievementsTabView.swift   # Lista de logros
            ├── TrophyRoomView.swift        # Sala de trofeos
            ├── DailyRewardsView.swift      # Recompensas diarias
            └── GamificationIconView.swift  # Iconos con fallback
```

### Patrones Utilizados

1. **Singleton**: `GamificationStore.shared` mantiene el estado global
2. **Observer Pattern**: Vistas reactivas con `@Published` properties
3. **Factory Pattern**: Creación de logros y trofeos predefinidos
4. **Protocol-Oriented**: Implementa `GamificationModuleProtocol`

---

## Sistema de XP y Niveles

### Fuentes de XP

| Acción | XP Base | XP Bonus |
|--------|---------|----------|
| Completar hábito | 5 | - |
| Racha de días | - | min(streak, 10) × 2 |
| Desbloquear logro | Varía | 10-200 según rareza |
| Desbloquear trofeo | Varía | 50-1000 según tier |
| Recompensa diaria | Varía | 5-50 según día |

### Tabla de Niveles

| Nivel | Nombre | XP Mínimo | XP Máximo | Icono |
|-------|--------|-----------|-----------|-------|
| 1 | Novato | 0 | 100 | ⭐ |
| 2 | Aprendiz | 100 | 300 | ⭐ |
| 3 | Dedicado | 300 | 600 | ⭐ |
| 4 | Constante | 600 | 1,000 | ⭐ |
| 5 | Experto | 1,000 | 1,500 | ⭐ |
| 6 | Maestro | 1,500 | 2,200 | ⭐ |
| 7 | Leyenda | 2,200 | 3,000 | 👑 |
| 8 | Héroe | 3,000 | 4,000 | 👑 |
| 9 | Campeón | 4,000 | 5,500 | 🏆 |
| 10 | Inmortal | 5,500 | ∞ | 🏆 |

---

## Sistema de Logros

### Categorías

#### 🔥 Rachas (6 logros)
| ID | Nombre | Requisito | Rareza | XP |
|----|--------|-----------|--------|-----|
| streak_3 | Primer Paso | 3 días | Común | 10 |
| streak_7 | Semana Perfecta | 7 días | Poco común | 30 |
| streak_14 | Dos Semanas | 14 días | Raro | 50 |
| streak_30 | Mes Completo | 30 días | Épico | 100 |
| streak_100 | Centenario | 100 días | Legendario | 150 |
| streak_365 | Un Año Perfecto | 365 días | Mítico | 200 |

#### ✅ Completados (6 logros)
| ID | Nombre | Requisito | Rareza | XP |
|----|--------|-----------|--------|-----|
| complete_1 | Primera Victoria | 1 hábito | Común | 5 |
| complete_10 | Diez Victorias | 10 hábitos | Poco común | 15 |
| complete_50 | Medio Centenar | 50 hábitos | Raro | 40 |
| complete_100 | Centenario | 100 hábitos | Épico | 80 |
| complete_500 | Quinientos | 500 hábitos | Legendario | 120 |
| complete_1000 | Mil Victorias | 1000 hábitos | Mítico | 180 |

#### 📅 Consistencia (4 logros)
- Semana Perfecta
- 80% Mensual
- Madrugador (Early Bird)
- Noctámbulo (Night Owl)

#### 🧭 Explorador (5 logros)
- Primera Foto
- Primer Modelo 3D
- Hábito IA
- Cinco Hábitos
- Todas las Categorías

#### ⭐ Especiales (5 logros)
- Primer Día
- Regreso Triunfal
- Año Nuevo
- Nivel 5
- Nivel 10

### Rarezas de Logros

| Rareza | Color | XP Típico |
|--------|-------|-----------|
| Común | Gris | 5-15 |
| Poco común | Verde | 15-30 |
| Raro | Azul | 30-60 |
| Épico | Púrpura | 60-100 |
| Legendario | Naranja | 100-150 |
| Mítico | Dorado | 150-200 |

---

## Sistema de Trofeos

### Tiers de Trofeos

| Tier | Nombre | Color | XP Bonus |
|------|--------|-------|----------|
| 🥉 Bronce | Bronce | Marrón | +50 |
| 🥈 Plata | Plata | Plateado | +100 |
| 🥇 Oro | Oro | Dorado | +200 |
| 💎 Platino | Platino | Blanco-plateado | +400 |
| 💠 Diamante | Diamante | Celeste | +1000 |

### Lista de Trofeos

| Tier | ID | Nombre | Requisito |
|------|-----|--------|-----------|
| Bronce | bronze_beginner | Iniciado | Primer hábito |
| Bronce | bronze_streak | Persistente | Racha de 7 días |
| Plata | silver_dedicated | Dedicado | 50 completados |
| Plata | silver_streak | Inquebrantable | Racha de 30 días |
| Oro | gold_master | Maestro | 200 completados |
| Oro | gold_streak | Leyenda Viviente | Racha de 100 días |
| Platino | platinum_elite | Élite | 500 completados |
| Platino | platinum_achiever | Coleccionista | 20 logros |
| Diamante | diamond_legend | Inmortal | 1000 completados |
| Diamante | diamond_perfect | Perfección | Racha de 365 días |

---

## Recompensas Diarias

### Ciclo de 7 Días

| Día | XP Recompensa |
|-----|---------------|
| 1 | 5 XP |
| 2 | 10 XP |
| 3 | 15 XP |
| 4 | 20 XP |
| 5 | 25 XP |
| 6 | 30 XP |
| 7 | 50 XP |

### Multiplicador por Racha

```swift
let multiplier = 1.0 + (Double(loginStreak / 7) * 0.1)
// Semana 1: x1.0
// Semana 2: x1.1
// Semana 3: x1.2
// etc.
```

---

## Integración con el Núcleo

### Registro del Módulo

```swift
// En ModuleBootstrapper.bootstrap()
let gamificationModule = GamificationModuleImpl()
ModuleRegistry.shared.registerGamificationModule(gamificationModule)
```

### Llamada desde HabitStore

```swift
// En HabitStore.toggleHabitCompletion()
if !wasCompleted {
    // Calcular racha...
    GamificationStore.shared.habitCompleted(streak: streak, category: habit.iconName)
}
```

### Llamada desde HabitCompletionSheet

```swift
// En saveAndDismiss()
GamificationStore.shared.habitCompleted(streak: habit.currentStreak, category: habit.iconName)

if hasImage {
    GamificationStore.shared.photoAdded()
}

if has3DModel {
    GamificationStore.shared.model3DCreated()
}
```

---

## Vistas Disponibles

### GamificationHubView
Vista principal con:
- Nivel y barra de progreso XP
- Resumen de estadísticas
- Acceso rápido a logros, trofeos y recompensas
- Logros/trofeos recientes

### AchievementsTabView
- Lista de todos los logros agrupados por categoría
- Filtros por categoría y estado (todos/desbloqueados/bloqueados)
- Detalle de cada logro con progreso

### TrophyRoomView
- Exhibición de trofeos por tier
- Animaciones de desbloqueo
- Detalle con requisitos

### DailyRewardsView
- Calendario semanal de recompensas
- Botón para reclamar XP diario
- Indicador de racha de login

---

## Testing

### Archivo de Tests
`HabitAppTests/GamificationTests.swift`

### Grupos de Tests

| Suite | Tests |
|-------|-------|
| UserLevelTests | Niveles, XP, orden |
| AchievementCategoryTests | Categorías |
| AchievementRarityTests | Rarezas, colores |
| AchievementTests | Estructura, unicidad |
| TrophyTierTests | Tiers, XP bonus |
| TrophyCollectionTests | Lista completa |
| GamificationProfileTests | Perfil, inicialización |
| GamificationStoreTests | Store, persistencia |
| GamificationModuleImplTests | Módulo, protocolo |
| GamificationModuleRegistryTests | Registro |

---

## GitHub Actions

### Workflow: `module-gamification.yml`

```yaml
name: 🎮 Gamification Module CI

on:
  push:
    paths:
      - 'HabitApp/Modules/Gamification/**'
      - 'HabitApp/Premium/Gamification/**'
      - 'HabitAppTests/GamificationTests.swift'
```

### Jobs

1. **Lint**: SwiftLint en archivos del módulo
2. **Build**: Compilación con Xcode 16.3
3. **Test**: Ejecución de GamificationTests
4. **UI Check**: Verificación de SwiftUI previews
5. **Verify Features**: Comprobación de características
6. **Docs**: Verificación de documentación

---

## Iconos Personalizados

Ver [ICONOS_GAMIFICACION.md](../ICONOS_GAMIFICACION.md) para los prompts de generación de:
- 26 iconos de logros
- 10 iconos de trofeos

### Ubicación de Assets

```
HabitApp/Assets.xcassets/Gamification/
├── Achievements/
│   ├── achievement_streak_3.imageset/
│   ├── achievement_streak_7.imageset/
│   └── ... (26 imagesets)
└── Trophies/
    ├── trophy_bronze_beginner.imageset/
    ├── trophy_bronze_streak.imageset/
    └── ... (10 imagesets)
```

---

## Troubleshooting

### Debug Logging

El módulo incluye prints extensos para debug:

```swift
print("🎮 [GamificationStore] habitCompleted - streak: \(streak), category: \(category)")
print("🎮 [GamificationStore] XP antes: \(profile.totalXP)")
print("🎮 [GamificationStore] XP después: \(profile.totalXP)")
```

### Problemas Comunes

1. **Logros no se desbloquean**: Verificar que `habitCompleted()` se llame correctamente
2. **XP +0 en recompensas**: Revisar `claimDailyReward()` y validación de datos
3. **Datos corruptos**: Usar `resetAllData()` para reiniciar

### Reset de Datos

```swift
GamificationStore.shared.resetAllData()
```

## Diagrama de Arquitectura

```
┌──────────────────────────────────────────────────────────┐
│                      Núcleo de la App                    │
│  ┌────────────────────────────────────────────────────┐  │
│  │ HabitCompletionSheet / UI                          │  │
│  │ - Llama a GamificationStore.shared.habitCompleted()│  │
│  │ - Muestra GamificationHubView / AchievementsTabView│  │
│  └───────────────┬────────────────────────────────────┘  │
└──────────────────┼──────────────────────────────────────-┘
                                     │
                                     ▼
┌──────────────────────────────────────────────────────────┐
│                  ModuleRegistry / Bootstrapper           │
│ - Registra `GamificationModuleImpl` en el arranque       │
└────────────────────────────┬─────────────────────────────┘
                                                         │
                                                         ▼
┌──────────────────────────────────────────────────────────┐
│               GamificationModuleImpl (concreto)          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ - GamificationStore(lógica de negocio, XP, niveles)│  │
│  │ - GamificationStore.shared (singleton / Provider)  │  │
│  │ - GamificationStore ->Persistence (UserDefaults/DB)│  │
│  │ - Views: GamificationHubView, AchievementsTabView  │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘

Flujo resumido:
- `ModuleBootstrapper` crea `GamificationModuleImpl` y lo registra en `ModuleRegistry`.
- Al completar un hábito, `HabitCompletionSheet` o `HabitStore` invocan `GamificationStore.shared.habitCompleted(...)`.
- `GamificationStore` calcula XP, actualiza rachas, desbloquea logros/trofeos, persiste estado y publica cambios via `@Published`.
- Vistas observan `GamificationStore` y reaccionan (UI, animaciones, notificaciones).
```

## Para la presentación

- **Resumen:** Añade XP, niveles, logros, trofeos y recompensas diarias; integra en el flujo de completado de hábitos para aumentar retención.
- **Patrones de diseño:**
    - **Singleton:** `GamificationStore.shared` como fuente de verdad.
    - **Observer (Reactive):** `@Published` + Combine para actualizaciones en tiempo real en vistas.
    - **Factory/Builder:** creación de logros y trofeos predefinidos centralizada.
    - **Protocol-oriented:** `GamificationModuleProtocol` permite intercambiar implementaciones.
- **Tecnologías / APIs:**
    - `Swift`, `SwiftUI` para UI y vistas reactivas.
    - `Combine` (`@Published`) para observación de estado.
    - `UserDefaults` / persistencia local para perfil y metadatos (puede ampliarse a DB local).
    - Animaciones SwiftUI y assets (`Assets.xcassets/Gamification`).
- **Requisitos / Consideraciones:**
    - No requiere permisos especiales (salvo acceso opcional a fotos si se integran imágenes de logros).
    - Diseñado para funcionar en todas las plataformas soportadas por la app con adaptaciones UI.
- **Slides sugeridas:**
    - Diagrama de flujo (bootstrap → registro → trigger desde HabitCompletion → GamificationStore → UI).
    - Patrones y beneficios (retención, feedback inmediato, testabilidad).
    - KPIs a medir: aumento de retención diaria, incremento de completados, uso de features premium.

## Desacoplamiento e inyección de dependencias

- **Interfaz vs implementación:** el núcleo interactúa con `GamificationModuleProtocol` / `GamificationStore` sin conocer detalles internos de cálculo de XP o reglas de desbloqueo.
- **Registro centralizado:** `ModuleRegistry` permite inyectar la implementación concreta (`GamificationModuleImpl`) en bootstrap; útil para sustituir por `MockGamificationModule` en tests.
- **Singleton controlado:** aunque `GamificationStore.shared` es singleton, la arquitectura permite resetear o sustituir la instancia durante pruebas o arranque alternativo.
- **Observabilidad desacoplada:** vistas consumen datos publicados (`@Published`) en vez de llamadas directas, evitando llamadas sincrónicas y acoplamiento fuerte.
- **Persistencia encapsulada:** la lógica de almacenamiento (UserDefaults/DB) está dentro del módulo; el núcleo solo requiere API de alto nivel (por ejemplo, `resetAllData()`).
- **Feature gating y configuración:** el módulo puede exponer flags (e.g., `isPremiumEnabled`) y el núcleo simplemente consulta dichas banderas para mostrar/ocultar UI.
- **Testabilidad:** se pueden crear `MockGamificationStore` o inyectar test doubles via `ModuleRegistry` para validar flujos (XP, logros, notificaciones) sin tocar persistencia real.

