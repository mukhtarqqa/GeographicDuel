import 'package:flutter/material.dart';
import 'geo_point.dart';

class PlayerState {
  PlayerState({
    required this.id,
    required this.name,
    this.rating = 1000,
    this.health = 6000,
    this.maxHealth = 6000,
    this.isBot = false,
    this.hasGuessed = false,
    this.currentGuess,
    this.roundScore = 0,
    this.distanceKm,
    this.avatarColor = const Color(0xff315e4c),
  });

  final String id;
  final String name;
  final int rating;
  int health;
  final int maxHealth;
  final bool isBot;
  bool hasGuessed;
  GeoPoint? currentGuess;
  int roundScore;
  double? distanceKm;
  final Color avatarColor;

  double get healthPercent => (health / maxHealth).clamp(0.0, 1.0);
  bool get isEliminated => health <= 0;

  void applyDamage(int damage) {
    health = (health - damage).clamp(0, maxHealth);
  }

  void resetForNewRound() {
    hasGuessed = false;
    currentGuess = null;
    roundScore = 0;
    distanceKm = null;
  }
}
