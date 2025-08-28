class RestaurantController < ApplicationController
  before_action :set_restaurant, only: %i[show update destroy]

  def index
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 10

    restaurants = Restaurant.includes(menus: :menu_menu_items)
                            .limit(per_page)
                            .offset((page - 1) * per_page)
                            .order(created_at: :desc)

    render json: restaurants, status: :ok
  end

  def show
    render json: @restaurant, status: :ok
  end

  def create
    restaurant = Restaurant.new(restaurant_params)

    unless restaurant.valid?
      return render json: { errors: restaurant.errors.full_messages }, status: :unprocessable_content
    end

    restaurant.save!

    render json: restaurant, status: :created
  end

  def update
    unless @restaurant.update(restaurant_params)
      return render json: { errors: @restaurant.errors.full_messages }, status: :unprocessable_content
    end

    render json: @restaurant, status: :ok
  end

  def destroy
    @restaurant.destroy!

    render json: { message: "Restaurant deleted successfully" }, status: :ok
  end

  private

  def restaurant_params
    params.permit(:name, :description, :address_line_1, :address_line_2, :city, :state, :zip_code,
                  :phone_number, :email, :website_url, :logo_url, :cover_image_url)
  end

  def set_restaurant
    @restaurant = Restaurant.includes(menus: :menu_menu_items).find_by(id: params[:id])

    if @restaurant.nil?
      return render json: { error: "Restaurant not found" }, status: :not_found
    end
  end
end
