import cv2
import dlib
import numpy as np
import os
import time
from datetime import datetime
from ultralytics import YOLO
import serial
import json


TRIPS_FILE = os.path.expanduser("/home/mahyar/Desktop/trips.json") # File to log trips
prev_byte = 0 # keeps track of prev byte from ESP
driver_face_rect = None  # to track the driver's face

# start a new trip function
def start_new_trip():
    """Create a new trip entry when the Pi boots up."""
    if os.path.exists(TRIPS_FILE):
        try:
            with open(TRIPS_FILE, "r") as f:
                data = json.load(f)
        except json.JSONDecodeError:
            data = {"trips": []}
    else:
        data = {"trips": []}

    new_trip_id = len(data["trips"]) + 1  # trip number = total trips + 1
    new_trip = {
        "trip_id": new_trip_id,
        "start_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "distractions": 0,
        "end_time": None
    }

    data["trips"].append(new_trip)
    with open(TRIPS_FILE, "w") as f:
        json.dump(data, f, indent=4)

    print(f"🚗 Started new trip #{new_trip_id}")
    return new_trip_id

# add distraction function
def add_distraction():
    """Increment distraction count for the latest trip in trips.json"""
    if os.path.exists(TRIPS_FILE):
        try:
            with open(TRIPS_FILE, "r") as f:
                data = json.load(f)
        except json.JSONDecodeError:
            data = {"trips": []}
    else:
        data = {"trips": []}

    if data["trips"]:
        # Add 1 distraction to the last trip
        data["trips"][-1]["distractions"] += 1
    else:
        # If no trips exist, start one automatically
        new_trip = {
            "trip_id": 1,
            "start_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "distractions": 1,
            "end_time": None
        }
        data["trips"].append(new_trip)

    with open(TRIPS_FILE, "w") as f:
        json.dump(data, f, indent=4)

    print("⚠️ Added distraction to trips.json")

def compute_iou(a, b):
    # convert dlib rectangles to box format
    ax1, ay1, ax2, ay2 = a.left(), a.top(), a.right(), a.bottom()
    bx1, by1, bx2, by2 = b.left(), b.top(), b.right(), b.bottom()

    inter_x1 = max(ax1, bx1)
    inter_y1 = max(ay1, by1)
    inter_x2 = min(ax2, bx2)
    inter_y2 = min(ay2, by2)

    inter_area = max(0, inter_x2 - inter_x1) * max(0, inter_y2 - inter_y1)
    area_a = (ax2 - ax1) * (ay2 - ay1)
    area_b = (bx2 - bx1) * (by2 - by1)

    union = area_a + area_b - inter_area
    if union == 0:
        return 0
    return inter_area / union



# === Serial Setup ===
ser = serial.Serial('/dev/serial0', 115200, timeout=1)
time.sleep(2)

# === Load Models ===
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")
model = YOLO('best_traffic_nano_yolo.pt')

# === Global States ===
greenLight = False
attentive = False
looking_down = False

# === File Save Path ===
save_path = "/home/mahyar/Desktop/test_photos"
os.makedirs(save_path, exist_ok=True)

# --- Serial I/O ---
def send_bit(b):
    ser.write(bytes([b]))
    ser.flush()
    print(f"Sent: 0x{b:02X}")

def receive_bit():
    if ser.in_waiting > 0:
        byte = ser.read(1)
        return int.from_bytes(byte, "big")
    return None

