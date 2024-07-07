# module routes

# flask
from flask import render_template, request, url_for, redirect

# local
from common import *

@app.route('/')
def index():
    return render_template('index.html')


