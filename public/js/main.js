$(function(){

    $(function(){
        $('#btn_links').click(function(){
          var url = $('#url').val();
          $.getJSON(links_api+'?url='+url, function(image){
            console.log(image);
            var $result = $('#results');
            $result.html('<img src="' + image.data + '" />');
          });
        });




        $('#get_inspiration').click(function(){
          $.getJSON('/inscrapper.json', function(res){
            var $result = $('#results');
            console.log('res', res);
            // $results.html(res);
          });
        });


    });
});
