import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[100],
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _humidityController = TextEditingController();

  void _addWeather() async {
    await _firestore.collection('Weather').add({
      'district_province': _districtController.text,
      'temperature': double.parse(_temperatureController.text),
      'humidity': int.parse(_humidityController.text),
    });
    _districtController.clear();
    _temperatureController.clear();
    _humidityController.clear();
  }

  void _updateWeather(String id, double temperature, int humidity) async {
    await _firestore.collection('Weather').doc(id).update({
      'temperature': temperature,
      'humidity': humidity,
    });
  }

  void _deleteWeather(String id) async {
    await _firestore.collection('Weather').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Data'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _districtController,
              decoration: InputDecoration(labelText: 'อำเภอ/จังหวัด'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _temperatureController,
              decoration: InputDecoration(labelText: 'อุณหภูมิ (°C)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _humidityController,
              decoration: InputDecoration(labelText: 'ความชื้น (%)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addWeather,
              child: Center(child: Text('เพิ่มข้อมูล')),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder(
                stream: _firestore.collection('Weather').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: Text('กำลังโหลดข้อมูล...'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('ไม่มีข้อมูล'));
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(
                            "${doc['district_province']}",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            "🌡️ ${doc['temperature']} °C   💧 ${doc['humidity']}%",
                            style: TextStyle(fontSize: 14),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.orange),
                                onPressed: () {
                                  _temperatureController.text = doc['temperature'].toString();
                                  _humidityController.text = doc['humidity'].toString();
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('แก้ไขข้อมูล'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: _temperatureController,
                                            decoration: InputDecoration(labelText: 'อุณหภูมิ (°C)'),
                                            keyboardType: TextInputType.number,
                                          ),
                                          SizedBox(height: 10),
                                          TextField(
                                            controller: _humidityController,
                                            decoration: InputDecoration(labelText: 'ความชื้น (%)'),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () {
                                            _updateWeather(
                                              doc.id,
                                              double.parse(_temperatureController.text),
                                              int.parse(_humidityController.text),
                                            );
                                            Navigator.pop(context);
                                          },
                                          child: Text('อัปเดต'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteWeather(doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
