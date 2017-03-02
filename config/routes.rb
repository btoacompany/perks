Rails.application.routes.draw do
  # for landing
  root to: 'landing#index'

  get	'/price'	    => 'landing#price'
  get	'/privacy'	    => 'landing#privacy'
  get	'/terms'	    => 'landing#terms'
  get	'/integration/slack'	  => 'landing#slack'
  get	'/integration/slack/add'  => 'landing#slack_add'
  get '/contact' => 'landing#contact'
  post '/contact/complete' => 'landing#contact_mail'

  # for testing
  get	'/tests'		  => 'tests#index'
  get	'/tests/create'		  => 'tests#create'
  post	'/tests/create/complete'  => 'tests#create_complete'
  get	'/tests/edit/:id'	  => 'tests#edit'
  post	'/tests/edit/complete'	  => 'tests#edit_complete'

  # login
  get	'/login'		      => 'users#login'
  post	'/login/complete'	      => 'users#login_complete'
  get	'/logout'		      => 'users#logout'
  get	'/company/login'	      => 'company#login'

  # registration
  get	'/company/register'	      => 'company#create'
  post	'/company/register/complete'  => 'company#create_complete'
  get	'/update'		      => 'users#update'
  post	'/update/complete'	      => 'users#update_complete', :as => 'user'
  get	'/invite'		      => 'users#invite'
  post	'/invite/complete'	      => 'users#invite_complete'

  # company
  get	'/company'			    => 'company#index'
  get	'/company/details'		    => 'company#details'
  get	'/company/edit'			    => 'company#edit'
  post	'/company/edit/complete'	    => 'company#edit_complete'
  get '/company/customize' => 'company#customize'
  post '/company/customize/update' => 'company#customize_update'
  get	'/company/employees'		    => 'company#employees'
  post '/company/employees' => 'company#employees'
  post  '/company/employees/edit/complete'  => 'company#edit_employees_complete'
  post  '/company/employees/delete'     => 'company#delete_employees'
  get '/company/employees/register' => 'company#register_employees'
  post '/company/employees/import_users_by_csv'      => 'company#import_users_by_csv'
  post '/company/employees/create_department_and_team_by_csv' => 'company#create_department_and_team_by_csv'
  post '/company/employees/export_csv_format_create_user' => 'company#export_csv_format_create_user'
  post '/company/employees/export_csv_format_create_department_and_team' => 'company#export_csv_format_create_department_and_team'
  post 'company/employees/register/complete' => 'company#register_employees_complete'
  get	'/company/employees/add'	    => 'company#add_employees'
  post	'/company/employees/add/complete'   => 'company#add_employees_complete'
  get	'/company/employees/edit/:user_id'  => 'company#edit_employees'
  get	'/company/rewards'		    => 'company#rewards'
  get	'/company/rewards/add'		    => 'company#add_rewards'
  post	'/company/rewards/add/complete'	    => 'company#add_rewards_complete'
  get	'/company/rewards/edit/:reward_id'  => 'company#edit_rewards'
  post	'/company/rewards/edit/complete'    => 'company#edit_rewards_complete'
  post	'/company/rewards/delete'	    => 'company#delete_rewards'
  get	'/company/rewards/request'	    => 'company#rewards_request'
  post	'/company/rewards/request/action'   => 'company#rewards_request_action'
  # get	'/company/bonus'		    => 'company#bonus'
  # get	'/company/bonus/add'		    => 'company#add_bonus'
  # post	'/company/bonus/add/complete'	    => 'company#add_bonus_complete'
  # get	'/company/bonus/edit/:bonus_id'     => 'company#edit_bonus'
  # post	'/company/bonus/edit/complete'	    => 'company#edit_bonus_complete'
  # post	'/company/bonus/delete'		    => 'company#delete_bonus'
  post	'/company/employees/make_admin'	    => 'company#make_admin'
  post	'/company/employees/make_user'	    => 'company#make_user'
  post	'/company/employees/make_manager'   => 'company#make_manager'
  post	'/company/employees/make_non_manager' => 'company#make_non_manager'
  get '/company/employees/edit_email' => 'company#edit_email'
  post '/company/employees/update' => 'company#update_email'

  # users
  get	'/user'			    => 'users#index'
  post	'/user/give_points'	    => 'users#give_points'
  post	'/user/give_points_slack'   => 'users#give_points_slack'
  post	'/user/give_comments'	    => 'users#give_comments'
  post	'/user/give_kudos'	    => 'users#give_kudos'
  post	'/user/give_bonus'	    => 'users#give_bonus'
  post	'/user/delete_post'	    => 'users#delete_post'
  post	'/user/delete_comment'	    => 'users#delete_comment'
  get	'/profile'		    => 'users#profile'
  get	'/profile/given'	    => 'users#given'
  get	'/rewards'		    => 'users#rewards'
  post	'/rewards/request'	    => 'users#rewards_request'
  get	'/rewards/status'	    => 'users#rewards_status'
  post	'/rewards/cancel'	    => 'users#rewards_cancel'
  get	'/bonus'		    => 'users#bonus'

  #analytics
  get	'analytics'		=> 'analytics#overall'
  post	'analytics'		=> 'analytics#overall'
  get	'analytics/receiver'	=> 'analytics#index'
  post	'analytics/receiver'	=> 'analytics#index'
  get	'analytics/giver'	=> 'analytics#giver'
  post	'analytics/giver'	=> 'analytics#giver'
  get	'analytics/hashtag'	=> 'analytics#hashtag'
  post	'analytics/hashtag'	=> 'analytics#hashtag'
  get 'analytics/hashtag/points' => 'analytics#hashtagpoints'
  post 'analytics/hashtag/points' => 'analytics#hashtagpoints'
  get	'analytics/hashtag/all' => 'analytics#allhashtag'
  post	'analytics/hashtag/all' => 'analytics#allhashtag'
  get 'analytics/hashtag/all/points' => 'analytics#allhashtagpoints'
  post  'analytics/hashtag/all/points' => 'analytics#allhashtagpoints'
  get	'analytics/user/:id'	=> 'analytics#user'
  post	'analytics/user/:id'	=> 'analytics#user'
  get 'analytics/user/:id/points'  => 'analytics#userpoints'
  post  'analytics/user/:id/points'  => 'analytics#userpoints'
  get 'analytics/user/:id/given' => 'analytics#usergiven'
  get 'analytics/user/:id/given' => 'analytics#usergiven'
  get 'analytics/user/:id/received' => 'analytics#userreceived'

  #facebook auth
  get	'auth/facebook', as: "auth_provider"
  get	'auth/facebook/callback',to: "users#fb_auth"

  #forget password
  get	'/forgot_password'		  => 'users#forgot_password'
  post	'/forgot_password/submit'	  => 'users#forgot_password_submit'

  #ios register
  post	'/device/ios/register'		  => 'device#register_ios'
  post	'/device/ios/unregister'	  => 'device#unregister_ios'
end
