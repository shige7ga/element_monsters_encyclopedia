module Users
  class SessionsController < Devise::SessionsController
    def create
      self.resource = resource_class.new(sign_in_params)

      if blank_login_fields?
        add_blank_errors
        clean_up_passwords(resource)
        respond_with(resource, location: after_sign_in_path_for(resource))
      else
        super
      end
    end

    private

    def blank_login_fields?
      params.dig(resource_name, :login).blank? || params.dig(resource_name, :password).blank?
    end

    def add_blank_errors
      resource.errors.add(:login, :blank) if params.dig(resource_name, :login).blank?
      resource.errors.add(:password, :blank) if params.dig(resource_name, :password).blank?
    end
  end
end
