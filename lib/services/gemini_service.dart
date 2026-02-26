import 'dart:convert';
// mjd penghubung antara klien dan server
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:schedule_generator_ai/models/task.dart';

class GeminiService {
  static const String _baseUrl = "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent";
  final String apiKey;

  GeminiService() : apiKey = dotenv.env['GEMINI_API_KEY'] ?? "Please input your apikay" {
 if (apiKey.isEmpty) {
    throw Exception("API key is missing or empty");
  
  }
  }

  Future<String> generateSchedule(List<Task> tasks) async {
   _validateTasks(tasks);
   final prompt = _buildPrompt(tasks);
   
   try {
    //akan muncul di debug console
     print("Prompt: \n$prompt");

     // add request timeout message to avoid indefinite hangs if the API doesn't responding
     // code setelah await itu code yang bakalan di jalankan dan itu hasilnya (?)
     //asyn = proses dimulai 2 tanda sedang berjalan secara bersamaan.
     //await = berakhirnya proses asynchronous sebelum melanjutkan ke code berikutnya


      final response = await http
          .post(Uri.parse("$_baseUrl?key=$apiKey"),
              headers: {
                "Content-Type": "application/json",
                },
              body: jsonEncode({
                "contentes": [
                  {
                    "role": "user",
                    "parts": [
                      {"text": prompt}
                    ]
                  }
                ]
              })
              ).timeout(Duration(seconds: 20));
              return _handleResponse(response);
      
   } catch (e) {
      throw ArgumentError("Failed to generate schedule: $e");
   }
   }

   String  _handleResponse(http.Response responses) {
    
      final data = jsonDecode(responses.body);
      if (responses.statusCode == 401) {
        throw ArgumentError("invalid API key or unauthorized access");
      } else if (responses.statusCode == 429) {
        throw ArgumentError("rate limit exceeded, please try again later");
      } else if (responses.statusCode == 500) {
        throw ArgumentError("internal server error, please try again later");
      } else if (responses.statusCode == 503) {
        throw ArgumentError("service unavailable, please try again later");
      } else if (responses.statusCode == 200) {
        throw data["candidates"][0]["content" ]["parts"][0]["text"];
      } else {
        throw ArgumentError("Unknown error ");
      }

    } 


   }
   
   


   String _buildPrompt(List<Task> tasks) {
    final taskList = tasks.map((task) => "${task.name} (priority: ${task.priority}, duration: ${task.duration} minutes, deadline: ${task.deadline})").join("\n");
    return "buatkan jadwal harian yang optimal berdasarkan task berikut: \n$taskList";
   }

   void _validateTasks(List<Task> tasks) {
    if (tasks.isEmpty) throw ArgumentError("Task cannot be empty");
   }
  