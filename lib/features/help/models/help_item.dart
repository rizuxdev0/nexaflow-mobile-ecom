import 'package:flutter/material.dart';

class FAQItem {
  final String question;
  final String answer;
  final List<String> tags;

  FAQItem({
    required this.question,
    required this.answer,
    required this.tags,
  });
}

class HelpSection {
  final String id;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<FAQItem> faqs;

  HelpSection({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.faqs,
  });
}

class GuideStep {
  final int step;
  final IconData icon;
  final String title;
  final String description;

  GuideStep({
    required this.step,
    required this.icon,
    required this.title,
    required this.description,
  });
}
