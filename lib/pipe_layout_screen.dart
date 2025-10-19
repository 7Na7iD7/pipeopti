import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'kruskal.dart';
import 'modern_graph_visualization.dart';
import 'metric_card.dart';
import 'connection_item.dart';
import 'dart:math';
import 'dart:isolate';

// Constants
class AppConstants {
  static const int minFloors = 2;
  static const int maxFloors = 6;
  static const int minRooms = 10;
  static const int maxRooms = 20;
  static const Duration calculationDelay = Duration(milliseconds: 800);
  static const Duration animationDuration = Duration(milliseconds: 500);
  static const Duration snackBarDuration = Duration(seconds: 3);
}

// Error Types
enum ValidationError {
  invalidFloors,
  invalidRooms,
  roomsLessThanFloors,
  calculationFailed,
}

// App State
enum AppState {
  initial,
  loading,
  calculated,
  error,
}

// Calculation Result
class CalculationResult {
  final List<Room> rooms;
  final List<Connection> connections;
  final double minimumPipeLength;
  final double originalNetworkLength;

  CalculationResult({
    required this.rooms,
    required this.connections,
    required this.minimumPipeLength,
    required this.originalNetworkLength,
  });

  double get reductionPercentage {
    if (originalNetworkLength <= 0) return 0;
    return ((originalNetworkLength - minimumPipeLength) / originalNetworkLength * 100);
  }
}

// Analytics Data
class AnalyticsData {
  final Map<int, int> connectionsPerFloor;
  final List<FlSpot> distanceSpots;
  final List<BarChartGroupData> floorBarGroups;

  AnalyticsData({
    required this.connectionsPerFloor,
    required this.distanceSpots,
    required this.floorBarGroups,
  });

