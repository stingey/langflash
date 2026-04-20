module Admin
  class BaseController < ApplicationController
    before_action :require_admin

    private

    def require_admin
      return if current_user&.admin?

      redirect_to dashboard_path, alert: "You don't have access to that area."
    end
  end
end
