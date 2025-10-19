import 'dart:math';
import 'package:flutter/material.dart';

extension DoubleSquare on double {
  double get squared => this * this;
}

extension ColorBrightness on Color {
  Color brighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final int red = (this.red + (255 - this.red) * amount).round();
    final int green = (this.green + (255 - this.green) * amount).round();
    final int blue = (this.blue + (255 - this.blue) * amount).round();

    return Color.fromARGB(this.alpha, red, green, blue);
  }
}