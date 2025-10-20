<div align="center">

# 💧 Smart Pipe Optimization

**A next-generation Flutter app that designs the most efficient pipe layout using Kruskal’s MST algorithm.**

[![Flutter](https://img.shields.io/badge/Framework-Flutter-blue?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Language-Dart-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-purple)](https://github.com/YOUR_USERNAME/smart_pipe_optimization/releases/tag/1.0.0)
[![Dart SDK](https://img.shields.io/badge/Dart_SDK-3.0.0+-teal)](https://dart.dev/)

</div>

---

## 🧭 Table of Contents

- [📖 About The Project](#-about-the-project)
- [✨ Key Features](#-key-features)
- [🧠 Core Algorithm: Kruskal's MST](#-core-algorithm-kruskals-mst)
- [🛠️ Technology Stack](#️-technology-stack)
- [📂 Project Structure](#-project-structure)
- [🚀 Getting Started](#-getting-started)
- [📘 Developer Notes](#-developer-notes)
- [📜 License](#-license)

---

## 📖 About The Project

💡 **Smart Pipe Optimization** empowers engineers with a cutting-edge visual and algorithmic tool to craft the most efficient water or gas piping networks across multi-floor buildings. It generates realistic layouts, computes optimal paths, and delivers interactive visualizations for seamless design workflows.

### 🧩 Key Goals
- **Minimize Costs**: Slash material and construction expenses through optimized pipe routing.
- **Accelerate Design**: Produce lifelike building layouts in seconds based on user specifications.
- **Unlock Insights**: Dive deep into analytics with intuitive dashboards for data-driven decisions.

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| **⚙️ Dynamic Layout Generation** | Auto-generates randomized multi-floor building layouts tailored to user-defined floors and rooms. |
| **🔗 Optimal Path Calculation** | Leverages Kruskal’s Algorithm for Minimum Spanning Tree (MST) to minimize total pipe length. |
| **🧭 Interactive Visualization** | Fully zoomable and pannable canvas with hover tooltips for node details and edge metrics. |
| **📊 Rich Analytics Dashboard** | Embedded fl_chart visualizations including:<br>• Pipe length histograms<br>• Per-floor connection density heatmaps<br>• Cost estimation breakdowns |
| **🎨 Modern UI/UX** | - Fluid animations via Lottie & flutter_animate<br>- Seamless light/dark mode toggle<br>- Responsive design for mobile & tablet |
| **🔍 Advanced Filtering & Search** | - Filter rooms by floor or type<br>- Dynamic node highlighting<br>- Searchable connection logs |

---

## 🧠 Core Algorithm: Kruskal's MST

### 🧩 Concept Overview
In this system, each room acts as a **node**, and potential pipes between rooms form **weighted edges**. Weights incorporate Euclidean distances with vertical penalties to mimic real-world plumbing challenges.

### 🔍 Algorithm Steps
1. **Generate Edges**: Compute all pairwise connections between nodes with distance-based weights.  
2. **Sort by Weight**: Arrange edges in ascending order of cost (shortest first).  
3. **Union-Find (DSU)**: Employ Disjoint Set Union to detect and prevent cycles during edge selection.  
4. **Build MST**: Add edges iteratively until exactly `(n-1)` connections link all `n` nodes.

### 💡 Outcome
A fully connected, cycle-free network with the **absolute minimum pipe length** – proven optimal for cost efficiency!

> 🔗 **Deep Dive**: Check `lib/kruskal.dart` for the full implementation with customizable penalties.

---

## 🛠️ Technology Stack

| Category | Tools / Packages |
|----------|------------------|
| **Framework** | Flutter 3.24+ |
| **Language** | Dart 3.0+ |
| **State Management** | StatefulWidget + Provider for reactive services |
| **Charts & Analytics** | [fl_chart](https://pub.dev/packages/fl_chart) for dynamic visualizations |
| **Animations** | [lottie](https://pub.dev/packages/lottie), [flutter_animate](https://pub.dev/packages/flutter_animate) |
| **UI Enhancements** | [google_fonts](https://pub.dev/packages/google_fonts), [flutter_spinkit](https://pub.dev/packages/flutter_spinkit) |
| **Graph Rendering** | CustomPainter with Canvas for performant node/edge drawing |
| **Utilities** | [equatable](https://pub.dev/packages/equatable) for immutable models |

---

## 📂 Project Structure

```bash
📦 lib/
┣ 📜 main.dart # App bootstrap: themes, routes, and providers
┣ 📜 kruskal.dart # Kruskal's MST core + DSU implementation
┣ 📜 pipe_layout_screen.dart # Tabbed interface: Layout | Data | Analytics
┣ 📜 modern_graph_visualization.dart # GestureDetector-wrapped CustomPainter canvas
┣ 📜 room_and_connection_painter.dart # Draws rooms (rects), edges (lines), & labels
┣ 📜 welcome_screen.dart # Lottie-animated onboarding carousel
┣ 📜 modern_login_screen.dart # Frosted glass auth with form validation
```

---

## 🚀 Getting Started

Ready to pipe up your dev environment? Follow these steps:

### 1️⃣ Clone the Repo
```bash
git clone https://github.com/YOUR_USERNAME/smart_pipe_optimization.git
```

### 2️⃣ Navigate & Prep
```bash
cd smart_pipe_optimization
flutter pub get
```

### 3️⃣ Launch the App
```bash
flutter run
```

---

⚠️ **Requirements:**  
Flutter SDK ≥ **3.24**, Dart ≥ **3.0**.  
Ensure your emulator/device is properly connected.

---

📘 **Developer Notes**

🧩 **Quick Tips**
- **Tweak Penalties:** Edit `distanceTo()` in `kruskal.dart` to include material-specific costs (e.g., copper vs. PVC).  
- **Theme Customization:** Override `ThemeData` in `main.dart` for brand-aligned colors.  
- **Extensibility:** Roadmap includes 3D extrusion views (via `three_dart`) and cloud sync (Firebase).

---

🔧 **Contributing**  
Fork the repo, create a branch (`feat/your-feature`), and open a PR with tests.  
See **CONTRIBUTING.md** for guidelines.

---

🐛 **Issues?**  
Report bugs or suggest new features via the **Issues** section.

---

📜 **License**  
This project is distributed under the **MIT License**.  
Free to use, modify, and distribute – credit appreciated! 🚀

---

<div align="center">
  <sub>💙 Built with ❤️ using Flutter • Engineered for Precision • Algorithm-Powered Innovation</sub>
</div>
