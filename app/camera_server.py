# This is the program that takes a picture and helps send it to the app over an HTPP connection
# SafeSight Senior Design
# Written by Matthew Carvajal

from flask import Flask, send_file
from picamera2 import Picamera2
import time

app = Flask(__name__)
camera = Picamera2()
camera.configure(camera.create_still_configuration())

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

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080) #wlan0 on pi



