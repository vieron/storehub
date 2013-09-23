# Storehub

API to store images to flickr or dropbox.

Uses dropbox (dropbox-sdk gem) and flickr (flickraw gem)



## Local installation

### Flickr auth

- Register and app in Flickr
- Add secret and api_token to .env file
- Go to http://0.0.0.0:5000/2flickr.json
- Read console feedback:
	- Go to the auth page and confirm
	- Paste in terminal the number given by flickr
	- Prease Enter
- Continue reading the console:
	- Access_token and access_secret will be echoed. Add them to the .env file


### Dropbox auth

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



## Heroku Installation

heroku create --buildpack git://github.com/ddollar/heroku-buildpack-multi.git
heroku config:add $(cat .env)

git push heroku master
heroku open



## Usage

http://localhost:5000/2dropbox.json?url=http://vieron.net
http://localhost:5000/2flickr.json?url=http://vieron.net
http://localhost:5000/png.json?url=http://vieron.net
http://localhost:5000/captures


## Links
http://www.flickr.com/services/api/


## Bookmarklets

### Store image in flickr
javascript:(function(){document.head.appendChild(document.createElement('script')).src='http://0.0.0.0:5000/bookmarklet/url2flickr.js';})();