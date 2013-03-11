$(function() {
    $('tr.history p').hide();    
    $('.openHistory').click(function(){
        if($(this).parent().parent().hasClass('visibleHistory')){
            $(this).parent().siblings('td').children('p').hide();
            $(this).parent().parent().removeClass('visibleHistory');
        }else{
            $(this).parent().siblings('td').children('p').show();
            $(this).parent().parent().addClass('visibleHistory')
        }
        console.log($(this).parent().parent());
    });
});