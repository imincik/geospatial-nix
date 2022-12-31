#!/usr/bin/env python

import random
from flask import Flask
from shapely.geometry import Point

app = Flask(__name__)


@app.route('/')
def buffer():
    x = random.randrange(1, 10)
    y = random.randrange(1, 10)
    p = Point(x,y)

    return str(p.buffer(2))

def run():
   app.run(host="0.0.0.0")

if __name__=='__main__':
   app.run()
