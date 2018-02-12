//for tracking pv
$(function() {
	var page_path = window.location.pathname;

	var arr_track_pages = [
	  	/\/profile$/
	  	,/\/profile\/articles$/
	  	,/\/profile\/given$/
	  	,/\/company\/article\/\d+$/
	];

	var ctr = arr_track_pages.length;

	for(var i=0; i < ctr; i++) {
	  	if(arr_track_pages[i].test(page_path)) {
		  	$.ajax({
			    type: "POST",
			    url: "/tracking/pv",
			    data: { 'page_path': page_path }
			});
		  	break;
	  	}
	}

});