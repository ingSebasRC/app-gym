# IronLog - Gym Tracker Pro 🏋️‍♂️💪

**IronLog** es una aplicación de seguimiento de entrenamiento diseñada para entusiastas del fitness que buscan una herramienta profesional, rápida y visualmente impactante. Este proyecto ha sido desarrollado con **Flutter** y **SQLite**, enfocándose en la experiencia de usuario (UX) y el análisis de datos de progreso.

---

## 🔥 Características Principales

### 📈 Visualización de Progreso
*   **Gráficas Dinámicas:** Visualiza tu evolución de fuerza con gráficas de línea integradas al final de cada ejercicio (usando `fl_chart`).
*   **Récord Personal (PR):** La app detecta y destaca automáticamente tu mejor levantamiento histórico con una insignia especial.
*   **Volumen de Entrenamiento:** Cálculo en tiempo real del volumen total (Peso x Reps) por sesión para optimizar la hipertrofia.

### 📅 Navegación Semanal Infinita
*   **Calendario Táctil:** Desliza lateralmente para navegar entre días o usa el selector de semanas para consultar entrenamientos pasados o planificar futuros.
*   **Persistencia Temporal:** Cada entrenamiento queda vinculado a su fecha exacta en el calendario.

### 📋 Gestión de Rutinas e Inteligencia
*   **Plantillas de Rutina:** Crea tus propias rutinas y "impórtalas" en cualquier día con un solo toque. Ideal para repetir tus días de Empuje/Tracción/Pierna.
*   **Creación On-the-fly:** Crea nuevos ejercicios personalizados directamente mientras armas tu rutina.
*   **Auto-Save Pro:** Olvídate de los botones de guardar. La aplicación persiste tus datos automáticamente al salir de la pantalla.

### 🛠️ Herramientas de Precisión
*   **Selector de Unidades:** Soporte nativo para **KG** y **LB** con guardado de preferencia.
*   **Ajustes Rápidos:** Botones de +/- 5 para peso y +/- 1 para repeticiones que agilizan la entrada de datos durante el descanso.
*   **Cronómetro Integrado:** Timer flotante en pantalla para controlar tus tiempos de descanso con precisión.

---

## 🛠️ Stack Tecnológico

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **Base de Datos:** [Sqflite](https://pub.dev/packages/sqflite) (SQLite local)
*   **Gráficas:** [fl_chart](https://pub.dev/packages/fl_chart)
*   **Estado & Persistencia:** [Shared Preferences](https://pub.dev/packages/shared_preferences)
*   **Feedback:** Haptic Feedback para una experiencia táctil premium.

---

## 🚀 Instalación y Uso

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/tu-usuario/ironlog-gym-tracker.git
   ```
2. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```
3. **Ejecutar en modo Debug:**
   ```bash
   flutter run
   ```
4. **Generar APK de producción:**
   ```bash
   flutter build apk --release
   ```

---

## 🎯 Objetivo del Proyecto

Este proyecto fue creado para demostrar habilidades avanzadas en:
1.  **Gestión de Bases de Datos Relacionales:** Esquemas complejos, migraciones y consultas históricas.
2.  **Arquitectura Limpia:** Separación de lógica de negocio, servicios y UI.
3.  **UI/UX Avanzada:** Implementación de animaciones, gestos táctiles y visualización de datos compleja.
4.  **Optimización de Rendimiento:** Caching de datos y manejo eficiente del ciclo de vida de la aplicación.

---

## 📸 Capturas de Pantalla (Opcional)
> *Sugerencia: Añade aquí capturas de la Pantalla Principal, el Sistema de Rutinas y la Gráfica de Progreso.*

---
Desarrollado por [Tu Nombre] - 2026
