# This is the program that takes a picture and helps send it to the app over an HTPP connection
# SafeSight Senior Design
# Written by Matthew Carvajal

from flask import Flask, send_file, send_from_directory, jsonify
from picamera2 import Picamera2
import time
import os

app = Flask(__name__)
camera = Picamera2()
camera.configure(camera.create_still_configuration())

PHOTO_DIR = os.path.expanduser("~/Desktop/test_photos") # Directory for pictures

# /capture path to capture a picture
@app.route("/capture")
def capture():
    filename = "/tmp/latest.jpg"
    camera.start()
    time.sleep(1)  # let auto-exposure adjust
    camera.capture_file(filename)
    camera.stop()
    return send_file(filename, mimetype="image/jpeg")

# ping tester for establishing connection
@app.route("/ping")
def ping():
    return {"status": "ok"}

@app.route("/photos")
def list_photos():
    files = sorted(os.listdir(PHOTO_DIR))
    files = [f for f in files if f.lower().endswith((".jpg", ".jpeg", ".png"))]
    return jsonify({"photos": files})

@app.route("/photos/<filename>")
def get_photo(filename):
    return send_from_directory(PHOTO_DIR, filename)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080) #wlan0 on pi



