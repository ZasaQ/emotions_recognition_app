import 'package:flutter/material.dart';


const Color themeMainTextColor = Color.fromRGBO(50, 38, 53, 1);
const Color themeMainBackgroundColor = Color.fromRGBO(192, 115, 202, 1);

final ThemeData appTheme = ThemeData(
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: themeMainBackgroundColor,
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
    ),
    backgroundColor: themeMainTextColor,
    actionsIconTheme: IconThemeData(color: themeMainBackgroundColor),
    iconTheme: IconThemeData(color: themeMainBackgroundColor),
  ),
  textTheme: const TextTheme(
    titleMedium: TextStyle(color: themeMainTextColor, fontSize: 20.0),
    bodyMedium: TextStyle(color: themeMainTextColor, fontSize: 16.0),
    bodySmall: TextStyle(
      color: themeMainTextColor,
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: themeMainTextColor,
    thickness: 2.0,
  ),
  iconTheme: const IconThemeData(color: themeMainTextColor),
  scaffoldBackgroundColor: themeMainBackgroundColor,
  colorScheme: ColorScheme.fromSeed(seedColor: themeMainBackgroundColor),
  useMaterial3: true,
);
