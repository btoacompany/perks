Rails.application.routes.draw do
  root 'top#index'
  
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
  get	'/update/complete'	      => 'users#update_complete', :as => 'user'

  # company
  get	'/company'			    => 'company#index'
  get	'/company/details'		    => 'company#details'
  get	'/company/edit'			    => 'company#edit'
  post	'/company/edit/complete'	    => 'company#edit_complete'
  get	'/company/employees'		    => 'company#employees'
  get	'/company/employees/add'	    => 'company#add_employees'
  post	'/company/employees/add/complete'   => 'company#add_employees_complete'
  post	'/company/employees/remove'	    => 'company#remove_employees'

  # users
  get	'/edit'			    => 'users#edit'
  post	'/edit/complete'	    => 'users#edit_complete'

  # item front
  get	'/items'			=> 'items#index'
  get	'/items/:id'			=> 'items#details'

  # admin
  get	'/tools/admin/edit/:id'	      => 'admins#edit'
  get	'/tools/admin/edit/complete'  => 'admins#edit_complete'

  # item tools
  get	'/tools/items'			=> 'items#view'
  get	'/tools/items/create'		=> 'items#create'
  post	'/tools/items/create_complete'	=> 'items#create_complete'
  get	'/tools/items/edit/:id'		=> 'items#edit'
  post	'/tools/items/edit_complete'	=> 'items#edit_complete'	
  post	'/tools/items/delete_complete'	=> 'items#delete'

  # vendor tools
  get	'/tools/vendors'		  => 'vendors#index'
  get	'/tools/vendors/create'		  => 'vendors#create'
  get	'/tools/vendors/edit/:id'	  => 'vendors#edit'
  post	'/tools/vendors/create_complete'  => 'vendors#create_complete'
  post	'/tools/vendors/edit_complete'	  => 'vendors#edit_complete'	
  post	'/tools/vendors/delete_complete'  => 'vendors#delete'
end
