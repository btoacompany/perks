Rails.application.routes.draw do
  root 'users#index'
  
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
  get	'/tools/login'		      => 'admins#login'
  post	'/tools/login/complete'	      => 'admins#login_complete'
  get	'/tools/logout'		      => 'admins#logout'
  get	'/company/login'	      => 'company#login'
  post	'/company/login/complete'     => 'company#login_complete'
  get	'/company/logout'	      => 'company#logout'

  # registration
  get	'/tools/register'	      => 'admins#create'
  post	'/tools/register/complete'    => 'admins#create_complete'
  get	'/company/register'	      => 'company#create'
  post	'/company/register/complete'  => 'company#create_complete'
  get	'/update'		      => 'users#update'
  post	'/update/complete'	      => 'users#update_complete', :as => 'user'

  # company
  get	'/company'			    => 'company#index'
  get	'/company/details'		    => 'company#details'
  get	'/company/edit'			    => 'company#edit'
  post	'/company/edit/complete'	    => 'company#edit_complete'
  get	'/company/employees'		    => 'company#employees'
  get	'/company/employees/add'	    => 'company#add_employees'
  post	'/company/employees/add/complete'   => 'company#add_employees_complete'
  get	'/company/employees/edit/:user_id'  => 'company#edit_employees'
  post	'/company/employees/edit/complete'  => 'company#edit_employees_complete'
  post	'/company/employees/delete'	    => 'company#delete_employees'
  get	'/company/rewards'		    => 'company#rewards'
  get	'/company/rewards/add'		    => 'company#add_rewards'
  post	'/company/rewards/add/complete'	    => 'company#add_rewards_complete'
  get	'/company/rewards/edit/:reward_id'  => 'company#edit_rewards'
  post	'/company/rewards/edit/complete'    => 'company#edit_rewards_complete'
  post	'/company/rewards/delete'	    => 'company#delete_rewards'
  get	'/company/rewards/request'	    => 'company#rewards_request'
  post	'/company/rewards/request/action'   => 'company#rewards_request_action'

  # users
  get	'/user'			    => 'users#index'
  post	'/user/give_points'	    => 'users#give_points'
  post	'/user/give_comments'	    => 'users#give_comments'
  post	'/user/give_kudos'	    => 'users#give_kudos'
  get	'/profile'		    => 'users#profile'
  get	'/rewards'		    => 'users#rewards'
  post	'/rewards/request'	    => 'users#rewards_request'
  get	'/rewards/status'	    => 'users#rewards_status'
  post	'/rewards/cancel'	    => 'users#rewards_cancel'

  # admin
  get	'/tools/admin/edit/:id'	      => 'admins#edit'
  get	'/tools/admin/edit/complete'  => 'admins#edit_complete'
end
