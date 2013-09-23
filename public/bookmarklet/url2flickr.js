;(function() {
    var DEV = false;
    var HOST;

    if (DEV) {
        HOST = 'http://localhost:5000/';
    } else {
        HOST = 'http://storehub.herokuapp.com/';
    }


    function loadScript(url, callback){
        var script = document.createElement("script");
        script.type = "text/javascript";
        script.slave = HOST + "proxy.html";

        if (script.readyState){  //IE
            script.onreadystatechange = function(){
                if (script.readyState == "loaded" ||
                        script.readyState == "complete"){
                    script.onreadystatechange = null;
                    callback();
                }
            };
        } else {  //Others
            script.onload = function(){
                callback();
            };
        }

        script.src = url;
        document.getElementsByTagName("head")[0].appendChild(script);
    }


    loadScript("https://raw.github.com/vieron/storehub/master/public/js/xdomain.min.js", function(){
        loadScript("https://ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js", function(){
            var styles = 'position:fixed; z-index: 99999999; top: 0; right: 0; background: #000; color: #FFF; display: none; padding: 20px; font-size: 18px;';
            var $loading = $('<div style="'+ styles +'">capturing...</div>');
            $loading.appendTo(document.body).fadeIn();

            $.ajax(HOST + "2flickr.json", {
                data: {
                    url: window.top.location.href
                },
                type: 'get',
                dataType: 'json',
                headers: { "auth-token": "lhafleg57aglat:hdo3fi2erKie41hg5osg543etj" }
            }).success(function(res) {
                // console.log(res);
                $loading.html('<a href="'+res.url+'" target="_blank" style="color: #FFF!important; text-decoration: underline; font-size: 20px;">view image</a>');
                setTimeout(function() {
                    $loading.fadeOut(function() {
                        $(this).remove();
                    });
                }, 15 * 1000);
            });
        });
    });



})();
