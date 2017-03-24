var i = 0;
$(function(){
	var addPost = function(){
	  $(".new_post:first"). 
	    clone(). 
	    removeClass("display_hidden").
	      find('#description').  
	        attr('name', 'new_post[][description]').
	        prop('disabled', false).
	          end().
	            appendTo("#new_posts");
	}
  $("#addItem").on("click", addPost);
  	addPost();
  	$(".remove_div").first().remove();
});

