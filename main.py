from flask import Flask
import random, math


def isColorLight(rgb=[0,128,255]):
    [r, g, b] = rgb
    hsp = math.sqrt(0.299 * (r * r) + 0.587 * (g * g) + 0.114 * (b * b))
    if hsp > 127.5:
        return True
    else:
        return False


app = Flask(__name__)
num = random.randint(0, 999)
bg_color_vals = [random.randint(0, 255), random.randint(0, 255), random.randint(0, 255)]
bg_color = "#" + "".join(hex(x)[2:] for x in bg_color_vals)
fg_color = "#000" if isColorLight(rgb=bg_color_vals) else "#fff"


@app.route('/')
def hello():
    result = """
        <html>
        <body>
            <div style="
                background-color:{};
                color: {};
                width: 200px;
                text-align: center;
                font-size: 80px;
            ">
                {:0>3d}
            </div>
        </body>
        </html>
    """
    result = result.format(bg_color, fg_color, num)
    return result


if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=8080)


