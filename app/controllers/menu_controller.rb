class MenuController < ApplicationController
  before_action :set_restaurant, only: %i[index create]
  before_action :set_menu, only: %i[show update destroy]

  def index
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 10

    menus = @restaurant.menus.includes(:menu_items)
                             .limit(per_page)
                             .offset((page - 1) * per_page)
                             .order(created_at: :desc)

    render json: menus, status: :ok
  end

  def show
    render json: @menu, status: :ok
  end

  def create
    menu = Menu.new(menu_params)
    menu.restaurant = @restaurant

    unless menu.valid?
      return render json: { errors: menu.errors.full_messages }, status: :unprocessable_content
    end

    menu.save!

    render json: menu, status: :created
  end

  def update
    unless @menu.update(menu_params)
      return render json: { errors: @menu.errors.full_messages }, status: :unprocessable_content
    end

    render json: @menu, status: :ok
  end

  def destroy
    @menu.destroy!

    render json: { message: "Menu deleted successfully" }, status: :ok
  end

  private

  def menu_params
    params.permit(:name, :description, :category, :active, :starts_at, :ends_at, :restaurant_id)
  end

  def set_restaurant
    @restaurant = Restaurant.includes(:menus).find_by(id: params[:restaurant_id])

    if @restaurant.nil?
      return render json: { error: "Restaurant not found" }, status: :not_found
    end
  end

  def set_menu
    @menu = Menu.includes(:menu_items).find_by(id: params[:id], restaurant_id: params[:restaurant_id])

    if @menu.nil?
      return render json: { error: "Menu not found" }, status: :not_found
    end

    @restaurant = @menu.restaurant
  end
end
