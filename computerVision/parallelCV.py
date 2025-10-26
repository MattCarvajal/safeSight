"""import cv2
import dlib
import numpy as np
import os
import time
from datetime import datetime
from PIL import Image
from ultralytics import YOLO
import serial, time

# Initiate serial 
ser = serial.Serial('/dev/serial0', 115200, timeout=1)

# Load the detector and predictor
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")   

# Green light and attentive booleans
greenLight = False
attentive = False

def send_bit(b):
    ser.write(bytes([b]))
    ser.flush()
    print("Sent", b)

def receive_bit():
    if ser.in_waiting > 0:
        byte = ser.read(1)
        return int.from_bytes(byte, "big")
    return None

# Load a pretrained YOLOv8n model
model = YOLO('best_traffic_nano_yolo.pt')

# path for pictures
save_path = "/home/mahyar/Desktop/test_photos"
os.makedirs(save_path, exist_ok = True)

looking_down = False # tack the look down state

def estimate_head_pose(image):
    global looking_down
    global attentive
    global greenLight
    
    # Convert image to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Detect faces
    faces = detector(gray)
    
    for face in faces:
        # Get facial landmarks
        landmarks = predictor(gray, face)
        
        # Calculate pitch angle
        left_eye = np.array([landmarks.part(36).x, landmarks.part(36).y])
        right_eye = np.array([landmarks.part(45).x, landmarks.part(45).y])
        nose_tip = np.array([landmarks.part(30).x, landmarks.part(30).y])
        
        # Calculate the vertical displacement of the nose tip relative to the eyes
        eye_midpoint = (left_eye + right_eye) / 2
        vertical_displacement = nose_tip[1] - eye_midpoint[1]
        
        # Determine if looking up or down based on vertical displacement
        if vertical_displacement > 40:  # Adjust this threshold as needed
            print(f"Looking down: {vertical_displacement}")

            # look down take the picture
           # if not looking_down:
               # filename = f"driver_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
               # filepath = os.path.join(save_path, filename)
                #cv2.imwrite(filepath, image)
                #print(f"📸 Photo saved: {filepath}")
               # looking_down = True  # mark as captured so we don't spam
            
            print("Driver distracted")
            attentive = False
            #send_bit(0x00)



        elif vertical_displacement < 10:  # Adjust this threshold as needed
            print(f"Looking up: {vertical_displacement}")
            looking_down = False
            attentive = False
            print("Driver Distracted")
            #send_bit(0x00)
        else:
            print(f"Looking straight: {vertical_displacement}")
            looking_down = False
            attentive = True
            print("Driver attentive")
            #send_bit(0x01)
        
        # Draw facial landmarks for visualization
        for n in range(0, 68):
            x = landmarks.part(n).x
            y = landmarks.part(n).y
            cv2.circle(image, (x, y), 1, (0, 255, 0), -1)
        
    return image

# Example usage
cap = cv2.VideoCapture("/dev/v4l/by-id/usb-Ruision_UVC_Camera_20200416-video-index0")
cap.set(cv2.CAP_PROP_FPS, 30)
 
# open a video file or start a video stream 2
cap2 = cv2.VideoCapture("/dev/v4l/by-id/usb-046d_Brio_100_2525APPPKBE8-video-index0")  # replace with 0 for webcam
cap2.set(cv2.CAP_PROP_FPS, 30)



if not cap.isOpened() or not cap2.isOpened():
    print("Error: One or both cameras could not be opened.")
    exit()

frame_id = 0
skip = 30

# --- Main Loop ---
while True:
    ret1, frame1 = cap.read()
    ret2, frame2 = cap2.read()

    if ret1:
        frame1 = estimate_head_pose(frame1)
        cv2.imshow("Head Pose Camera", frame1)

    if ret2:
       
        if frame_id % skip == 0:
            results = model(frame2)

            for r in results:
                
                # Only save if there are detections
                if len(r.boxes) > 0:
                    frame2 = r.plot()  # Annotated image
                    filename2 = f"traffic_detected_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
                    filepath = os.path.join(save_path, filename2)
                    cv2.imwrite(filepath, frame2)
                    print(f"📸 Saved annotated traffic light image: {filepath}")
                else:
                    print("No traffic light detected.")

                    
        cv2.imshow("YOLO Camera", frame2)

        frame_id += 1

    if (greenLight == True & attentive == True):
        send_bit(0x11)
    elif (greenLight == False & attentive == True):
        send_bit(0x01)
    elif (greenLight == True & attentive == False):
        send_bit(0x10)
    else:
        send(0x00)

    # wait for byte and take a picture accordingly
    if (receive_bit()):
            if not looking_down:
                filename = f"driver_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
                filepath = os.path.join(save_path, filename)
                filename2 = f"traffic_detected_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
                filepath2 = os.path.join(save_path, filename2)
                cv2.imwrite(filepath, image)
                cv2.imwrite(filepath2, frame2)
                print(f"📸 Photo saved: {filepath}")
                looking_down = True  # mark as captured so we don't spam

    # Quit when 'q' is pressed
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# --- Cleanup ---
cap.release()
cap2.release()
cv2.destroyAllWindows()
"""

import cv2
import dlib
import numpy as np
import os
import time
from datetime import datetime
from ultralytics import YOLO
import serial

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
    global looking_down, attentive
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = detector(gray)

    for face in faces:
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

print("✅ System ready. Listening for ESP signal...")

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
        send_bit(0x11)
    elif not greenLight and attentive:
        send_bit(0x01)
    elif greenLight and not attentive:
        send_bit(0x10)
    else:
        send_bit(0x00)

    # --- Listen for ESP command ---
    byte_in = receive_bit()
    if byte_in == 1 and ret1 and ret2:
        filename1 = f"front_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
        filename2 = f"rear_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
        cv2.imwrite(os.path.join(save_path, filename1), frame1)
        cv2.imwrite(os.path.join(save_path, filename2), frame2)
        print(f"📸 ESP Triggered capture: {filename1}, {filename2}")

    frame_id += 1

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap_front.release()
cap_back.release()
cv2.destroyAllWindows()
ser.close()
