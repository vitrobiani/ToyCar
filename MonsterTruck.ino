#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_TX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

#define IN1 18
#define IN2 19
#define EN1 16

#define IN3 5
#define IN4 4
#define EN2 17

#define ACTION_TIME 300
#define BUFFER_TIME 10


void driveForward(int speed) {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  ledcWrite(EN1, speed);
}

void driveBackward(int speed) {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  ledcWrite(EN1, speed);
}

void steerLeft(int speed) {
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
  ledcWrite(EN2, speed);
}

void steerRight(int speed) {
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
  ledcWrite(EN2, speed);
}

void stopDrive() { ledcWrite(EN1, 0); }
void stopSteer() { ledcWrite(EN2, 0); }

BLECharacteristic *pTxCharacteristic;

bool deviceConnected = false;
bool needsAdvertisingRestart = false;

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) {
    deviceConnected = true;
    Serial.println("Client connected");
  }
  void onDisconnect(BLEServer *pServer) {
    deviceConnected = false;
    needsAdvertisingRestart = true;
    Serial.println("Client disconnected");
  }
};

class RxCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String value = pCharacteristic->getValue().c_str();
    value.trim(); 

    Serial.print("Received: ");
    Serial.println(value);

    if (value == "FORWARD") {
      driveForward(200);
    } else if (value == "BACKWARD") {
      driveBackward(200);
    } else if (value == "LEFT") {
      steerLeft(200);
    } else if (value == "RIGHT") {
      steerRight(200);
    } else if (value == "DRIVE_LEFT") {
      driveForward(200);
      steerLeft(200);
    } else if (value == "DRIVE_RIGHT") {
      driveForward(200);
      steerRight(200);
    } else if (value == "STOP") {
      stopDrive();
      stopSteer();
    }
  }
};

void setup() {
  Serial.begin(115200);

  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  ledcAttach(EN1, 1000, 8);
  ledcAttach(EN2, 1000, 8);

  BLEDevice::init("Monster_Truck");

  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pTxCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_TX,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pTxCharacteristic->addDescriptor(new BLE2902());

  BLECharacteristic *pRxCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_RX,
    BLECharacteristic::PROPERTY_WRITE
  );
  pRxCharacteristic->setCallbacks(new RxCallbacks());

  pService->start();
  pServer->getAdvertising()->start();
  Serial.println("BLE ready, waiting for connection...");
}


void loop() {
  //for when client restarts
  if (needsAdvertisingRestart) {
    needsAdvertisingRestart = false;
    delay(500); 
    BLEDevice::getAdvertising()->start();
    Serial.println("Advertising restarted");
  }
}

