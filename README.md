# Sinatra+Heroku+PhantomJS

## Installation

### For phantom and ruby on heroku*

heroku create --buildpack git://github.com/ddollar/heroku-buildpack-multi.git
git push heroku master
heroku open

heroku config:add LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib:/app/vendor/phantomjs/lib
heroku config:add PATH=bin:vendor/bundle/ruby/1.9.1/bin:/usr/local/bin:/usr/bin:/bin:/app/vendor/phantomjs/bin

### For Dropbox

Create a new app in: https://www.dropbox.com/developers/apps

** Locally **

1. create .env put these lines in:
    1. DROPBOX_KEY=key_from_before
    2. DROPBOX_SECRET=secret_from_before
    2. SEND_TO_DROPBOX_TOKEN=the_token_you_want    (used to upload captures to dropbox)

2. `foreman start`
6. `open http://localhost:5000` in the same browser you used to sign up the new dropbox account
7. It will take you to dropbox, authorize the app. You will be redirected back and it will tell you the new DROPBOX_TOKEN
8. put DROPBOX_TOKEN=that_token in your .env file
9. restart foreman, and enjoy


** On Heroku **

1. `heroku config:add DROPBOX_KEY=app_key`
2. `heroku config:add DROPBOX_SECRET=app_secret`

or

1. `heroku config:add $(cat .env)`
2. `heroku open`
3. It will take you to dropbox, authorize the app. You will be redirected back and it will tell you the new DROPBOX_TOKEN
9. `heroku config add DROPBOX_TOKEN=that_token`


## Usage

http://localhost:5000/2dropbox.json?url=http://vieron.net
http://localhost:5000/png.json?url=http://vieron.net
