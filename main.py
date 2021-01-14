from flask import Flask, render_template, request, session, redirect
from flask_sqlalchemy import SQLAlchemy
from flask_mail import Mail
import json
from datetime import datetime
from fusionauth.fusionauth_client import FusionAuthClient


with open('config.json', 'r') as c:
    params = json.load(c)["params"]
local_server = True

app = Flask(__name__)
app.secret_key = 'rakesh-key'

app.config.update(
    MAIL_SERVER='smtp.gmail.com',
    MAIL_PORT='465',
    MAIL_USE_SSL=True,
    MAIL_USERNAME=params['gmail-user'],
    MAIL_PASSWORD=params['gmail-password']
)
mail = Mail(app)

if local_server:
    app.config['SQLALCHEMY_DATABASE_URI'] = params['local_uri']
else:
    app.config['SQLALCHEMY_DATABASE_URI'] = params['prod_uri']

db = SQLAlchemy(app)


class Contacts(db.Model):
    serial_no = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    email = db.Column(db.String(120), nullable=False)
    phone_no = db.Column(db.String(12), nullable=False)
    message = db.Column(db.String(120), nullable=False)
    date = db.Column(db.String(12), nullable=True)


class Posts(db.Model):
    serial_no = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(80), nullable=False)
    tag_line = db.Column(db.String(120), nullable=False)
    slug = db.Column(db.String(120), nullable=False)
    content = db.Column(db.String(120), nullable=False)
    img_file = db.Column(db.String(25), nullable=False)
    date = db.Column(db.String(12), nullable=True)


@app.route("/")
def home():
    posts = Posts.query.filter_by().all()[0:3]
    return render_template('index.html', params=params, posts=posts)


@app.route("/about")
def about():
    return render_template('about.html', params=params)


@app.route("/login")
def login():
    return render_template('login.html', params=params)


@app.route("/editdelete/<string:serial_no>", methods=['GET', 'POST'])
def editdelete(serial_no):
    if request.method == 'POST':
        post = Posts.query.filter_by(serial_no=serial_no).first()
        return render_template('edit_delete.html', params=params, post=post, serial_no=serial_no, action_name="Edit Blog")


@app.route("/delete/<string:serial_no>", methods=['GET', 'POST'])
def delete(serial_no):
    if request.method == 'POST':
        post = Posts.query.filter_by(serial_no=serial_no).delete()
        db.session.commit()
        posts = Posts.query.all()
        return render_template('dashboard.html', params=params, posts=posts)


@app.route("/posts")
def posts():
    posts = Posts.query.all()
    return render_template('dashboard.html', params=params, posts=posts)


@app.route("/create", methods=['GET', 'POST'])
def create():

    if (request.method == 'POST'):
        title = request.form.get('title')
        tag_line = request.form.get('tag_line')
        slug = request.form.get('slug')
        content = request.form.get('content')
        img_file = request.form.get('img_file')


        entry = Posts(
            title=title,
            tag_line=tag_line,
            slug=slug,
            content=content,
            img_file=img_file,
            date=datetime.now()
        )

        db.session.add(entry)
        db.session.commit()
    return render_template('Add_Edit_Delete.html', params=params)


@app.route("/edit/<string:serial_no>", methods=['GET', 'POST'])
def edit(serial_no):
    act_name = request.form.get('index')

    '''  if (session['user'] != None and session['user'] == params['admin_user'] and session['pass'] == params['admin_password']):
        print(session['user'])'''
    if (act_name == '1'):
        action_name = "Create New Blog"
        return render_template('Add_Edit_Delete.html', params=params, action_name=action_name) 

    if (request.method == 'POST') and serial_no != '0':

        box_title = request.form.get('title')
        tag_line = request.form.get('tag_line')
        slug = request.form.get('slug')
        content = request.form.get('content')
        img_file = request.form.get('img_file')
        date = datetime.now()

        post = Posts.query.filter_by(serial_no=serial_no).first()
        post.title = box_title
        post.tag_line = tag_line
        post.slug = slug
        post.content = content
        post.img_file = img_file
        post.date = date

        db.session.add(post)
        db.session.commit()


    return redirect('/posts')

@app.route("/dashboard", methods=['GET', 'POST'])
def dashboard():
    session['user'] = request.form.get('uname')
    session['pass'] = request.form.get('pass')

    print(session['user'])
    if (session['user'] != None and session['user'] == params['admin_user'] and session['pass'] == params['admin_password']):
        posts = Posts.query.all()
        return render_template('dashboard.html', params=params, posts=posts)
    else:
        return render_template('login.html', params=params)

    # if request.method == 'POST':
    #     username = request.form.get('uname')
    #     userpass = request.form.get('pass')
    #     if (username == params['admin_user'] and userpass == params['admin_password']):
    #         session['user'] = username
    #         posts = Posts.query.all()
    #         return render_template('dashboard.html', params=params, posts=posts)
    #     else:
    #         return render_template('login.html', params=params)

@app.route("/contact", methods=['GET', 'POST'])
def contact():
    if (request.method == 'POST'):
        name = request.form.get('name')
        email = request.form.get('email')
        phone = request.form.get('phone')
        message = request.form.get('message')

        entry = Contacts(
            name=name,
            email=email,
            phone_no=phone,
            message=message,
            date=datetime.now()
        )

        db.session.add(entry)
        db.session.commit()

        mail.send_message('New message from blog' + name,
                          sender=email,
                          recipients=[params['gmail-user']],
                          body=message + "\n" + phone
                          )

    return render_template('contact.html', params=params)


@app.route("/post/<string:post_slug>", methods=['GET'])
def post(post_slug):

    post = Posts.query.filter_by(slug=post_slug).first()

    if (request.method == 'GET'):
        return render_template('post.html', params=params, post=post)


if __name__ == "__main__":
    app.run(debug=True)
