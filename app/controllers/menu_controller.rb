class MenuController < ApplicationController
  before_action :set_restaurant, only: %i[index create]
  before_action :set_menu, only: %i[show update destroy add_menu_item update_menu_item remove_menu_item]

  def index
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 10

    menus = @restaurant.menus.includes(:menu_menu_items)
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

  def add_menu_item
    menu_item = MenuItem.find_or_create_by(name: params[:name])
    result = @menu.add_menu_item(menu_item:, attributes: menu_menu_item_params.except(:menu_item_id, :name))

    if result[:success]
      render json: { message: "Menu item added successfully" }, status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  def update_menu_item
    menu_item = @menu.menu_menu_items.find_by(menu_item_id: params[:menu_item_id])

    if menu_item.nil?
      return render json: { error: "Menu item not found" }, status: :not_found
    end

    result = @menu.update_menu_item(menu_item:,
                                    attributes: menu_menu_item_params.except(:menu_item_id, :name))

    if result[:success]
      render json: { message: "Menu item updated successfully" }, status: :ok
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  def remove_menu_item
    menu_item = @menu.menu_menu_items.find_by(menu_item_id: params[:menu_item_id])

    if menu_item.nil?
      return render json: { error: "Menu item not found" }, status: :not_found
    end

    menu_item.destroy!

    render json: { message: "Menu item removed successfully" }, status: :ok
  end

  private

  def menu_params
    params.permit(:name, :description, :category, :active, :starts_at, :ends_at)
  end

  def menu_menu_item_params
    params.permit(:menu_item_id, :name, :description, :category,
                  :price, :currency, :available, :prep_time_minutes, :image_url)
  end

  def set_restaurant
    @restaurant = Restaurant.includes(:menus).find_by(id: params[:restaurant_id])

    if @restaurant.nil?
      return render json: { error: "Restaurant not found" }, status: :not_found
    end
  end

  def set_menu
    @menu = Menu.includes(:menu_menu_items).find_by(id: params[:id], restaurant_id: params[:restaurant_id])

    if @menu.nil?
      return render json: { error: "Menu not found" }, status: :not_found
    end
  end
end
