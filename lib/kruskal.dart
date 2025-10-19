import 'dart:math';

class Room {
  final String id;
  final String name;
  final int floor;
  final double x;
  final double y;
  double displayRadius;

  Room({
    required this.id,
    required this.name,
    required this.floor,
    required this.x,
    required this.y,
    this.displayRadius = 14.0,
  });

  @override
  String toString() => name;

  double distanceTo(Room other) {
    final double horizontalDistance = x - other.x;
    final double verticalDistance = y - other.y;
    final double floorChangePenalty = 5.0 + Random().nextDouble() * 5.0;
    final double floorDistance =
        (floor - other.floor).abs() * floorChangePenalty;
    return sqrt(
      horizontalDistance * horizontalDistance +
          verticalDistance * verticalDistance,
    ) +
        floorDistance;
  }
}

class Connection {
  final Room from;
  final Room to;
  final double distance;

  Connection({required this.from, required this.to, required this.distance});

  @override
  String toString() => '$from → $to (${distance.toStringAsFixed(1)})';
}

class KruskalResult {
  final List<Connection> connections;
  final double totalLength;

  KruskalResult({required this.connections, required this.totalLength});
}

class DisjointSet {
  final Map<String, String> _parent = {};
  final Map<String, int> _rank = {};

  void makeSet(String x) {
    _parent[x] = x;
    _rank[x] = 0;
  }

  String find(String x) {
    if (_parent[x] != x) {
      _parent[x] = find(_parent[x]!);
    }
    return _parent[x]!;
  }

  bool union(String x, String y) {
    String rootX = find(x);
    String rootY = find(y);

    if (rootX == rootY) return false;

    if (_rank[rootX]! < _rank[rootY]!) {
      _parent[rootX] = rootY;
    } else {
      _parent[rootY] = rootX;
      if (_rank[rootX] == _rank[rootY]) {
        _rank[rootX] = _rank[rootX]! + 1;
      }
    }
    return true;
  }
}

class Building {
  final int floors; // M
  final int totalRooms; // N
  List<Room> rooms = [];
  final Random _random = Random();

  Building({required this.floors, required this.totalRooms});

  void generateRandomLayout() {
    rooms.clear();
    final Random random = Random();
    final Map<int, List<Room>> roomsPerFloor = {};

    for (int i = 0; i < floors; i++) {
      roomsPerFloor[i] = [];
    }

    for (int i = 0; i < floors; i++) {
      final floorName = String.fromCharCode('A'.codeUnitAt(0) + i);
      final double x = 10.0 + random.nextDouble() * 20;
      final double y =
      50.0;

      final room = Room(
        id: 'room_${rooms.length}',
        name: '$floorName${1}',
        floor: i,
        x: x,
        y: y,
        displayRadius: 10.0 + random.nextDouble() * 10,
      );

      rooms.add(room);
      roomsPerFloor[i]!.add(room);
    }

    while (rooms.length < totalRooms) {
      final floorIndex = random.nextInt(floors);
      final floorName = String.fromCharCode('A'.codeUnitAt(0) + floorIndex);

      int roomNumberOnFloor = 1;
      bool isNameTaken(String name) => rooms.any((room) => room.name == name);
      String potentialName;
      do {
        potentialName = '$floorName$roomNumberOnFloor';
        roomNumberOnFloor++;
      } while (isNameTaken(potentialName));

      double newX;
      double newY;
      Room newRoom;
      bool validPosition = false;
      int attempts = 0;
      const maxAttempts = 50;

      do {
        newY = 50.0;
        if (roomsPerFloor[floorIndex]!.isEmpty) {
          newX = 10.0 + random.nextDouble() * 20;
        } else {
          final lastRoomInFloor = roomsPerFloor[floorIndex]!.last;
          final minDistance = 10.0;
          final maxDistance = 30.0;

          newX =
              lastRoomInFloor.x +
                  minDistance +
                  random.nextDouble() * (maxDistance - minDistance);
        }

        newRoom = Room(
          id: 'room_${rooms.length}',
          name: potentialName,
          floor: floorIndex,
          x: newX,
          y: newY,
          displayRadius: 10.0 + random.nextDouble() * 10,
        );

        validPosition = true;
        if (roomsPerFloor[floorIndex]!.isNotEmpty) {
          for (var existingRoom in roomsPerFloor[floorIndex]!) {
            final distance = sqrt(
              pow(newRoom.x - existingRoom.x, 2) +
                  pow(newRoom.y - existingRoom.y, 2),
            );
            if (existingRoom != newRoom &&
                (distance < 10.0 || distance > 300.0)) {
              validPosition = false;
              break;
            }
          }
        }

        attempts++;
        if (attempts >= maxAttempts && !validPosition) {
          newX += 10.0;
          newRoom = Room(
            id: 'room_${rooms.length}',
            name: potentialName,
            floor: floorIndex,
            x: newX,
            y: newY,
            displayRadius: 10.0 + random.nextDouble() * 10,
          );
          validPosition = true;
        }
      } while (!validPosition);

      rooms.add(newRoom);
      roomsPerFloor[floorIndex]!.add(newRoom);
    }
  }

  void addRoom({
    required String id,
    required String name,
    required int floor,
    required double x,
    required double y,
    double displayRadius = 14.0,
  }) {
    rooms.add(
      Room(
        id: id,
        name: name,
        floor: floor,
        x: x,
        y: y,
        displayRadius: displayRadius,
      ),
    );
  }

  List<Connection> generateAllPossibleConnections() {
    List<Connection> connections = [];
    if (rooms.length < 2) return connections;

    for (int i = 0; i < rooms.length; i++) {
      for (int j = i + 1; j < rooms.length; j++) {
        final distance = rooms[i].distanceTo(rooms[j]);
        connections.add(
          Connection(from: rooms[i], to: rooms[j], distance: distance),
        );
      }
    }
    return connections;
  }

  double calculateFullNetworkLength() {
    double totalLength = 0;
    List<Connection> allConnections = generateAllPossibleConnections();
    for (var connection in allConnections) {
      totalLength += connection.distance;
    }
    return totalLength;
  }

  KruskalResult runKruskalAlgorithm() {
    if (rooms.isEmpty) {
      return KruskalResult(connections: [], totalLength: 0);
    }

    List<Connection> allConnections = generateAllPossibleConnections();
    allConnections.sort((a, b) => a.distance.compareTo(b.distance));

    DisjointSet disjointSet = DisjointSet();
    for (var room in rooms) {
      disjointSet.makeSet(room.id);
    }

    List<Connection> mst = []; // Minimum Spanning Tree
    double totalLength = 0;
    int edgesCount = 0;
    int expectedEdges = rooms.length - 1;

    for (var connection in allConnections) {
      if (edgesCount == expectedEdges) break;

      if (disjointSet.union(connection.from.id, connection.to.id)) {
        mst.add(connection);
        totalLength += connection.distance;
        edgesCount++;
      }
    }
    return KruskalResult(connections: mst, totalLength: totalLength);
  }
}
