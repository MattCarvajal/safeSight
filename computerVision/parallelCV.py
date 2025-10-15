import cv2
import dlib
import numpy as np
from PIL import Image
from ultralytics import YOLO

# Load the detector and predictor
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")

# Load a pretrained YOLOv8n model
model = YOLO('best_traffic_nano_yolo.pt')

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
        elif vertical_displacement < 10:  # Adjust this threshold as needed
            print(f"Looking up: {vertical_displacement}")
        else:
            print(f"Looking straight: {vertical_displacement}")
        
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
                frame2 = r.plot()

        cv2.imshow("YOLO Camera", frame2)

        frame_id += 1

    # Quit when 'q' is pressed
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# --- Cleanup ---
cap.release()
cap2.release()
cv2.destroyAllWindows()