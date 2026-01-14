from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello World from Flask!"

@app.route("/name/hello/<name>")
def test_message(name):
    return f"Hello {name}"


@app.route("/health")
def health():
    return jsonify(status="ok"), 200


@app.route("/live")
def liveness():
    return jsonify(status="alive"), 200


@app.route("/ready")
def readiness():
    return jsonify(status="ready"), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
