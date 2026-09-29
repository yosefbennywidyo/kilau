Rails.application.routes.draw do
  get "/_ping", to: "health#ping"
  get "/", to: redirect("/posts", status: 303)
  resources :posts, only: [:index, :show, :new, :create, :edit, :update, :destroy]
end
