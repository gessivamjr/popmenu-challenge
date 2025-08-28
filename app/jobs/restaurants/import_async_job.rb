class Restaurants::ImportAsyncJob < ApplicationJob
  queue_as :default

  def perform(restaurant_id)
    restaurant = Restaurant.find(restaurant_id)
  end
end
