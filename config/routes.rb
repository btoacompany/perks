Rails.application.routes.draw do
  root 'top#index'

  # item front
  get	'/items'			=> 'items#index'
  get	'/items/:id'			=> 'items#details'

  # item tools
  get	'/tools/items'			=> 'items#view'
  get	'/tools/items/create'		=> 'items#create'
  post	'/tools/items/create_complete'	=> 'items#create_complete'
  get	'/tools/items/edit/:id'		=> 'items#edit'
  post	'/tools/items/edit_complete'	=> 'items#edit_complete'	
  post	'/tools/items/delete_complete'	=> 'items#delete'

  # maker tools
  get	'/tools/suppliers'		    => 'suppliers#index'
  get	'/tools/suppliers/create'	    => 'suppliers#create'
  get	'/tools/suppliers/edit/:id'	    => 'suppliers#edit'
  post	'/tools/suppliers/create_complete'  => 'suppliers#create_complete'
  post	'/tools/suppliers/edit_complete'    => 'suppliers#edit_complete'	
  post	'/tools/suppliers/delete_complete'  => 'suppliers#delete'
end
