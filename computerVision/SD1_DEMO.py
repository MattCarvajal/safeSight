import cv2
import dlib
import numpy as np
import serial, time

# Initiate serial 
ser = serial.Serial('/dev/serial0', 115200, timeout=1)

# Load the detector and predictor
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")

def send_bit(b):
    ser.write(bytes([b]))
    ser.flush()
    print("Sent", b)

def estimate_head_pose(image):
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
        if vertical_displacement > 50:  # Adjust this threshold as needed
            print(f"Looking down: {vertical_displacement}")
            print("Buzzer ON")
            send_bit(0x01)
        elif vertical_displacement < 10:  # Adjust this threshold as needed
            print(f"Looking up: {vertical_displacement}")
            print("Buzzer ON")
            send_bit(0x01)
        else:
            print(f"Looking straight: {vertical_displacement}")
            print("Buzzer OFF")
            send_bit(0x00)
        
        # Draw facial landmarks for visualization
        for n in range(0, 68):
            x = landmarks.part(n).x
            y = landmarks.part(n).y
            cv2.circle(image, (x, y), 1, (0, 255, 0), -1)
        
    return image

# Example usage
cap = cv2.VideoCapture(0)
while True:
    success, img = cap.read()
    if success:
        img = estimate_head_pose(img)
        cv2.imshow("Image", img)
        if cv2.waitKey(1) & 0xFF == ord("q"):
            break
cap.release()
cv2.destroyAllWindows()
