# module app

# system
import traceback

# flask
from flask import Flask

# local
from common import *
from routes import *


def app_startup():
    """Initialize and setup neccessary services and functionality.
    """
    pass


def app_shutdown():
    """Shutdown and free resources.
    """
    pass


if __name__ == "__main__":
    try:
        app_startup()
        app.run(debug=True)
    except:
        traceback.print_exc()
    finally:
        app_shutdown()


