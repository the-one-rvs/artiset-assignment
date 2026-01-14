from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello World from Flask!"

@app.route("/name/hi/<name>")
def name(name):
    return f"Hello {name}"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
