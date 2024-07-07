# module common

# system
import os

# flask
from flask import Flask

app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(24)           # generate random byte string
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024 # 16 MB


