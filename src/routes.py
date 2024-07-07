# module routes

# flask
from flask import render_template, request, url_for, redirect

# local
from common import *

@app.route('/')
def index():
    return render_template('index.html', background=True, is_index=True)


@app.route('/about')
def about():
    return render_template('about.html', background=True, is_index=True)


@app.route('/blog')
def blog():
    return render_template('blog.html', background=True)


@app.route('/projects')
def projects():
    return render_template('projects.html', background=True)


@app.route('/contact_me')
def contact_me():
    return render_template('contact_me.html', background=True)

