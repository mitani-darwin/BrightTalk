class Users::SessionsController < Devise::SessionsController
  respond_to :html, :json

  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          resource: resource_name,
          csrf_token: form_authenticity_token,
          endpoints: {
            session_create: session_path(resource_name),
            passkey_auth_options: auth_options_passkey_authentications_path,
            passkey_auth_create: passkey_authentications_path
          },
          fields: {
            email: {
              type: "email",
              required: true,
              autocomplete: "email",
              label: "メールアドレス"
            }
          },
          features: {
            passkey_authentication: true
          }
        }
      end

      format.any do
        respond_with resource, serialize_options(resource)
      end
    end
  end
end
