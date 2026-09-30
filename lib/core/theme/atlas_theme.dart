import 'package:flutter/material.dart';

abstract final class AtlasColors {
  static const paper = Color(0xfff4f3ed);
  static const paperDark = Color(0xffe8e7de);
  static const ink = Color(0xff233d35);
  static const inkLight = Color(0xff3b5b50);
  static const muted = Color(0xff64746c);
  static const green = Color(0xff315e4c);
  static const greenLight = Color(0xff437c64);
  static const rust = Color(0xffad633e);
  static const rustLight = Color(0xffc57850);
  static const gold = Color(0xffd4a34b);
  static const line = Color(0xffd9ded4);
  static const mapWater = Color(0xffe5ebe6);
  static const mapLand = Color(0xffc7d1c0);
  static const mapGrid = Color(0xffd4dcd0);
  static const glassBorder = Color(0x3fffffff);
  static const glassBg = Color(0x66ffffff);
  static const glassDarkBg = Color(0x88172d23);
}

class AtlasTheme {
  static TextStyle editorial(
    double size, {
    Color color = AtlasColors.ink,
    FontWeight weight = FontWeight.w400,
  }) =>
      TextStyle(
        fontFamily: 'AtlasSerif',
        fontSize: size,
        height: 1.15,
        letterSpacing: -size / 38,
        color: color,
        fontWeight: weight,
      );

  static TextStyle sans(
    double size, {
    Color color = AtlasColors.ink,
    FontWeight weight = FontWeight.normal,
  }) =>
      TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
      );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AtlasColors.paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AtlasColors.green,
          surface: AtlasColors.paper,
          brightness: Brightness.light,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: AtlasColors.ink,
              displayColor: AtlasColors.ink,
            ),
        splashFactory: NoSplash.splashFactory,
        dividerColor: AtlasColors.line,
      );
}
