class MenuItemController < ApplicationController
  before_action :set_menu_item, only: %i[show update destroy]

  def index
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 10

    menu_items = MenuItem.includes(:menus)
                         .limit(per_page)
                         .offset((page - 1) * per_page)
                         .order(created_at: :desc)

    render json: menu_items, status: :ok
  end

  def show
    render json: @menu_item, status: :ok
  end

  def create
    menu_item = MenuItem.new(menu_item_params)

    unless menu_item.valid?
      return render json: { errors: menu_item.errors.full_messages }, status: :unprocessable_content
    end

    menu_item.save!

    render json: menu_item, status: :created
  rescue ActionController::ParameterMissing => e
    render json: { error: "Missing required parameter: #{e.param}" }, status: :bad_request
  end

  def update
    unless @menu_item.update(menu_item_params)
      return render json: { errors: @menu_item.errors.full_messages }, status: :unprocessable_content
    end

    render json: @menu_item, status: :ok
  rescue ActionController::ParameterMissing => e
    render json: { error: "Missing required parameter: #{e.param}" }, status: :bad_request
  end

  def destroy
    @menu_item.destroy!

    render json: { message: "Menu item deleted successfully" }, status: :ok
  end

  private

  def menu_item_params
    params.expect(menu_item: [ :name ])
  end

  def set_menu_item
    @menu_item = MenuItem.find_by(id: params[:id])

    if @menu_item.nil?
      return render json: { error: "Menu item not found" }, status: :not_found
    end
  end
end
