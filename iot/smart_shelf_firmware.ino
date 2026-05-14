/**
 * Smart Shelf — ESP8266 Firmware
 * 
 * Hardware: ESP8266 NodeMCU + HX711 Load Cell Amplifier
 * 
 * Reads weight from HX711 sensor(s) and POSTs to Supabase Edge Function
 * every SEND_INTERVAL_MS milliseconds.
 * 
 * Wiring (HX711):
 *   DOUT → D2 (GPIO4)
 *   SCK  → D3 (GPIO0)
 *   VCC  → 3.3V
 *   GND  → GND
 */

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include "HX711.h"

// ── Configuration ─────────────────────────────────────────
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

const char* SUPABASE_URL   = "https://njrflpglzlbyumeyizgm.supabase.co/functions/v1/sensor-data";
const char* SUPABASE_ANON  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qcmZscGdsemxieXVtZXlpemdtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0Nzg4NzQsImV4cCI6MjA5MzA1NDg3NH0.idG964OiTTQ7zltdrSow6BDPMd8zUMQX7BjGXfH-H0w";

// Unique ID for this ESP8266 (must match shelves.sensor_id in DB)
const char* SENSOR_ID = "shelf-A1-esp8266";

// Send interval (ms)
const unsigned long SEND_INTERVAL_MS = 5000;

// ── HX711 Pins ────────────────────────────────────────────
const int DOUT_PIN = D2;  // GPIO4
const int SCK_PIN  = D3;  // GPIO0

// Calibration factor — run calibration sketch first
float CALIBRATION_FACTOR = -7050.0;

// ── Slot mapping ──────────────────────────────────────────
// If you have multiple load cells, add more HX711 instances here
// and map each to a slot number that matches your database items.
const int NUM_SLOTS = 1;

HX711 scale;

unsigned long lastSendTime = 0;
bool wifiConnected = false;

// ── Setup ─────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(100);
  Serial.println("\n🚀 Smart Shelf Firmware v1.0");

  // Initialize HX711
  scale.begin(DOUT_PIN, SCK_PIN);
  scale.set_scale(CALIBRATION_FACTOR);
  scale.tare();  // Zero out on startup
  Serial.println("✅ Scale initialized and tared");

  // Connect to WiFi
  connectWiFi();
}

// ── Main Loop ─────────────────────────────────────────────
void loop() {
  // Maintain WiFi connection
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("⚠️  WiFi disconnected. Reconnecting...");
    connectWiFi();
  }

  unsigned long now = millis();
  if (now - lastSendTime >= SEND_INTERVAL_MS) {
    lastSendTime = now;
    sendReadings();
  }
}

// ── Connect to WiFi ───────────────────────────────────────
void connectWiFi() {
  Serial.printf("📶 Connecting to WiFi: %s", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("\n✅ Connected! IP: %s\n", WiFi.localIP().toString().c_str());
    wifiConnected = true;
  } else {
    Serial.println("\n❌ WiFi connection failed. Will retry...");
    wifiConnected = false;
  }
}

// ── Read weight from HX711 ────────────────────────────────
float readWeightGrams() {
  if (!scale.is_ready()) return -1.0;
  float weight = scale.get_units(5);  // Average of 5 readings
  if (weight < 0) weight = 0;          // Clamp negatives
  return weight;
}

// ── Build JSON payload ────────────────────────────────────
String buildPayload(float* weights, int count) {
  StaticJsonDocument<512> doc;
  doc["sensor_id"] = SENSOR_ID;

  JsonArray readings = doc.createNestedArray("readings");
  for (int i = 0; i < count; i++) {
    JsonObject r = readings.createNestedObject();
    r["slot"] = i + 1;
    r["weight_g"] = weights[i];
  }

  String output;
  serializeJson(doc, output);
  return output;
}

// ── Send readings to Supabase ─────────────────────────────
void sendReadings() {
  float weights[NUM_SLOTS];
  
  // Read weight for slot 1
  weights[0] = readWeightGrams();
  Serial.printf("📦 Slot 1 weight: %.1f g\n", weights[0]);

  // Add more slots here if needed:
  // weights[1] = readWeight_slot2();

  String payload = buildPayload(weights, NUM_SLOTS);
  Serial.printf("📤 Sending: %s\n", payload.c_str());

  WiFiClientSecure client;
  client.setInsecure();  // Skip SSL verification (acceptable for IoT)

  HTTPClient http;
  if (!http.begin(client, SUPABASE_URL)) {
    Serial.println("❌ HTTP begin failed");
    return;
  }

  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", String("Bearer ") + SUPABASE_ANON);
  http.addHeader("apikey", SUPABASE_ANON);

  int httpCode = http.POST(payload);

  if (httpCode == HTTP_CODE_OK || httpCode == 200) {
    String response = http.getString();
    Serial.printf("✅ Response (%d): %s\n", httpCode, response.c_str());
  } else {
    Serial.printf("❌ HTTP error: %d\n", httpCode);
  }

  http.end();
}
