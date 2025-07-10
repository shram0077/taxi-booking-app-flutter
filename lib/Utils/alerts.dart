import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';

alertInfo(context, String text, IconData icon, TypeInfo typeInfo) {
  return AlertInfo.show(
      context: context,
      padding: 45,
      text: text,
      icon: icon,
      typeInfo: typeInfo,
      position: MessagePosition.top);
}
