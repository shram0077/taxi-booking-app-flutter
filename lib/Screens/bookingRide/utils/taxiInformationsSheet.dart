import 'package:flutter/material.dart';

Widget taxiInformationsSheet(String driverId) {
  // Here, you could fetch taxi info based on driverId from your database or API
  return Container(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Taxi Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        // Display driver info here (For now, it's a placeholder)
        Text('Driver ID: $driverId'),
        SizedBox(height: 16),
        Text('Driver Name: John Doe'), // Replace with actual data
        SizedBox(height: 8),
        Text('Taxi Model: Toyota Camry'), // Replace with actual data
        SizedBox(height: 8),
        Text('License Plate: ABC1234'), // Replace with actual data
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // Handle call or message to the driver
          },
          child: Text('Contact Driver'),
        ),
      ],
    ),
  );
}
