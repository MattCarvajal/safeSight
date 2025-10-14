import cv2
import numpy as np

def detect_traffic_light(frame):
    # Convert image to HSV
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)

    # Define color ranges in HSV
    red_lower1 = np.array([0, 100, 100])
    red_upper1 = np.array([10, 255, 255])
    red_lower2 = np.array([160, 100, 100])
    red_upper2 = np.array([179, 255, 255])

    yellow_lower = np.array([18, 100, 100])
    yellow_upper = np.array([35, 255, 255])

    green_lower = np.array([40, 50, 50])
    green_upper = np.array([90, 255, 255])

    # Create masks
    red_mask1 = cv2.inRange(hsv, red_lower1, red_upper1)
    red_mask2 = cv2.inRange(hsv, red_lower2, red_upper2)
    red_mask = cv2.bitwise_or(red_mask1, red_mask2)
    yellow_mask = cv2.inRange(hsv, yellow_lower, yellow_upper)
    green_mask = cv2.inRange(hsv, green_lower, green_upper)

    # Apply morphological filtering (reduce noise)
    kernel = np.ones((5, 5), np.uint8)
    red_mask = cv2.morphologyEx(red_mask, cv2.MORPH_OPEN, kernel)
    yellow_mask = cv2.morphologyEx(yellow_mask, cv2.MORPH_OPEN, kernel)
    green_mask = cv2.morphologyEx(green_mask, cv2.MORPH_OPEN, kernel)

    # Detect contours
    def find_color(mask, color_name, frame, color_bgr):
        contours, _ = cv2.findContours(mask, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
        detected = False
        for cnt in contours:
            area = cv2.contourArea(cnt)
            perimeter = cv2.arcLength(cnt, True)
            if perimeter == 0:
                continue
            circularity = 4 * np.pi * (area / (perimeter * perimeter))

            if area > 200 and 0.7 < circularity < 1.2: # Circular blob of color
                (x, y, w, h) = cv2.boundingRect(cnt)
                cv2.rectangle(frame, (x, y), (x + w, y + h), color_bgr, 2)
                cv2.putText(frame, color_name, (x, y - 10),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, color_bgr, 2)
                detected = True
        if detected:
            print(f"{color_name} light detected!")

    find_color(red_mask, "RED", frame, (0, 0, 255))
    find_color(yellow_mask, "YELLOW", frame, (0, 255, 255))
    find_color(green_mask, "GREEN", frame, (0, 255, 0))

    return frame


def main():
    cap = cv2.VideoCapture(0)  # 0 = webcam. Change to file path for video

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        output = detect_traffic_light(frame)
        cv2.imshow("Traffic Light Detection", output)

        # Press 'q' to quit
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
