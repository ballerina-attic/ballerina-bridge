import time

from flask import Flask


app = Flask(__name__)


@app.route('/order')
def kasun():
    return 'Hello from Order: microservice.'

if __name__ == "__main__":
    app.run(host="0.0.0.0", threaded=True)
