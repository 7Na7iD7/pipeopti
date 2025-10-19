# Smart Pipe Optimization

A sophisticated Flutter application designed to calculate and visualize the most efficient pipe layout in a multi-story building using Kruskal's algorithm to determine the Minimum Spanning Tree (MST).

-----

## 📋 Table of Contents

  * [About The Project](#about-the-project)
  * [Screenshots](#screenshots)
  * [Key Features](#key-features)
  * [Core Algorithm: Kruskal's MST](#core-algorithm-kruskals-mst)
  * [Technology Stack](#technology-stack)
  * [Project Structure](#project-structure)
  * [Getting Started](#getting-started)
  * [License](#license)

## 📖 About The Project

This project provides a powerful tool for engineers and planners to optimize infrastructure costs. By inputting the number of floors and rooms in a building, the application generates a random spatial layout and then calculates the shortest possible total pipe length required to connect every room.

The result is an interactive, visually rich graph that allows users to explore the optimal network, view detailed connection data, and analyze the layout's efficiency through dynamic charts.

## 📸 Screenshots

*(Replace these placeholders with actual screenshots of your running application.)*

| Welcome & Login | Main Layout & Visualization | Data & Analytics |
| :---: | :---: | :---: |
| ** | *[GIF of the Interactive Graph Visualization]* | ** |
| A modern, animated entry point to the application. | The core interactive canvas where the optimal pipe network is displayed. | Detailed views of connection data and performance charts. |

## ✨ Key Features

  * **Dynamic Layout Generation**: Automatically creates a randomized, multi-floor building layout based on user-defined parameters (floors and rooms).
  * **Optimal Path Calculation**: Implements **Kruskal's algorithm** to find the Minimum Spanning Tree (MST), guaranteeing the most cost-effective pipe network.
  * **Interactive 2D Visualization**: A custom-painted, zoomable, and pannable canvas displays rooms (nodes) and pipes (edges). Users can tap on rooms to see details and adjust properties.
  * **Rich Data Analytics**: The "Analytics" tab provides insightful charts, including:
      * Distribution of pipe lengths.
      * Number of pipe connections originating from each floor.
  * **Detailed Connection List**: The "Data" tab presents a scrollable list of every required connection, showing the two rooms it connects and the distance between them.
  * **Modern UI/UX**:
      * Fluid animations and transitions throughout the app.
      * Beautifully designed Welcome and Login screens with Lottie animations.
      * Support for both **Light and Dark themes**.
  * **Advanced Filtering & Search**: A side-panel allows users to filter rooms by floor or search for specific rooms, which are then highlighted on the main graph.

## 🧠 Core Algorithm: Kruskal's MST

The heart of this application is **Kruskal's algorithm for finding a Minimum Spanning Tree (MST)**.

1.  **Nodes & Edges**: Each `Room` in the building is treated as a **node (or vertex)** in a graph. A potential pipe connection between any two rooms is an **edge**.
2.  **Edge Weight**: The "weight" of each edge is the calculated distance between two rooms. A key innovation in this model is the `distanceTo` function, which adds a significant **penalty for connections between different floors**. This realistically simulates the higher cost and complexity of vertical piping.
3.  **The Algorithm**:
      * All possible connections (edges) are generated and sorted by their distance (weight) in ascending order.
      * The algorithm iterates through the sorted edges.
      * For each edge, it checks if adding it to the network would form a cycle. It uses a **Disjoint Set Union (DSU)** data structure for this, which is highly efficient.
      * If no cycle is formed, the edge is added to our final network (the MST).
      * This process continues until there are `(number of rooms - 1)` edges, ensuring every room is connected.
4.  **Result**: The final set of connections forms the network with the absolute minimum total pipe length.

## 🛠️ Technology Stack

This project is built with Flutter and leverages several high-quality packages:

  * **Framework**: [Flutter](https://flutter.dev/)
  * **Language**: [Dart](https://dart.dev/)
  * **State Management**: `StatefulWidget` & `setState` (with a clean, service-oriented architecture)
  * **Charting**: [`fl_chart`](https://pub.dev/packages/fl_chart) - For the analytics dashboards.
  * **Animations**:
      * [`lottie`](https://pub.dev/packages/lottie) - For complex JSON-based animations on the welcome/login screens.
      * [`flutter_animate`](https://pub.dev/packages/flutter_animate) - For fluent and simple UI animations.
  * **UI Helpers**:
      * [`google_fonts`](https://pub.dev/packages/google_fonts) - For custom typography.
      * [`flutter_spinkit`](https://pub.dev/packages/flutter_spinkit) - For elegant loading indicators.

## 📂 Project Structure

The codebase is organized logically to separate concerns, making it clean and maintainable.

| File/Folder | Description |
| :--- | :--- |
| `main.dart` | The main entry point of the app, configures themes and routes. |
| `kruskal.dart` | Contains the core logic: classes for `Room`, `Connection`, `Building`, and the implementation of Kruskal's algorithm with a `DisjointSet`. |
| `pipe_layout_screen.dart` | The main screen of the application, managing state, user input, and displaying the three main tabs (Layout, Data, Analytics). |
| `modern_graph_visualization.dart`| The interactive widget that hosts the `CustomPainter` for the graph. Manages zooming, panning, and user interaction. |
| `room_and_connection_painter.dart`| The `CustomPainter` class responsible for drawing all rooms, connections, labels, and animations on the canvas. |
| `welcome_screen.dart` | A visually appealing welcome screen with custom animations. |
| `modern_login_screen.dart` | An animated, modern login screen with particle effects and a frosted glass UI. |
| `*.dart` (in root) | Reusable UI components like `MetricCard`, `ConnectionItem`, and helper `extensions`. |

## 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

1.  **Clone the repo**
    ```sh
    git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
    ```
2.  **Navigate to the project directory**
    ```sh
    cd YOUR_REPO
    ```
3.  **Install dependencies**
    ```sh
    flutter pub get
    ```
4.  **Run the app**
    ```sh
    flutter run
    ```

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.
