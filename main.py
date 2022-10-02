from flask import Flask, session, url_for, jsonify, request
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, BooleanField, SubmitField, HiddenField
from wtforms.validators import InputRequired, EqualTo, Length
import random, math, os
import sqlalchemy
from sqlalchemy import create_engine
from sqlalchemy import Table, Column, Integer, String, MetaData, inspect
from sqlalchemy.sql import text
from sqlalchemy.orm import sessionmaker

session_memory = {

}

metadata = MetaData()
books = Table('book', metadata,
        Column('id', Integer, primary_key=True),
        Column('title', String(25))
    )



def isColorLight(rgb=[0,128,255]):
    [r, g, b] = rgb
    hsp = math.sqrt(0.299 * (r * r) + 0.587 * (g * g) + 0.114 * (b * b))
    if hsp > 127.5:
        return True
    else:
        return False


def abort_ro(*args, **kwargs):
    raise ValueError("You are trying to write with a read-only session. this is not allowed")


def create_session(readonly=True):
    eng = engine_ro if readonly else engine
    Session = sessionmaker(bind=eng, autoflush=False, autocommit=False)
    session = Session()
    if readonly:
        session.flush = abort_ro  # now it won't flush!
        session.commit = abort_ro

    return session


app = Flask(__name__)
app.secret_key = "SecretKey"
num = random.randint(0, 999)
bg_color_vals = [random.randint(0, 255), random.randint(0, 255), random.randint(0, 255)]
bg_color = "#" + "".join(hex(x)[2:].zfill(2) for x in bg_color_vals)
fg_color = "#000" if isColorLight(rgb=bg_color_vals) else "#fff"

app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('SQLALCHEMY_DATABASE_URI', 'sqlite:///site.db')
engine = create_engine(app.config['SQLALCHEMY_DATABASE_URI'])
if "mysql://" in app.config['SQLALCHEMY_DATABASE_URI']:
    engine.execute("CREATE DATABASE IF NOT EXISTS app")  # create db
    engine.execute("USE app")  # select new db
rs = engine.execute("SELECT table_name FROM information_schema.tables")
existing_tables = [row[0] for row in rs]
if "book" not in existing_tables:
    metadata.create_all(engine, checkfirst=True)

app.config['SQLALCHEMY_DATABASE_URI_READONLY'] = os.getenv('SQLALCHEMY_DATABASE_URI_READONLY', 'sqlite:///site.db')
engine_ro = create_engine(app.config['SQLALCHEMY_DATABASE_URI_READONLY'])

with engine.connect() as con:
    rs = con.execute("SELECT * FROM book")
    exists = False
    for row in rs:
        exists = True
        break
    if not exists:
        data = [
            {'id': 1, 'title': "The Hobbit"},
            {'id': 2, 'title': "The Silmarillion"}
        ]

        stmt = text("INSERT INTO book(id, title) VALUES(:id, :title)")

        for line in data:
            con.execute(stmt, **line)


@app.route("/books/add")
def add_book():
    data = {'title': request.args.get('title')}
    with create_session(readonly=False) as conn:
        conn.execute("USE app")
        st = text("INSERT INTO book(title) VALUES(:title)")
        conn.execute(st, data)
        conn.commit()
    return "success"


class SessionForm(FlaskForm):
    open_session = SubmitField("Open Session")
    close_session = SubmitField("Close Session")


@app.route('/', methods=["GET", "POST"])
def hello():
    form = SessionForm()

    if form.open_session.data:
        session["token"] = "".join([hex(random.randint(0,15))[2:] for x in range(32)])
        session_memory[session["token"]] = "" + "".join([hex(random.randint(0,15))[2:] for x in range(32)])

    if form.close_session.data:
        if session["token"] in session_memory:
            del session_memory[session["token"]]
        session.clear()

    if "token" in session:
        memory = "Not Found"
        if session["token"] in session_memory:
            memory = session_memory[session["token"]]
        session_html = """
        <form method="POST" action="{}">{} {}<div>Token: {}</div><div>Memory: {}</div></form>
        """
        session_html = session_html.format(url_for("hello"), form.hidden_tag(), form.close_session(),
                                           session["token"], memory)
    else:
        session_html = """
        <form method="POST" action="{}">{}{}</form>
        """
        session_html = session_html.format(url_for("hello"), form.hidden_tag(),  form.open_session())

    book_html = """<html>
            <body>
            {}
            </body>
        </html>"""

    list_html = ""
    with create_session() as conn:
        conn.execute("USE app")
        rs = conn.execute("SELECT * FROM book")
        for row in rs:
            list_html += "{}: {}<br />".format(row[0], row[1])
    book_html = book_html.format(list_html)

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
            {}
        </body>
        </html>
    """
    result = result.format(bg_color, fg_color, num, session_html, book_html)
    return result


@app.route('/alive')
def health_alive():
    return "OK"

@app.route('/ready')
def health_ready():
    return jsonify(
        backend='ready',
        db='ready',
        queue='ready'
    )


if __name__ == '__main__':
    app.run(
        debug=os.getenv('FLASK_DEBUG', True),
        host=os.getenv('FLASK_IP', "0.0.0.0"),
        port=os.getenv('FLASK_PORT', 8080))


