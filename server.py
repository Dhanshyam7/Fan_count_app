from flask import Flask, request, jsonify
import cv2, numpy as np, math, os

app = Flask(__name__)

def count_rotations(video_path):
    cap = cv2.VideoCapture(video_path)
    center_x, center_y = 320, 240
    total_angle_change = 0.0
    last_angle = None

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame = cv2.resize(frame, (640, 480))
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
        mask = cv2.inRange(hsv, np.array([140, 50, 100]), np.array([170, 255, 255]))
        contours, _ = cv2.findContours(mask, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

        if contours:
            c = max(contours, key=cv2.contourArea)
            (x, y), radius = cv2.minEnclosingCircle(c)
            if radius > 5:
                dx, dy = x - center_x, y - center_y
                angle = math.degrees(math.atan2(dy, dx))
                if last_angle is not None:
                    delta = angle - last_angle
                    if delta > 180: delta -= 360
                    elif delta < -180: delta += 360
                    total_angle_change += abs(delta)
                last_angle = angle

    cap.release()
    return total_angle_change / 360.0

@app.route('/upload', methods=['POST'])
def upload():
    if 'video' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400
    file = request.files['video']
    filepath = os.path.join('uploads', file.filename)
    os.makedirs('uploads', exist_ok=True)
    file.save(filepath)

    try:
        count = count_rotations(filepath)
        return jsonify({'rotations': round(count, 2)})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