  factory AnalyticsData.fromConnections(List<Connection> connections, BuildContext context) {
    final connectionsPerFloor = <int, int>{};
    for (var connection in connections) {
      connectionsPerFloor.update(
        connection.from.floor,
            (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final distanceSpots = <FlSpot>[];
    if (connections.isNotEmpty) {
      final sortedConnections = List<Connection>.from(connections)
        ..sort((a, b) => a.distance.compareTo(b.distance));
      for (int i = 0; i < sortedConnections.length; i++) {
        distanceSpots.add(FlSpot(i.toDouble(), sortedConnections[i].distance));
      }
    }

    final floorBarGroups = <BarChartGroupData>[];
    final sortedFloors = connectionsPerFloor.keys.toList()..sort();

    for (var floor in sortedFloors) {
      final count = connectionsPerFloor[floor]!;
      floorBarGroups.add(
        BarChartGroupData(
          x: floor,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  Theme.of(context).colorScheme.tertiary.withOpacity(0.7),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return AnalyticsData(
      connectionsPerFloor: connectionsPerFloor,
      distanceSpots: distanceSpots,
      floorBarGroups: floorBarGroups,
    );
  }
}

// Validation Helper
class ValidationHelper {
  static String? validateFloors(String? value) {
    if (value == null || value.isEmpty) return 'Required field';
    final floors = int.tryParse(value);
    if (floors == null || floors < AppConstants.minFloors || floors > AppConstants.maxFloors) {
      return 'Floors must be between ${AppConstants.minFloors} and ${AppConstants.maxFloors}';
    }
    return null;
  }

  static String? validateRooms(String? value) {
    if (value == null || value.isEmpty) return 'Required field';
    final rooms = int.tryParse(value);
    if (rooms == null || rooms < AppConstants.minRooms || rooms > AppConstants.maxRooms) {
      return 'Rooms must be between ${AppConstants.minRooms} and ${AppConstants.maxRooms}';
    }
    return null;
  }

  static ValidationError? validateInputs(int floors, int rooms) {
    if (floors < AppConstants.minFloors || floors > AppConstants.maxFloors) {
      return ValidationError.invalidFloors;
    }
    if (rooms < AppConstants.minRooms || rooms > AppConstants.maxRooms) {
      return ValidationError.invalidRooms;
    }
    if (rooms < floors) {
      return ValidationError.roomsLessThanFloors;
    }
    return null;
  }
}

// Error Handler
class ErrorHandler {
  static const Map<ValidationError, String> _errorMessages = {
    ValidationError.invalidFloors: 'Number of floors must be between ${AppConstants.minFloors} and ${AppConstants.maxFloors}',
    ValidationError.invalidRooms: 'Number of rooms must be between ${AppConstants.minRooms} and ${AppConstants.maxRooms}',
    ValidationError.roomsLessThanFloors: 'Total rooms cannot be less than number of floors',
    ValidationError.calculationFailed: 'Calculation failed. Please try again.',
  };

  static void showError(BuildContext context, ValidationError error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessages[error] ?? 'Unknown error occurred',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: AppConstants.snackBarDuration,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: AppConstants.snackBarDuration,
      ),
    );
  }
}

// Calculation Service
class CalculationService {
  static Future<CalculationResult> calculateOptimalLayout(int floors, int rooms) async {
    return await Isolate.run(() {
      final building = Building(floors: floors, totalRooms: rooms);
      building.generateRandomLayout();

      final originalLength = building.calculateFullNetworkLength();
      final kruskalResult = building.runKruskalAlgorithm();

      return CalculationResult(
        rooms: building.rooms,
        connections: kruskalResult.connections,
        minimumPipeLength: kruskalResult.totalLength,
        originalNetworkLength: originalLength,
      );
    });
  }
}

// Main Screen
class PipeLayoutScreen extends StatefulWidget {
  const PipeLayoutScreen({super.key});

  @override
  State<PipeLayoutScreen> createState() => _PipeLayoutScreenState();
}

class _PipeLayoutScreenState extends State<PipeLayoutScreen>
    with TickerProviderStateMixin {

  // Controllers
  final TextEditingController _floorController = TextEditingController(text: "3");
  final TextEditingController _roomController = TextEditingController(text: "15");
  final _formKey = GlobalKey<FormState>();

  // Animation Controllers
  late AnimationController _tabTransitionController;
  late Animation<double> _tabTransitionAnimation;
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;

  // State variables
  AppState _appState = AppState.initial;
  CalculationResult? _result;
  AnalyticsData? _analyticsData;
  int _selectedTab = 0;
  bool _isDetailedView = false;
  bool _isGraphFullScreen = false;


  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _tabTransitionController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _tabTransitionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _tabTransitionController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _floorController.dispose();
    _roomController.dispose();
    _tabTransitionController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _calculateOptimalPipeLayout() async {
    if (!_formKey.currentState!.validate()) return;

    final floors = int.tryParse(_floorController.text);
    final rooms = int.tryParse(_roomController.text);

    if (floors == null || rooms == null) return;

    final validationError = ValidationHelper.validateInputs(floors, rooms);
    if (validationError != null) {
      ErrorHandler.showError(context, validationError);
      return;
    }

    setState(() {
      _appState = AppState.loading;
    });

    if (!_loadingController.isAnimating) {
      _loadingController.repeat();
    }

    try {
      await Future.delayed(AppConstants.calculationDelay);
      final result = await CalculationService.calculateOptimalLayout(floors, rooms);

      if (mounted) {
        setState(() {
          _result = result;
          _analyticsData = AnalyticsData.fromConnections(result.connections, context);
          _appState = AppState.calculated;
        });

        print('=== Debug Info ===');
        print('State: $_appState');
        print('Result is null: ${_result == null}');
        if (_result != null) {
          print('Rooms count: ${_result?.rooms.length}');
          print('Connections count: ${_result?.connections.length}');
        } else {
          print('Result object is null, cannot access rooms or connections.');
        }
        print('================');

        ErrorHandler.showSuccess(
            context,
            'Optimal layout calculated successfully! Reduction: ${result.reductionPercentage.toStringAsFixed(1)}%'
        );
      }
    } catch (e) {
      print('Calculation error: $e');
      if (mounted) {
        setState(() {
          _appState = AppState.error;
        });
        ErrorHandler.showError(context, ValidationError.calculationFailed);
      }
    } finally {
      if(mounted){
        _loadingController.stop();
        _loadingController.reset();
      }
    }
  }

  void _changeTab(int index) {
    if (_selectedTab == index) return;

    setState(() {
      _selectedTab = index;
    });

    _tabTransitionController.forward().then((_) {
      if (mounted) {
        _tabTransitionController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_isGraphFullScreen && _result != null) {
      return _buildFullScreenGraph(theme);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: _buildAppBar(theme),
      body: SafeArea(
        child: _buildBody(theme, isDarkMode),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text(
        'Smart Pipe Optimization',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      actions: [
        // شرط _result != null برای دکمه‌های اکشن حفظ می‌شود زیرا نیاز به داده دارند
        if (_appState == AppState.calculated && _result != null) ...[
          IconButton(
            icon: Icon(_isGraphFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
            tooltip: _isGraphFullScreen ? 'Exit Full Screen' : 'Full Screen Graph',
            onPressed: () {
              setState(() {
                _isGraphFullScreen = !_isGraphFullScreen;
              });
            },
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isDetailedView = !_isDetailedView;
              });
            },
            icon: Icon(
              _isDetailedView ? Icons.grid_view_rounded : Icons.view_comfy_alt_outlined,
            ),
            tooltip: _isDetailedView ? 'Switch to Simple View' : 'Switch to Detailed View',
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFullScreenGraph(ThemeData theme) {
    // _result null check is already done before calling this in build method
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Graph Full Screen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.fullscreen_exit),
          tooltip: 'Exit Full Screen',
          onPressed: () {
            setState(() {
              _isGraphFullScreen = false;
            });
          },
        ),
      ),
      body: SafeArea(
        child: ModernGraphVisualization(
          key: ValueKey('graph_fullscreen_${_result!.rooms.hashCode}'),
          rooms: _result!.rooms,
          connections: _result!.connections,
          isDetailedView: _isDetailedView,
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDarkMode) {
    return Column(
      children: [
        _buildConfigurationCard(theme),

        _buildTabBar(isDarkMode),
        const SizedBox(height: 12),

        Expanded(
          child: AnimatedSwitcher(
            duration: AppConstants.animationDuration,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _appState == AppState.loading
                ? _buildLoadingView(theme) // اگر لودینگ است، فقط نمای لودینگ را نشان بده
                : Column( // در غیر این صورت، همیشه تب‌ها و محتوای آنها را نشان بده
              key: ValueKey(_selectedTab), // برای انیمیشن صحیح هنگام تغییر تب
              children: [
                // نمایش سطر MetricCard ها فقط در تب Layout و بعد از محاسبه
                if (_selectedTab == 0 && _appState == AppState.calculated && _result != null)
                  _buildMetricsRow(theme),
                Expanded(child: _getTabContent(isDarkMode)), // مستقیماً محتوای تب را نمایش بده
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildConfigurationCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.settings, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'Building Configuration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _floorController,
                      decoration: InputDecoration(
                        labelText: 'Floors',
                        prefixIcon: Icon(
                          Icons.layers,
                          color: theme.colorScheme.primary.withOpacity(0.7),
                        ),
                        suffixText: 'floors',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: ValidationHelper.validateFloors,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _roomController,
                      decoration: InputDecoration(
                        labelText: 'Rooms',
                        prefixIcon: Icon(
                          Icons.meeting_room,
                          color: theme.colorScheme.primary.withOpacity(0.7),
                        ),
                        suffixText: 'rooms',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: ValidationHelper.validateRooms,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    return ElevatedButton.icon(
                      onPressed: _appState == AppState.loading ? null : _calculateOptimalPipeLayout,
                      icon: _appState == AppState.loading
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.auto_graph),
                      label: Text(
                        _appState == AppState.loading
                            ? 'Calculating...'
                            : 'Calculate Optimal Pipe Layout',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        minimumSize: const Size(220, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildTabItem(0, 'Layout', Icons.map, isDarkMode),
            _buildTabItem(1, 'Data', Icons.data_array, isDarkMode),
            _buildTabItem(2, 'Analytics', Icons.analytics, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData icon, bool isDarkMode) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeTab(index),
        child: AnimatedContainer(
          duration: AppConstants.animationDuration,
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: MetricCard(
              title: 'Minimum Pipe Length',
              value: '${_result!.minimumPipeLength.toStringAsFixed(1)} units',
              icon: Icons.straighten,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MetricCard(
              title: 'Length Reduction',
              value: '${_result!.reductionPercentage.toStringAsFixed(1)}%',
              icon: Icons.trending_down,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _tabTransitionAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _tabTransitionAnimation,
          child: _getTabContent(isDarkMode),
        );
      },
    );
  }

  Widget _getTabContent(bool isDarkMode) {
    // این متد فقط انتخاب کننده تب است، منطق نمایش داده یا پیام خالی در خود متدهای هر تب باشد.
    switch (_selectedTab) {
      case 0:
        return _buildLayoutTab(isDarkMode);
      case 1:
        return _buildDataTab(isDarkMode);
      case 2:
        return _buildAnalyticsTab(isDarkMode);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLayoutTab(bool isDarkMode) {
    if (_result == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No layout data available. Please enter building details and click "Calculate Optimal Pipe Layout" to view.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDarkMode
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ModernGraphVisualization(
        key: ValueKey('graph_normal_${_result!.rooms.hashCode}'),
        rooms: _result!.rooms,
        connections: _result!.connections,
        isDetailedView: _isDetailedView,
      ),
    );
  }

  Widget _buildDataTab(bool isDarkMode) {
    if (_result == null || _result!.connections.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No connection data available. Please enter building details and click "Calculate Optimal Pipe Layout" to view.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDarkMode
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Optimal Connections',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_result!.connections.length} connections',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_result!.connections.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ConnectionItem(connection: _result!.connections[index]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(bool isDarkMode) {
    if (_analyticsData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No data available for analytics. Please enter building details and click "Calculate Optimal Pipe Layout" to view.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ListView(
        children: [
          _buildDistanceChart(isDarkMode),
          const SizedBox(height: 16),
          _buildFloorChart(isDarkMode),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDistanceChart(bool isDarkMode) {
    return Card(
      elevation: isDarkMode ? 1 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Connection Distance Distribution',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Shows pipe length distribution across connections',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: _analyticsData!.distanceSpots.isNotEmpty
                  ? LineChart(_buildLineChartData(isDarkMode))
                  : const Center(child: Text("Not enough data for distance chart.")),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorChart(bool isDarkMode) {
    return Card(
      elevation: isDarkMode ? 1 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Connections Per Floor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Number of pipes originating from each floor',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: _analyticsData!.floorBarGroups.isNotEmpty
                  ? BarChart(_buildBarChartData(isDarkMode))
                  : const Center(child: Text("Not enough data for floor connections chart.")),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartData(bool isDarkMode) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (_analyticsData!.distanceSpots.map((s) => s.y).reduce(max)) / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            strokeWidth: 0.5,
          );
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) =>
                SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 10,
                ),
                textAlign: TextAlign.left,
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            width: 0.5),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: _analyticsData!.distanceSpots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.tertiary,
            ],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                Theme.of(context).colorScheme.tertiary.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      minX: 0,
      maxX: (_analyticsData!.distanceSpots.length - 1).toDouble(),
      minY: 0,
    );
  }

  BarChartData _buildBarChartData(bool isDarkMode) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String floorName = getFloorName(group.x.toInt());
            return BarTooltipItem(
              '$floorName Floor\n${rod.toY.toInt()} connections',
              TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          },
          tooltipPadding: const EdgeInsets.all(8),
          tooltipMargin: 8,
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  getFloorName(value.toInt()),
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
            reservedSize: 30,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value % ((meta.appliedInterval / 2).ceil() == 0 ? 1 : (meta.appliedInterval / 2).ceil()) == 0 || value == meta.max) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 10,
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            strokeWidth: 0.5,
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            width: 0.5),
      ),
      barGroups: _analyticsData!.floorBarGroups,
      maxY: (_analyticsData!.connectionsPerFloor.values.isEmpty
          ? 0.0
          : _analyticsData!.connectionsPerFloor.values.reduce(max).toDouble()) + 2.0,
    );
  }

  String getFloorName(int floor) {
    if (floor < 0) return 'N/A';
    return String.fromCharCode('A'.codeUnitAt(0) + floor);
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SpinKitFadingCircle(
              color: theme.colorScheme.primary,
              size: 70.0,
            ),
          ),
          const SizedBox(height: 30),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Calculating optimal layout...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onBackground.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return const SizedBox.shrink();
  }
}