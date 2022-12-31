#!/usr/bin/env python

import base64
from io import BytesIO
from random import randrange

from flask import Flask
from matplotlib.figure import Figure
from shapely.geometry import Point, Polygon

app = Flask(__name__)


@app.route("/")
def shape():
    points = []
    for i in range(10):
        x = randrange(1, 100)
        y = randrange(1, 100)
        points.append(Point(x, y))

    polygon = Polygon([[p.x, p.y] for p in points])
    shape = polygon.convex_hull

    x, y = shape.exterior.xy

    fig = Figure()
    ax = fig.subplots()
    ax.plot(x, y, c="blue")

    buf = BytesIO()
    fig.savefig(buf, format="png")
    data = base64.b64encode(buf.getbuffer()).decode("ascii")

    return f"<img src='data:image/png;base64,{data}'/><br />{shape.wkt}"


def run():
    app.run(host="0.0.0.0")


if __name__ == "__main__":
    app.run()
