Rails.application.routes.draw do

  get 'pages/:id' => 'pages#show'
  root 'pages#show'

  mount Anecdote::Engine => "/anecdote"
end
