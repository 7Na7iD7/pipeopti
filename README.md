<!-- =================================================================== -->

<!-- 🚀 SMART PIPE OPTIMIZATION - PROFESSIONAL README -->

<!-- =================================================================== -->

<p align="center">
<img src="assets/smart_pipe_banner.png" alt="Smart Pipe Optimization Banner" width="100%">
</p>

<h1 align="center">💧 Smart Pipe Optimization</h1>
<p align="center">
<em>A next-generation Flutter app that designs the most efficient pipe layout using Kruskal’s MST algorithm.</em>
</p>

<p align="center">
<a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Framework-Flutter-blue?logo=flutter&logoColor=white" /></a>
<a href="https://dart.dev/"><img src="https://img.shields.io/badge/Language-Dart-0175C2?logo=dart&logoColor=white" /></a>
<a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" /></a>
<a href="#"><img src="https://img.shields.io/badge/Version-1.0.0-purple" /></a>
</p>

🧭 Table of Contents

📖 About The Project

📸 Screenshots

✨ Key Features

🧠 Core Algorithm: Kruskal's MST

🛠️ Technology Stack

📂 Project Structure

🚀 Getting Started

📘 Developer Notes

📜 License

📖 About The Project

💡 Smart Pipe Optimization provides engineers with a visual and algorithmic tool

to design the most efficient water or gas piping network across multiple floors.

It simulates realistic layouts, calculates optimal paths, and visualizes the network interactively.

🧩 Key Goals

Reduce material and construction costs.

Generate realistic layouts quickly.

Provide insights through analytics dashboards.

📸 Screenshots

🖥️ Welcome & Login

📊 Main Visualization

📈 Data & Analytics







Modern animated login with Lottie effects.

Interactive MST visualization of the layout.

Insightful charts and data-driven analysis.

✨ Key Features

⚙️ Dynamic Layout Generation > Automatically creates randomized building layouts based on user input (floors & rooms).

🔗 Optimal Path Calculation > Uses Kruskal’s Algorithm to form a Minimum Spanning Tree (MST) ensuring minimum total pipe length.

🧭 Interactive Visualization > Zoomable and pannable graph canvas with detailed node data.

📊 Rich Analytics Dashboard > Built-in charts show:

Pipe length distribution

Connection density per floor

🎨 Modern UI/UX

Smooth animations

Lottie-based onboarding

Light & Dark mode

🔍 Advanced Filtering & Search

Filter rooms by floor

Highlight specific nodes dynamically

🧠 Core Algorithm: Kruskal’s MST

🧩 Concept Overview

Each room is treated as a node; every potential pipe between two rooms is an edge.

Edge weights are calculated based on distance, with penalties for vertical pipes.

🔍 Steps of the Algorithm

Generate all possible connections.

Sort edges by distance (ascending).

Use Disjoint Set Union (DSU) to avoid cycles.

Select edges until (rooms - 1) connections are made.

💡 Result: A perfectly connected network with minimal total pipe length.

🛠️ Technology Stack

Category

Tools / Packages

Framework

Flutter

Language

Dart

State Management

StatefulWidget + Service-Oriented Architecture

Charts & Analytics

fl_chart

Animations

lottie, flutter_animate

UI Enhancements

google_fonts, flutter_spinkit

📂 Project Structure

📦 lib/
 ┣ 📜 main.dart                   # App entry point, routes & themes
 ┣ 📜 kruskal.dart                # Core MST algorithm & Disjoint Set
 ┣ 📜 pipe_layout_screen.dart     # Layout + Data + Analytics tabs
 ┣ 📜 modern_graph_visualization.dart # Interactive canvas visualization
 ┣ 📜 room_and_connection_painter.dart # CustomPainter for drawing rooms & edges
 ┣ 📜 welcome_screen.dart         # Lottie animations + onboarding
 ┣ 📜 modern_login_screen.dart    # Animated login (frosted glass UI)
 ┗ 📁 widgets/                    # Reusable UI components (MetricCard, etc.)


🚀 Getting Started

Follow these simple steps to set up locally 👇

# 1️⃣ Clone the repository
git clone [https://github.com/YOUR_USERNAME/smart_pipe_optimization.git](https://github.com/YOUR_USERNAME/smart_pipe_optimization.git)

# 2️⃣ Navigate to the directory
cd smart_pipe_optimization

# 3️⃣ Install dependencies
flutter pub get

# 4️⃣ Run the app
flutter run


📘 Developer Notes

🧩 Tips

You can modify the distanceTo penalty function to simulate different material costs.

Customize the UI theme via ThemeData in main.dart.

Future updates may include 3D visualization and Firebase sync.

📜 License

Distributed under the MIT License.
See the LICENSE file for details.

<p align="center"> <sub>💙 Built with Flutter • Designed for Engineers • Powered by Algorithms</sub> </p>
