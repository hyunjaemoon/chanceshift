import 'package:flutter/material.dart';

enum ColorEnum {
  defaultColor,
}

final Map<ColorEnum, Color> colorMap = {
  ColorEnum.defaultColor: const Color.fromARGB(255, 0, 0, 40),
};

Color getColor(ColorEnum colorEnum) {
  return colorMap[colorEnum]!;
}
