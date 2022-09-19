from flask import Flask, session, url_for
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, BooleanField, SubmitField, HiddenField
from wtforms.validators import InputRequired, EqualTo, Length
import random, math


def isColorLight(rgb=[0,128,255]):
    [r, g, b] = rgb
    hsp = math.sqrt(0.299 * (r * r) + 0.587 * (g * g) + 0.114 * (b * b))
    if hsp > 127.5:
        return True
    else:
        return False


app = Flask(__name__)
app.secret_key = "SecretKey"
num = random.randint(0, 999)
bg_color_vals = [random.randint(0, 255), random.randint(0, 255), random.randint(0, 255)]
bg_color = "#" + "".join(hex(x)[2:] for x in bg_color_vals)
fg_color = "#000" if isColorLight(rgb=bg_color_vals) else "#fff"


class SessionForm(FlaskForm):
    open_session = SubmitField("Open Session")
    close_session = SubmitField("Close Session")


@app.route('/', methods=["GET", "POST"])
def hello():
    form = SessionForm()

    if form.open_session.data:
        session["token"] = "".join([hex(random.randint(0,15))[2:] for x in range(32)])

    if form.close_session.data:
        session.clear()

    if "token" in session:
        session_html = """
        <form method="POST" action="{}">{} {}<div>Token: {}</div></form>
        """
        session_html = session_html.format(url_for("hello"), form.hidden_tag(), form.close_session(), session["token"])
    else:
        session_html = """
        <form method="POST" action="{}">{}{}</form>
        """
        session_html = session_html.format(url_for("hello"), form.hidden_tag(),  form.open_session())

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
            {}
        </body>
        </html>
    """
    result = result.format(bg_color, fg_color, num, session_html)
    return result


@app.route('/healthcheck')
def health_check():
    return "Alive"


if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=8080)


