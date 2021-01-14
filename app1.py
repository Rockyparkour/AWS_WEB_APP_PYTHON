from flask import Flask, render_template

app = Flask(__name__)


@app.route("/home")
def hello():
    return render_template('index.html')


@app.route("/about")
def rakesh():
    name = "flask"
    return render_template('about.html', name1 = name)

app.run(debug=True)