# --- Head Pose Detection ---
def estimate_head_pose(image):
    global looking_down, attentive, driver_face_rect

    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = detector(gray)

    # --- If no face found ---
    if len(faces) == 0:
        attentive = True
        driver_face_rect = None  # reset tracking if face lost
        return image

    # --- If driver not selected yet, pick the LARGEST face ---
    if driver_face_rect is None:
        # choose the face with the biggest rectangle area
        driver_face_rect = max(faces, key=lambda r: r.width() * r.height())

    # --- Try to match new detections to the saved driver face ---
    chosen_face = None
    for face in faces:
        # IOU (Intersection-over-Union) to see if the face overlaps the saved face
        iou = compute_iou(driver_face_rect, face)
        if iou > 0.3:  # threshold — they overlap enough
            chosen_face = face
            driver_face_rect = face  # update tracking box
            break

    # --- If no match found, ignore all faces this frame ---
    if chosen_face is None:
        attentive = True
        return image

    # --- Run your existing head pose logic on ONLY the chosen face ---
    face = chosen_face
    landmarks = predictor(gray, face)

    left_eye = np.array([landmarks.part(36).x, landmarks.part(36).y])
    right_eye = np.array([landmarks.part(45).x, landmarks.part(45).y])
    nose_tip = np.array([landmarks.part(30).x, landmarks.part(30).y])

    eye_midpoint = (left_eye + right_eye) / 2
    vertical_displacement = nose_tip[1] - eye_midpoint[1]

    if vertical_displacement > 40:
        print("Looking down:", vertical_displacement)
        attentive = False
    elif vertical_displacement < 10:
        print("Looking up:", vertical_displacement)
        attentive = False
    else:
        print("Looking straight:", vertical_displacement)
        attentive = True

    # Draw facial landmarks
    for n in range(68):
        x, y = landmarks.part(n).x, landmarks.part(n).y
        cv2.circle(image, (x, y), 1, (0, 255, 0), -1)

    return image


# --- Cameras ---
cap_front = cv2.VideoCapture("/dev/v4l/by-id/usb-Ruision_UVC_Camera_20200416-video-index0")
cap_back = cv2.VideoCapture("/dev/v4l/by-id/usb-046d_Brio_100_2525APPPKBE8-video-index0")
cap_front.set(cv2.CAP_PROP_FPS, 30)
cap_back.set(cv2.CAP_PROP_FPS, 30)

if not cap_front.isOpened() or not cap_back.isOpened():
    print("Error: One or both cameras could not be opened.")
    exit()

frame_id = 0
skip = 30

start_new_trip()

print("✅ System ready. Listening for ESP signal...")

current_bit = None
# --- Main Loop ---
while True:
    ret1, frame1 = cap_front.read()
    ret2, frame2 = cap_back.read()

    if ret1:
        frame1 = estimate_head_pose(frame1)
        cv2.imshow("Front Camera (Head Pose)", frame1)

    if ret2:
        if frame_id % skip == 0:
            results = model(frame2)
            for r in results:
                if len(r.boxes) > 0:
                    frame2 = r.plot()
                    filename2 = f"traffic_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
                    filepath2 = os.path.join(save_path, filename2)
                    cv2.imwrite(filepath2, frame2)
                    print(f"🚦 YOLO detected object. Saved: {filepath2}")

                    # Optional: detect green light
                    for box in r.boxes:
                        cls = model.names[int(box.cls)]
                        if "green" in cls.lower():
                            greenLight = True
                            print("green light detected")
                            break
                        else:
                            greenLight = False
                else:
                    greenLight = False
                    
        cv2.imshow("Rear Camera (YOLO)", frame2)

    # --- State signaling ---
    if greenLight and attentive:
        bit_to_send = 0x11
    elif not greenLight and attentive:
        bit_to_send = 0x01
    elif greenLight and not attentive:
        bit_to_send = 0x10
    else:
        bit_to_send = 0x00

    if bit_to_send != current_bit:
        send_bit(bit_to_send)
        current_bit = bit_to_send

    # --- Listen for ESP command ---
    byte_in = receive_bit()
    if byte_in == 1 and prev_byte == 0 and ret1 and ret2:
        filename1 = f"front_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
        filename2 = f"rear_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
        cv2.imwrite(os.path.join(save_path, filename1), frame1)
        cv2.imwrite(os.path.join(save_path, filename2), frame2)
        print(f"📸 ESP Triggered capture: {filename1}, {filename2}")

        # --- ADD DISTRACTION ---
        add_distraction()

    frame_id += 1
    prev_byte = byte_in
    

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap_front.release()
cap_back.release()
cv2.destroyAllWindows()
ser.close()
